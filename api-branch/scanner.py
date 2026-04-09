#!/usr/bin/env python3
"""
API Branch Scanner -- auto-discovers APIs from project source code.

Rules:
  - NEVER makes HTTP calls. Read-only code analysis only.
  - NEVER silently swallows errors. All failures surface.
  - NEVER modifies manually-verified entries. Only flags new discoveries.
  - Scans Python + JS files for URL patterns, auth patterns, client classes.

Usage:
  python3 scanner.py                          # Show registry status
  python3 scanner.py --scan                   # Full scan all projects
  python3 scanner.py --scan --quiet           # Minimal output (for hooks)
  python3 scanner.py --scan --tree            # Scan + generate tree
  python3 scanner.py --project myapp          # Scan one project
  python3 scanner.py --tree                   # Generate tree from registry
  python3 scanner.py --add-project NAME PATH  # Register new project
  python3 scanner.py --diff                   # Show changes since last scan
"""

import json
import os
import re
import sys
from pathlib import Path
from datetime import datetime

BRANCH_DIR = Path.home() / ".claude" / "api-branch"
REGISTRY_FILE = BRANCH_DIR / "registry.json"
TREE_FILE = BRANCH_DIR / "tree.md"

SKIP_DIRS = {"venv", "node_modules", "__pycache__", ".git", "build", "dist",
             ".tox", ".mypy_cache", ".pytest_cache", "env", ".env"}
SKIP_FILE_PREFIXES = {"test_", "tests_", "conftest", "mock_", "fixture_"}
# URLs that are the app itself, not external APIs
SELF_URLS = {"localhost", "127.0.0.1", "0.0.0.0"}

# ---------------------------------------------------------------------------
# Patterns -- what we look for in source files
# ---------------------------------------------------------------------------

PY_BASE_URL = [
    r'(?:BASE_URL|base_url|API_URL|API_BASE)\s*=\s*f?["\']([^"\']*https?://[^"\']+)["\']',
    r'(?:base_url|url)\s*=\s*f?["\']([^"\']*https?://[^"\']+)["\']',
]
PY_AUTH = [
    r'["\'](Authorization)["\']',
    r'["\'](x-api-key)["\']',
    r'["\'](api_token)["\']',
    r'["\'](api_key)["\']',
    r'["\'](Bearer )["\']',
]
PY_CLIENT_CLASS = [
    r'class\s+(\w+(?:Client|Service|API|Api))\s*[\(:]',
]
PY_IMPORT_SDK = [
    r'^(?:import|from)\s+(anthropic|openai|stripe|twilio|slack_sdk|boto3|google)\b',
]
JS_FETCH = [
    r'fetch\s*\(\s*[`"\']([^`"\']*https?://[^`"\']*)[`"\']',
]
JS_BASE = [
    r'(?:API_BASE|BASE_URL|apiBase|baseUrl|baseURL)\s*[:=]\s*[`"\']([^`"\']+)[`"\']',
]


# ---------------------------------------------------------------------------
# Registry I/O
# ---------------------------------------------------------------------------

def load_registry():
    if REGISTRY_FILE.exists():
        try:
            with open(REGISTRY_FILE) as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            print(f"! REGISTRY CORRUPT: {e}", file=sys.stderr)
            sys.exit(1)
    return {"meta": {"version": 1}, "projects": {}, "last_scan": None, "scan_count": 0}


def save_registry(reg):
    reg["last_scan"] = datetime.now().isoformat()
    reg["scan_count"] = reg.get("scan_count", 0) + 1
    BRANCH_DIR.mkdir(parents=True, exist_ok=True)
    tmp = REGISTRY_FILE.with_suffix(".tmp")
    with open(tmp, "w") as f:
        json.dump(reg, f, indent=2)
    tmp.rename(REGISTRY_FILE)  # atomic on same filesystem


# ---------------------------------------------------------------------------
# File scanners (read-only, never execute)
# ---------------------------------------------------------------------------

def _extract(patterns, text):
    hits = []
    for pat in patterns:
        for m in re.finditer(pat, text, re.MULTILINE):
            hits.append(m.group(1) if m.lastindex else m.group(0))
    return list(dict.fromkeys(hits))


def scan_python_file(filepath):
    try:
        text = filepath.read_text(errors="replace")
    except Exception as e:
        return {"error": str(e)}
    return {
        "base_urls": [u for u in _extract(PY_BASE_URL, text) if not any(s in u for s in SELF_URLS)],
        "auth":      _extract(PY_AUTH, text),
        "classes":   _extract(PY_CLIENT_CLASS, text),
        "sdks":      _extract(PY_IMPORT_SDK, text),
    }


def scan_js_file(filepath):
    try:
        text = filepath.read_text(errors="replace")
    except Exception as e:
        return {"error": str(e)}
    return {
        "fetch_urls": [u for u in _extract(JS_FETCH, text) if not any(s in u for s in SELF_URLS)],
        "api_bases":  [u for u in _extract(JS_BASE, text) if not any(s in u for s in SELF_URLS)],
    }


# ---------------------------------------------------------------------------
# Project scanner
# ---------------------------------------------------------------------------

def should_skip(path):
    return any(part in SKIP_DIRS for part in path.parts)

def is_test_file(path):
    return any(path.name.startswith(p) for p in SKIP_FILE_PREFIXES)

def is_self_url(url, project_name=""):
    """Filter out the project's own domain from discoveries."""
    for s in SELF_URLS:
        if s in url:
            return True
    # If project name appears in URL, likely self-reference
    if project_name and project_name.lower() in url.lower():
        return True
    return False


def scan_project(proj_path, proj_name=""):
    proj = Path(proj_path)
    if not proj.is_dir():
        return {"error": f"Not a directory: {proj}"}

    result = {
        "path": str(proj), "ts": datetime.now().isoformat(),
        "files": 0, "discovered": {}, "errors": [],
    }

    # Python files
    for f in proj.rglob("*.py"):
        if should_skip(f) or is_test_file(f):
            continue
        result["files"] += 1
        findings = scan_python_file(f)
        if "error" in findings:
            result["errors"].append(f"{f.relative_to(proj)}: {findings['error']}")
            continue
        # Filter self-URLs
        findings["base_urls"] = [u for u in findings["base_urls"] if not is_self_url(u, proj_name)]
        if findings["base_urls"] or findings["classes"] or findings["sdks"]:
            result["discovered"][str(f.relative_to(proj))] = {**findings, "type": "python"}

    # JS/TS files (skip node_modules/build)
    for pattern in ["*.js", "src/**/*.js", "src/**/*.ts", "src/**/*.tsx"]:
        for f in proj.glob(pattern):
            if should_skip(f) or is_test_file(f):
                continue
            result["files"] += 1
            findings = scan_js_file(f)
            if "error" in findings:
                result["errors"].append(f"{f.relative_to(proj)}: {findings['error']}")
                continue
            findings["fetch_urls"] = [u for u in findings["fetch_urls"] if not is_self_url(u, proj_name)]
            findings["api_bases"] = [u for u in findings["api_bases"] if not is_self_url(u, proj_name)]
            if findings["fetch_urls"] or findings["api_bases"]:
                result["discovered"][str(f.relative_to(proj))] = {**findings, "type": "javascript"}

    return result


# ---------------------------------------------------------------------------
# Diff
# ---------------------------------------------------------------------------

def diff_scan(proj_name, proj_data, scan_result):
    changes = []
    known_files = set()
    known_urls = set()

    for api in proj_data.get("apis", {}).values():
        for key in ("client_file", "service_file", "router_file"):
            if api.get(key):
                known_files.add(api[key])
        if api.get("base_url"):
            known_urls.add(api["base_url"])

    for fpath, info in scan_result.get("discovered", {}).items():
        if fpath not in known_files:
            urls = info.get("base_urls", []) or info.get("fetch_urls", []) or info.get("api_bases", [])
            new_urls = [u for u in urls if u not in known_urls]
            if new_urls or info.get("classes") or info.get("sdks"):
                changes.append({
                    "type": "new_api_file", "file": fpath,
                    "urls": new_urls, "classes": info.get("classes", []),
                    "sdks": info.get("sdks", []),
                })

    proj_path = Path(proj_data.get("path", ""))
    for api_name, api in proj_data.get("apis", {}).items():
        cf = api.get("client_file")
        if cf and not (proj_path / cf).exists():
            changes.append({"type": "missing_file", "api": api_name, "file": cf})

    return changes


# ---------------------------------------------------------------------------
# Tree generator
# ---------------------------------------------------------------------------

def generate_tree(reg):
    lines = [
        "# API Branch -- Cross-Project Registry", "",
        f"Last scan: {reg.get('last_scan', 'never')[:19] if reg.get('last_scan') else 'never'}",
        f"Scans run: {reg.get('scan_count', 0)}", "",
    ]
    projects = reg.get("projects", {})
    if not projects:
        lines.append("(no projects registered -- use: scanner.py --add-project NAME PATH)")
        return "\n".join(lines)

    for pname, pdata in projects.items():
        apis = pdata.get("apis", {})
        lines.append(f"## [{pname}] -- {len(apis)} APIs")
        lines.append(f"   Path: {pdata.get('path', '?')}")
        lines.append("")
        if not apis:
            lines.append("   (no APIs cataloged -- run --scan to discover)")
            lines.append("")
            continue

        for aname, a in apis.items():
            st = a.get("status", "?")
            icon = {"active": "+", "broken": "!", "deprecated": "~", "discovered": "??"}.get(st, "?")
            lines.append(f"   [{icon}] {a.get('name', aname)}")
            lines.append(f"       base:   {a.get('base_url', '?')}")
            auth = a.get("auth", {})
            if auth:
                lines.append(f"       auth:   {auth.get('method','?')} -> {auth.get('key','?')}")
                if auth.get("note"):
                    lines.append(f"               {auth['note']}")
            for fk, label in [("client_file","client"),("service_file","service"),("router_file","router")]:
                if a.get(fk):
                    lines.append(f"       {label:8s}{a[fk]}")
            if a.get("ref_doc"):
                lines.append(f"       docs:   {a['ref_doc']}")
            eps = a.get("endpoints", [])
            if eps:
                tested = sum(1 for e in eps if e.get("tested"))
                lines.append(f"       endpoints: {len(eps)} ({tested} tested)")
                for ep in eps:
                    mark = "v" if ep.get("tested") else " "
                    tag = f" [{ep['status']}]" if ep.get("status") else ""
                    lines.append(f"         [{mark}] {ep.get('method','?'):6s} {ep.get('path','?')}  -- {ep.get('name','')}{tag}")
            gotchas = a.get("gotchas", [])
            if gotchas:
                lines.append(f"       gotchas: {len(gotchas)}")
                for g in gotchas:
                    lines.append(f"         ! {g}")
            lines.append("")

        sr = pdata.get("last_scan_result", {})
        if sr and sr.get("errors"):
            lines.append(f"   SCAN ERRORS ({len(sr['errors'])}):")
            for e in sr["errors"][:5]:
                lines.append(f"     ! {e}")
            lines.append("")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    import argparse
    p = argparse.ArgumentParser(description="API Branch Scanner")
    p.add_argument("--scan", action="store_true", help="Scan all registered projects")
    p.add_argument("--project", help="Scan one project by name")
    p.add_argument("--add-project", nargs=2, metavar=("NAME", "PATH"), help="Register a new project")
    p.add_argument("--tree", action="store_true", help="Generate tree view")
    p.add_argument("--diff", action="store_true", help="Show only new/changed APIs")
    p.add_argument("--quiet", action="store_true", help="Minimal output (for hooks)")
    args = p.parse_args()

    reg = load_registry()

    if args.add_project:
        name, path = args.add_project
        resolved = str(Path(path).resolve())
        if not Path(resolved).is_dir():
            print(f"! Path does not exist: {resolved}", file=sys.stderr)
            sys.exit(1)
        reg["projects"][name] = {"path": resolved, "apis": {}, "added": datetime.now().isoformat()}
        save_registry(reg)
        print(f"+ Registered project: {name} -> {resolved}")
        return

    if args.scan or args.project:
        targets = {}
        if args.project:
            if args.project not in reg["projects"]:
                print(f"! Unknown project: {args.project}", file=sys.stderr)
                sys.exit(1)
            targets[args.project] = reg["projects"][args.project]
        else:
            targets = reg["projects"]

        total_new = 0
        for pname, pdata in targets.items():
            result = scan_project(pdata["path"], pname)
            if "error" in result:
                print(f"! {pname}: {result['error']}", file=sys.stderr)
                continue

            reg["projects"][pname]["last_scan_result"] = {
                "files_scanned": result["files"],
                "api_files_found": len(result["discovered"]),
                "errors": result["errors"][:20],
                "ts": result["ts"],
            }

            changes = diff_scan(pname, pdata, result)
            new_apis = [c for c in changes if c["type"] == "new_api_file"]
            missing = [c for c in changes if c["type"] == "missing_file"]
            total_new += len(new_apis)

            if not args.quiet:
                print(f"  {pname}: {result['files']} files, "
                      f"{len(result['discovered'])} API files, "
                      f"{len(new_apis)} NEW, {len(missing)} missing, "
                      f"{len(result['errors'])} errors")
                for c in new_apis:
                    print(f"    + NEW: {c['file']}")
                    for u in c.get("urls", []):
                        print(f"        URL: {u}")
                    for cls in c.get("classes", []):
                        print(f"        Class: {cls}")
                for c in missing:
                    print(f"    ! MISSING: {c['file']} (API: {c['api']})")

        save_registry(reg)

        if args.quiet and total_new:
            print(f"API_BRANCH: {total_new} new API(s) -- run: python3 {__file__} --scan --tree")
        elif args.tree:
            tree = generate_tree(reg)
            TREE_FILE.write_text(tree)
            print(f"\n{tree}\nTree -> {TREE_FILE}")
        return

    if args.tree:
        tree = generate_tree(reg)
        TREE_FILE.write_text(tree)
        print(tree)
        return

    if args.diff:
        for pname, pdata in reg["projects"].items():
            result = scan_project(pdata["path"], pname)
            if "error" in result:
                print(f"  {pname}: {result['error']}")
                continue
            changes = diff_scan(pname, pdata, result)
            if not changes:
                print(f"  {pname}: no changes")
            else:
                for c in changes:
                    if c["type"] == "new_api_file":
                        print(f"  + {c['file']}  urls={c.get('urls',[])}  classes={c.get('classes',[])}")
                    elif c["type"] == "missing_file":
                        print(f"  - {c['file']}  (was: {c['api']})")
        return

    # Default: status
    proj_count = len(reg.get("projects", {}))
    total_apis = sum(len(p.get("apis", {})) for p in reg.get("projects", {}).values())
    print(f"API Branch Registry")
    print(f"  Projects:  {proj_count}")
    print(f"  APIs:      {total_apis}")
    print(f"  Last scan: {reg.get('last_scan', 'never')}")
    for name, data in reg.get("projects", {}).items():
        ac = len(data.get("apis", {}))
        print(f"  [{name}] {ac} APIs -> {data.get('path','?')}")


if __name__ == "__main__":
    main()

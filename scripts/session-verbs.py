#!/usr/bin/env python3
"""session-verbs: the verbs a Claude Code session set, with the commits made between them.

usage: session-verbs.py [TRANSCRIPT.jsonl] [--repo PATH]...

TRANSCRIPT defaults to the newest session of the current directory (~/.claude/projects/<cwd>/*.jsonl).
Each verb is a call to mcp__matrix-spinner__status or mcp__gerunds__status; the transcript stores each call twice, so they are
de-duplicated by call id. Each --repo adds that repo's commit titles from the session's span, taken from the
`[ ☠ title ]` bracket of a commit-style message, else its subject. Times are local.
"""
import glob
import json
import os
import re
import subprocess
import sys
from datetime import datetime

TOOLS = {"mcp__matrix-spinner__status", "mcp__gerunds__status"}  # the verb tool, before and after the split


def newest_transcript():
    slug = os.getcwd().replace("/", "-")
    found = glob.glob(os.path.expanduser(f"~/.claude/projects/{slug}/*.jsonl"))
    if not found:
        sys.exit(f"session-verbs: no transcripts under ~/.claude/projects/{slug}")
    return max(found, key=os.path.getmtime)


def when(iso):
    return datetime.fromisoformat(iso.replace("Z", "+00:00")).astimezone()


def verbs_of(path):
    seen, out, first, last = set(), [], None, None
    for line in open(path, encoding="utf8"):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        ts = d.get("timestamp")
        if ts:
            first, last = first or when(ts), when(ts)
        content = (d.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        for b in content:
            if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") in TOOLS:
                text = str((b.get("input") or {}).get("text", "")).strip()
                if text and b["id"] not in seen and ts:
                    seen.add(b["id"])
                    out.append((when(ts), "●", text))
    return out, first, last


def commits_of(repo, first, last):
    log = subprocess.run(
        ["git", "-C", repo, "log", f"--since={first.isoformat()}", f"--until={last.isoformat()}", "--format=%ct%x09%B%x00"],
        capture_output=True, text=True,
    ).stdout
    name = os.path.basename(os.path.abspath(repo))
    for entry in filter(None, (e.strip() for e in log.split("\x00"))):
        stamp, _, body = entry.partition("\t")
        m = re.search(r"\[\s*\S*\s*(.+?)\s*\]", body.splitlines()[0]) if body else None
        yield datetime.fromtimestamp(int(stamp)).astimezone(), "⎇", f"{name}: {m[1] if m else body.splitlines()[0]}"


def main(argv):
    repos, path = [], None
    it = iter(argv)
    for a in it:
        if a == "--repo":
            repos.append(next(it, None) or sys.exit(__doc__))
        elif a.startswith("-"):
            sys.exit(__doc__)
        else:
            path = a
    path = path or newest_transcript()
    rows, first, last = verbs_of(path)
    if first is None:
        sys.exit(f"session-verbs: no timestamps in {path}")
    for repo in repos:
        rows.extend(commits_of(repo, first, last))
    for t, mark, text in sorted(rows):
        print(f"{t:%H:%M:%S} {mark} {text}")


if __name__ == "__main__":
    main(sys.argv[1:])

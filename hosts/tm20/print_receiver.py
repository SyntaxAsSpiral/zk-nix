#!/usr/bin/env python3
"""tm20 mesh print receiver.

USB stays on tm20. Clients submit one prepared 80 mm job at a time.
Duplicate job IDs are not reprinted. Cookbook state is not read.
"""
import argparse
import base64
import hashlib
import json
import os
import subprocess
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from io import BytesIO
from pathlib import Path
from urllib.parse import urlparse

from PIL import Image

LOCK = threading.Lock()
ENV_ALIASES = {
    "PRINT_TOKEN": ("PRINT_TOKEN", "HOLIDAY_PRINT_TOKEN"),
    "PRINT_PORT": ("PRINT_PORT", "HOLIDAY_PRINT_PORT"),
    "PRINT_BIND": ("PRINT_BIND", "HOLIDAY_PRINT_BIND"),
    "PRINT_SPOOL": ("PRINT_SPOOL", "HOLIDAY_PRINT_SPOOL"),
}


def env(name, default=""):
    for key in ENV_ALIASES.get(name, (name,)):
        value = os.environ.get(key)
        if value:
            return value
    return default


def load_jobs(path):
    return json.loads(path.read_text()) if path.exists() else {}


def save_jobs(path, jobs):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + ".tmp")
    temp.write_text(json.dumps(jobs, indent=2) + "\n")
    temp.replace(path)


def job_id_ok(value):
    if not isinstance(value, str) or not 8 <= len(value) <= 80:
        return False
    return value.replace("-", "").replace("_", "").isalnum()


def validate_png(blob, digest):
    if hashlib.sha256(blob).hexdigest() != digest:
        raise ValueError("PNG hash does not match the prepared job.")
    with Image.open(BytesIO(blob)) as image:
        if image.format != "PNG" or image.width != 576:
            raise ValueError("Unexpected slip image.")
        image.verify()


def print_markdown(path):
    process = subprocess.run(
        ["tm20-set", "print", "md", str(path)],
        capture_output=True,
        text=True,
        timeout=120,
    )
    return "printed" if process.returncode == 0 else "uncertain"


def print_png(spool, job_id, blob):
    png = spool / (job_id + ".png")
    wrapper = spool / (job_id + ".md")
    png.write_bytes(blob)
    wrapper.write_text(f"![slip]({png.name})\n")
    return print_markdown(wrapper)


def accept_job(
    spool,
    jobs_path,
    job_id,
    digest,
    blob,
    printer=print_png,
    source=None,
    markdown=None,
):
    if not job_id_ok(job_id):
        raise ValueError("Invalid job id.")
    if source is not None and (
        not isinstance(source, str)
        or not source.replace("-", "").replace("_", "").isalnum()
        or len(source) > 40
    ):
        raise ValueError("Invalid source.")
    if not isinstance(digest, str) or len(digest) != 64:
        raise ValueError("Invalid digest.")
    if markdown is not None:
        if blob:
            raise ValueError("Send a PNG or markdown, not both.")
        if not isinstance(markdown, str) or not markdown.strip() or len(markdown) > 100_000:
            raise ValueError("Markdown job is empty or too large.")
        encoded = markdown.encode()
        if hashlib.sha256(encoded).hexdigest() != digest:
            raise ValueError("Markdown hash does not match the prepared job.")
    else:
        if not isinstance(blob, (bytes, bytearray)) or not blob or len(blob) > 5_000_000:
            raise ValueError("Slip image is empty or too large.")
        validate_png(blob, digest)
    spool.mkdir(parents=True, exist_ok=True)
    with LOCK:
        jobs = load_jobs(jobs_path)
        existing = jobs.get(job_id)
        if existing:
            return {
                "job_id": job_id,
                "slip_id": job_id,
                "status": existing["status"],
                "message": "No additional print sent.",
            }
        jobs[job_id] = {"sha256": digest, "status": "printing", "source": source}
        save_jobs(jobs_path, jobs)
    try:
        if markdown is not None:
            path = spool / (job_id + ".md")
            path.write_text(markdown)
            status = (
                print_markdown(path)
                if printer is print_png
                else printer(spool, job_id, markdown.encode())
            )
        else:
            status = printer(spool, job_id, blob)
    except (OSError, subprocess.TimeoutExpired):
        status = "uncertain"
    with LOCK:
        jobs = load_jobs(jobs_path)
        jobs[job_id] = {"sha256": digest, "status": status, "source": source}
        save_jobs(jobs_path, jobs)
    return {"job_id": job_id, "slip_id": job_id, "status": status}


def default_bind():
    bind = env("PRINT_BIND")
    if bind:
        return bind
    try:
        addresses = subprocess.check_output(
            ["tailscale", "ip", "-4"], text=True, timeout=3
        ).split()
        if addresses:
            return addresses[0]
    except (OSError, subprocess.CalledProcessError):
        pass
    return "127.0.0.1"


def load_local_env():
    path = Path(__file__).resolve().parent / ".env"
    if not path.exists():
        return
    for line in path.read_text().splitlines():
        name, separator, value = line.partition("=")
        name = name.strip()
        if not separator or not name or name in os.environ:
            continue
        os.environ[name] = value.strip().strip('"').strip("'")


def main():
    load_local_env()
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=int(env("PRINT_PORT", "8766")))
    parser.add_argument("--bind", default=default_bind())
    parser.add_argument("--token", default=env("PRINT_TOKEN"))
    parser.add_argument("--spool", default=env("PRINT_SPOOL"))
    args = parser.parse_args()
    if not args.token:
        raise SystemExit("Set PRINT_TOKEN or HOLIDAY_PRINT_TOKEN.")
    here = Path(__file__).resolve().parent
    spool = Path(args.spool).expanduser() if args.spool else here / "spool"
    jobs_path = spool / "jobs.json"
    token = args.token

    class Handler(BaseHTTPRequestHandler):
        def respond(self, value, status=200):
            body = json.dumps(value).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def authorized(self):
            return self.headers.get("Authorization") == "Bearer " + token

        def do_GET(self):
            if urlparse(self.path).path != "/health":
                return self.respond({"error": "Not found"}, 404)
            if not self.authorized():
                return self.respond({"error": "Unauthorized"}, 401)
            self.respond({"ok": True, "host": "tm20", "printer": "TM-T20III"})

        def do_POST(self):
            if urlparse(self.path).path != "/print":
                return self.respond({"error": "Not found"}, 404)
            if not self.authorized() or self.headers.get("Content-Type") != "application/json":
                return self.respond({"error": "Unauthorized"}, 401)
            try:
                length = int(self.headers.get("Content-Length", 0))
                if not 0 < length <= 7_000_000:
                    raise ValueError("Request too large or empty")
                payload = json.loads(self.rfile.read(length))
                job_id = payload.get("job_id") or payload.get("slip_id")
                image = payload.get("image")
                markdown = payload.get("markdown")
                blob = base64.b64decode(image, validate=True) if image else None
                self.respond(
                    accept_job(
                        spool,
                        jobs_path,
                        job_id,
                        payload.get("sha256"),
                        blob,
                        source=payload.get("source"),
                        markdown=markdown,
                    )
                )
            except Exception as exc:
                self.respond(
                    {
                        "error": str(exc)
                        if isinstance(exc, ValueError)
                        else "Print request failed."
                    },
                    400,
                )

    print(f"tm20 print receiver on {args.bind}:{args.port}", flush=True)
    ThreadingHTTPServer((args.bind, args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()

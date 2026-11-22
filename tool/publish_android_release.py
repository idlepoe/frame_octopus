"""Publish this repository's prepared Android assets using existing Git credentials.

Signing material is never read by this tool. Build/sign/verify the APK first.
An existing published release is never overwritten.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
REPO = "idlepoe/frame_octopus"
API = f"https://api.github.com/repos/{REPO}"


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--asset-dir", required=True, type=Path)
    parser.add_argument("--notes", required=True, type=Path)
    args = parser.parse_args()
    if git("remote", "get-url", "origin").removesuffix(".git") != f"https://github.com/{REPO}":
        raise SystemExit("Unexpected repository remote.")
    if git("status", "--porcelain"):
        raise SystemExit("Commit the prepared source before publishing.")
    if git("rev-parse", "HEAD") != args.commit or git("rev-parse", args.tag + "^{commit}") != args.commit:
        raise SystemExit("The release tag must point to the checked-out commit.")

    response = subprocess.run(
        ["git", "credential", "fill"], cwd=ROOT,
        input="protocol=https\nhost=github.com\n\n", text=True,
        capture_output=True, check=True,
    )
    credential = dict(line.split("=", 1) for line in response.stdout.splitlines() if "=" in line)
    headers = {"Authorization": "Bearer " + credential["password"], "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28", "User-Agent": "Frame-Octopus-Release"}

    def request(url, method="GET", payload=None, binary=None, content_type=None, missing_ok=False):
        h = dict(headers)
        data = None
        if payload is not None:
            data = json.dumps(payload).encode()
            h["Content-Type"] = "application/json"
        if binary is not None:
            data = binary
            h["Content-Type"] = content_type or "application/octet-stream"
        try:
            with urllib.request.urlopen(urllib.request.Request(url, data=data, headers=h, method=method), timeout=180) as result:
                return json.load(result)
        except urllib.error.HTTPError as error:
            if missing_ok and error.code == 404:
                return None
            raise RuntimeError(f"GitHub request failed with HTTP {error.code}.") from None

    names = ["Frame-Octopus-1.0.0-Android-arm64-v8a.apk", "Third-party-notices-Android.zip", "RELEASE_METADATA.json", "SHA256SUMS.txt"]
    paths = [args.asset_dir / name for name in names]
    if not all(path.is_file() for path in paths):
        raise SystemExit("One or more release assets are missing.")
    metadata = json.loads(paths[2].read_text(encoding="utf-8"))
    if metadata.get("source_commit") != args.commit:
        raise SystemExit("Asset metadata does not match the source commit.")
    if hashlib.sha256(paths[0].read_bytes()).hexdigest() != metadata["apk_sha256"]:
        raise SystemExit("APK checksum does not match the verified package.")
    notes = args.notes.read_text(encoding="utf-8")
    if notes.startswith("# "):
        notes = notes.split("\n", 1)[1].lstrip()

    release = request(API + "/releases/tags/" + urllib.parse.quote(args.tag, safe=""), missing_ok=True)
    if release is not None and not release["draft"]:
        raise SystemExit("Release is already published; refusing to overwrite it.")
    if release is None:
        release = request(API + "/releases", "POST", payload={
            "tag_name": args.tag, "target_commitish": args.commit,
            "name": "Frame Octopus 1.0.0 — Android beta 1", "body": notes,
            "draft": True, "prerelease": True, "make_latest": "false",
        })

    uploaded = {item["name"]: item for item in release["assets"]}
    for path in paths:
        data = path.read_bytes()
        digest = "sha256:" + hashlib.sha256(data).hexdigest()
        asset = uploaded.get(path.name)
        if asset is None:
            print("Uploading " + path.name, flush=True)
            url = release["upload_url"].split("{", 1)[0] + "?name=" + urllib.parse.quote(path.name)
            asset = request(url, "POST", binary=data)
        if asset["size"] != len(data) or (asset.get("digest") and asset["digest"] != digest):
            raise RuntimeError("Uploaded asset verification failed: " + path.name)
        if path.name in uploaded and asset.get("digest") != digest:
            raise RuntimeError("Cannot safely reuse an existing asset without a matching server digest.")

    release = request(API + "/releases/" + str(release["id"]), "PATCH", payload={"draft": False, "prerelease": True, "make_latest": "false", "body": notes})
    verified = request(API + "/releases/" + str(release["id"]))
    if verified["draft"] or set(names) != {asset["name"] for asset in verified["assets"]}:
        raise RuntimeError("Release publication verification failed.")
    record = {
        "url": verified["html_url"], "tag": args.tag, "commit": args.commit,
        "prerelease": verified["prerelease"],
        "assets": [{"name": a["name"], "bytes": a["size"], "digest": a.get("digest"), "download_url": a["browser_download_url"]} for a in verified["assets"]],
    }
    (args.asset_dir / "PUBLISHED_RELEASE.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
    print("Published: " + verified["html_url"], flush=True)


if __name__ == "__main__":
    main()

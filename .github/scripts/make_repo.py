#!/usr/bin/env python3
"""Generate Sileo/Cydia APT-repo metadata from a directory of .deb files.

Usage: make_repo.py <debs-dir> <repo-root>
Creates/updates:
  <repo-root>/dists/stable/main/binary-<arch>/Packages(.gz)
  <repo-root>/dists/stable/Release
"""
import sys, os, gzip, tarfile, io, hashlib, email.utils

SUITE = "stable"
COMPONENT = "main"
ORIGIN = "PerkZ999"
LABEL = "GameSeagull Repo"
DESCRIPTION = "GameSeagull - GamePigeon tweaks (prediction lines, find shot & more)"

def read_ar(data):
    """Yield (name, bytes) members of an ar archive."""
    assert data[:8] == b"!<arch>\n", "not an ar archive"
    off = 8
    while off + 60 <= len(data):
        name = data[off:off + 16].decode("utf-8", "replace").strip()
        size = int(data[off + 48:off + 58].decode().strip())
        body = data[off + 60:off + 60 + size]
        yield name.rstrip("/"), body
        off += 60 + size
        if off % 2:
            off += 1

def deb_control(deb_path):
    """Extract the control file text from a .deb."""
    data = open(deb_path, "rb").read()
    for name, body in read_ar(data):
        if name.startswith("control.tar"):
            tf = None
            if name.endswith(".gz"):
                tf = tarfile.open(fileobj=io.BytesIO(body), mode="r:gz")
            elif name.endswith(".xz"):
                tf = tarfile.open(fileobj=io.BytesIO(body), mode="r:xz")
            elif name.endswith(".zst"):
                try:
                    import zstandard
                    dctx = zstandard.ZstdDecompressor()
                    raw = dctx.stream_reader(io.BytesIO(body)).read()
                    tf = tarfile.open(fileobj=io.BytesIO(raw), mode="r:")
                except ImportError:
                    raise SystemExit(f"ERROR: {deb_path} uses zstd control.tar; pip install zstandard")
            else:
                raise SystemExit(f"ERROR: unknown control compression: {name}")
            for member in tf.getmembers():
                if member.name.lstrip("./") == "control":
                    return tf.extractfile(member).read().decode("utf-8", "replace")
    raise SystemExit(f"ERROR: no control.tar in {deb_path}")

def parse_control(text):
    """Return ordered list of (field, value) with multiline continuation preserved."""
    fields = []
    for line in text.replace("\r\n", "\n").split("\n"):
        if not line.strip():
            continue
        if line[0] in " \t" and fields:
            k, v = fields[-1]
            fields[-1] = (k, v + "\n" + line.rstrip())
        elif ":" in line:
            k, _, v = line.partition(":")
            fields.append((k.strip(), v.strip()))
    return fields

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def md5(data):
    return hashlib.md5(data).hexdigest()

def main():
    debs_dir, out_root = sys.argv[1], sys.argv[2]
    entries = {}  # arch -> list of (stanza_text, deb_rel_path, deb_bytes)

    for fname in sorted(os.listdir(debs_dir)):
        if not fname.endswith(".deb"):
            continue
        path = os.path.join(debs_dir, fname)
        fields = parse_control(deb_control(path))
        arch = dict((k.lower(), v) for k, v in fields).get("architecture")
        if not arch:
            raise SystemExit(f"ERROR: no Architecture in {fname}")
        stanza = []
        for k, v in fields:
            stanza.append(f"{k}: {v}")
        rel = f"debs/{fname}"
        stanza.append(f"Filename: {rel}")
        size = os.path.getsize(path)
        stanza.append(f"Size: {size}")
        text = "\n".join(stanza) + "\n"
        entries.setdefault(arch, []).append((text, rel, path, size))

    if not entries:
        raise SystemExit("ERROR: no .deb files found in " + debs_dir)

    archs = sorted(entries.keys())
    packages_files = []  # paths relative to repo root, for the Release checksums

    for arch, items in entries.items():
        dist_dir = os.path.join(out_root, "dists", SUITE, "main", f"binary-{arch}")
        os.makedirs(dist_dir, exist_ok=True)
        body = "\n".join(t for t, _, _, _ in items).encode("utf-8")
        with open(os.path.join(dist_dir, "Packages"), "wb") as f:
            f.write(body)
        with gzip.GzipFile(os.path.join(dist_dir, "Packages.gz"), "wb", mtime=0) as f:
            f.write(body)
        packages_files.append(f"dists/{SUITE}/main/binary-{arch}/Packages")
        packages_files.append(f"dists/{SUITE}/main/binary-{arch}/Packages.gz")
        for t, rel, path, size in items:
            dest = os.path.join(out_root, rel)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, "wb") as f:
                f.write(open(path, "rb").read())

    lines = [
        f"Origin: {ORIGIN}",
        f"Label: {LABEL}",
        f"Suite: {SUITE}",
        f"Codename: {SUITE}",
        f"Architectures: {' '.join(archs)}",
        f"Components: {COMPONENT}",
        f"Description: {DESCRIPTION}",
        f"Date: {email.utils.formatdate(usegmt=True)}",
    ]
    hashes = [("MD5Sum", lambda d: hashlib.md5(d).hexdigest()),
              ("SHA1", lambda d: hashlib.sha1(d).hexdigest()),
              ("SHA256", lambda d: hashlib.sha256(d).hexdigest())]
    for algo, fn in hashes:
        lines.append(algo + ":")
        for rel in packages_files:
            data = open(os.path.join(out_root, rel), "rb").read()
            lines.append(f" {fn(data)} {len(data):8d} {rel}")
    release = "\n".join(lines) + "\n"
    os.makedirs(os.path.join(out_root, "dists", SUITE), exist_ok=True)
    with open(os.path.join(out_root, "dists", SUITE, "Release"), "w") as f:
        f.write(release)

    total = sum(len(v) for v in entries.values())
    print(f"[+] wrote metadata for {total} package(s), arches: {', '.join(archs)}")
    print(f"[+] dists/{SUITE}/Release written")

if __name__ == "__main__":
    main()

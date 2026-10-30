#!/bin/bash
# Rebuilds the TrollStore GameSeagull IPA with the freshly compiled tweak.
#
# Usage: ./make_ipa.sh [path-to-base-GameSeagull.ipa]
#   If no base IPA is passed, the official TrollStoreGameSeagull 2.1 release is downloaded.
#   The .deb packages must be built first (./build_release.sh).
set -euo pipefail

VERSION=$(grep '^Version:' control | awk '{print $2}')
OUT="GameSeagull-${VERSION}.ipa"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

BASE_IPA="${1:-}"
if [ -z "$BASE_IPA" ]; then
	echo "[-] no base IPA given, downloading official TrollStoreGameSeagull 2.1 release..."
	curl -sL -o "$WORK/base.ipa" https://github.com/donato-fiore/TrollStoreGameSeagull/releases/download/v2.1/GameSeagull.ipa
	BASE_IPA="$WORK/base.ipa"
fi

echo "[+] extracting tweak dylib from built packages..."
DEB=$(ls packages/*.deb | grep -v rootless | head -1)
[ -n "$DEB" ] || { echo "[-] no rootful .deb found (run ./build_release.sh first)"; exit 1; }
mkdir -p "$WORK/deb"
dpkg-deb -x "$DEB" "$WORK/deb"
NEW_DYLIB=$(find "$WORK/deb" -name "GameSeagull.dylib" | head -1)
[ -n "$NEW_DYLIB" ] || { echo "[-] GameSeagull.dylib not found in $DEB"; exit 1; }

echo "[+] unpacking $BASE_IPA..."
mkdir -p "$WORK/ipa"
unzip -q "$BASE_IPA" -d "$WORK/ipa"

OLD_DYLIB=$(find "$WORK/ipa" -name "GameSeagull.dylib" | head -1)
[ -n "$OLD_DYLIB" ] || { echo "[-] GameSeagull.dylib not found inside IPA (is this a GameSeagull IPA?)"; exit 1; }

# preserve the original install name so existing references keep working
LC_ID=$(python3 - "$OLD_DYLIB" <<'EOF'
import struct, sys
data = open(sys.argv[1], 'rb').read()
magic, cputype, cpusub, filetype, ncmds = struct.unpack_from('<IIIII', data, 0)
off = 32
for _ in range(ncmds):
    cmd, cmdsize = struct.unpack_from('<II', data, off)
    if cmd == 0xd:  # LC_ID_DYLIB
        name_off = struct.unpack_from('<I', data, off + 8)[0]
        end = data.find(b'\x00', off + name_off)
        print(data[off + name_off:end].decode())
        break
    off += cmdsize
EOF
)
echo "[+] swapping in $NEW_DYLIB (install name: $LC_ID)"
cp -f "$NEW_DYLIB" "$OLD_DYLIB"
if [ -n "$LC_ID" ]; then
	# rewrite LC_ID_DYLIB in place (null-padded) when the new name fits; harmless to skip otherwise
	python3 - "$OLD_DYLIB" "$LC_ID" <<'EOF'
import struct, sys
path, want = sys.argv[1], sys.argv[2].encode()
data = bytearray(open(path, 'rb').read())
magic, cputype, cpusub, filetype, ncmds = struct.unpack_from('<IIIII', data, 0)
off = 32
for _ in range(ncmds):
    cmd, cmdsize = struct.unpack_from('<II', data, off)
    if cmd == 0xd:  # LC_ID_DYLIB
        name_off = struct.unpack_from('<I', data, off + 8)[0]
        end = data.find(b'\x00', off + name_off)
        old = data[off + name_off:end]
        if len(want) <= len(old):
            data[off + name_off:off + name_off + len(want)] = want
            data[off + name_off + len(want):end] = b'\x00' * (len(old) - len(want))
            open(path, 'wb').write(bytes(data))
            print(f'[+] install name patched in place')
        else:
            print(f'[!] new install name longer than old; leaving as-is')
        break
    off += cmdsize
EOF
fi

# fresh ad-hoc signature (TrollStore re-signs anyway)
ldid -S "$OLD_DYLIB"

echo "[+] repacking $OUT..."
(cd "$WORK/ipa" && zip -qr "$OLDPWD/$OUT" Payload)

echo "[+] done: $OUT"

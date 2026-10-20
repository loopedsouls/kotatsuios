#!/bin/bash
# ============================================================
# build.sh — Compila o KotatsuIOS no iPhone (rootless)
# SDK: /var/jb/usr/share/SDKs/iPhoneOS.sdk (iOS 16.2)
# ============================================================
set -u

SDK="/var/jb/usr/share/SDKs/iPhoneOS.sdk"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
BIN="$BUILD/KotatsuIOS"

CC="clang"
CFLAGS="-isysroot $SDK -target arm64-apple-ios15.0 \
  -fobjc-arc -fmodules -O2 \
  -I$ROOT/Sources \
  -I$ROOT/Sources/App \
  -I$ROOT/Sources/Core/Models \
  -I$ROOT/Sources/Core/Extensions \
  -I$ROOT/Sources/Parsers \
  -I$ROOT/Sources/Data \
  -I$ROOT/Sources/Presentation/Library \
  -I$ROOT/Sources/Presentation/Details \
  -I$ROOT/Sources/Presentation/Reader \
  -I$ROOT/Sources/Presentation/Sources \
  -I$ROOT/Sources/Presentation/Settings \
  -I$ROOT/Sources/Parsers"

LDFLAGS="-isysroot $SDK -framework UIKit -framework Foundation -framework CoreFoundation"

mkdir -p "$BUILD/obj"
rm -f "$BUILD/obj"/*.o

SOURCES=$(find "$ROOT/Sources" -name '*.m' | sort)
OBJECTS=""
FAIL=0

for src in $SOURCES; do
  rel="${src#$ROOT/Sources/}"
  obj="$BUILD/obj/$(echo "$rel" | tr '/' '_').o"
  OBJECTS="$OBJECTS $obj"
  echo "CC  $rel"
  if ! $CC $CFLAGS -c "$src" -o "$obj" 2>&1; then
    FAIL=1
  fi
done

if [ "$FAIL" -ne 0 ]; then
  echo "=== BUILD FAILED ==="
  exit 1
fi

echo "LINK $BIN"
if ! $CC $LDFLAGS -o "$BIN" $OBJECTS 2>&1; then
  echo "=== LINK FAILED ==="
  exit 1
fi

echo "SIGN"
cat > "$BUILD/ents.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>platform-application</key><true/>
  <key>com.apple.private.security.no-container</key><true/>
  <key>com.apple.private.skip-library-validation</key><true/>
  <key>com.apple.private.security.no-sandbox</key><true/>
</dict>
</plist>
EOF
ldid -S"$BUILD/ents.plist" "$BIN"

echo "=== BUILD OK: $BIN ==="

#!/bin/bash
# ============================================================
# test.sh — Compila e roda os testes de regressão do KotatsuIOS
# Valida paridade com kotatsu-parsers (Kotlin, reference/)
# ============================================================
set -u

SDK="/var/jb/usr/share/SDKs/iPhoneOS.sdk"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
BIN="$BUILD/RegressionTests"

CC="clang"
CFLAGS="-isysroot $SDK -target arm64-apple-ios15.0 \
  -fobjc-arc -fmodules -O1 \
  -I$ROOT/Sources \
  -I$ROOT/Sources/App \
  -I$ROOT/Sources/Core/Models \
  -I$ROOT/Sources/Core/Extensions \
  -I$ROOT/Sources/Parsers \
  -I$ROOT/Sources/Presentation/Library \
  -I$ROOT/Sources/Presentation/Details \
  -I$ROOT/Sources/Presentation/Reader \
  -I$ROOT/Sources/Presentation/Sources \
  -I$ROOT/Sources/Presentation/Settings"

LDFLAGS="-isysroot $SDK -framework Foundation -framework UIKit -framework CoreFoundation"

mkdir -p "$BUILD/obj-test"
rm -f "$BUILD/obj-test"/*.o

# Compila tudo que os testes precisam (parser + models + extensions + tests)
SOURCES="$ROOT/Sources/Parsers/MangaDexParser.m \
$ROOT/Sources/Core/Models/Manga.m \
$ROOT/Sources/Core/Models/Chapter.m \
$ROOT/Sources/Core/Models/Source.m \
$ROOT/Sources/Core/Extensions/NSDate+Extensions.m \
$ROOT/Sources/Core/Extensions/NSString+Extensions.m \
$ROOT/Tests/RegressionTests.m"

OBJECTS=""
FAIL=0
for src in $SOURCES; do
  name=$(basename "$src" .m)
  obj="$BUILD/obj-test/$name.o"
  OBJECTS="$OBJECTS $obj"
  echo "CC  $name"
  if ! $CC $CFLAGS -c "$src" -o "$obj" 2>&1; then
    FAIL=1
  fi
done

if [ "$FAIL" -ne 0 ]; then
  echo "=== TEST BUILD FAILED ==="
  exit 1
fi

echo "LINK $BIN"
if ! $CC $LDFLAGS -o "$BIN" $OBJECTS 2>&1; then
  echo "=== TEST LINK FAILED ==="
  exit 1
fi

# Assinar
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

# Registrar no trustcache
HASH=$(ldid -h "$BIN" 2>/dev/null | grep "CandidateCDHash sha256=" | head -1 | cut -d'=' -f2 | tr -d ' \r\n')
if [ ${#HASH} -eq 40 ]; then
  echo "8242" | sudo -S /var/jb/basebin/jbctl trustcache add "$HASH" >/dev/null 2>&1
  echo "trustcache: $HASH"
fi

echo ""
"$BIN"
RC=$?
echo ""
if [ $RC -eq 0 ]; then
  echo "=== TESTS PASSED ==="
else
  echo "=== TESTS FAILED (exit $RC) ==="
fi
exit $RC

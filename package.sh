#!/bin/bash
# ============================================================
# package.sh — Empacota o KotatsuIOS como .app + .deb
# ============================================================
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
APP="$BUILD/Kotatsu.app"
DEB_ROOT="$BUILD/debroot"

# 1. Montar estrutura do .app
rm -rf "$APP"
mkdir -p "$APP"

cp "$BUILD/KotatsuIOS" "$APP/KotatsuIOS"
cp "$ROOT/Resources/Info.plist" "$APP/Info.plist"

# PkgInfo
echo -n "APPL????" > "$APP/PkgInfo"

# 2. Assinar o binário dentro do .app
ldid -S"$BUILD/ents.plist" "$APP/KotatsuIOS"

# 3. Montar estrutura do .deb (rootless: /var/jb/Applications)
rm -rf "$DEB_ROOT"
mkdir -p "$DEB_ROOT/var/jb/Applications/Kotatsu.app"
mkdir -p "$DEB_ROOT/DEBIAN"

cp "$APP/KotatsuIOS" "$APP/Info.plist" "$APP/PkgInfo" "$DEB_ROOT/var/jb/Applications/Kotatsu.app/"

# 4. Control do .deb
cat > "$DEB_ROOT/DEBIAN/control" << 'EOF'
Package: org.koitharu.kotatsu.ios
Name: Kotatsu
Version: 1.0.0
Architecture: iphoneos-arm64
Description: Manga reader for iOS (port of Kotatsu)
Maintainer: lu4nn3ry
Author: lu4nn3ry
Section: Applications
Depends: firmware (>= 15.0)
EOF

# 5. Gerar .deb
DEB="$BUILD/org.koitharu.kotatsu.ios_1.0.0_iphoneos-arm64.deb"
rm -f "$DEB"
dpkg-deb --root-owner-group --build "$DEB_ROOT" "$DEB"

echo "=== PACKAGE OK ==="
echo "APP: $APP"
echo "DEB: $DEB"

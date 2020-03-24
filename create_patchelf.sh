#!/bin/sh -eu
available () {
  command -v "$1" >/dev/null 2>&1
}
if available wget; then
  DL="wget"
  DLS="wget -qO-"
elif available curl; then
  DL="curl -O"
  DLS="curl -s"
else
  echo "Install Wget or cURL" >&2
  exit 1
fi
PKGNAME=patchelf
VERSION="$($DLS https://nixos.org/releases/patchelf/ | grep -o "$PKGNAME-[0-9]\+\.[0-9]\+" | cut -d- -f2 | sort -V | tail -n 1)"
if [ -z "$VERSION" ]; then
  VERSION=0.10
fi
if [ ! -e "$PKGNAME-$VERSION.tar.bz2" ]; then
  $DL "http://nixos.org/releases/$PKGNAME/$PKGNAME-$VERSION/$PKGNAME-$VERSION.tar.bz2"
fi
if [ -d "$PKGNAME}-$VERSION" ]; then
  rm -fr "$PKGNAME-$VERSION"
fi
tar xf "$PKGNAME-$VERSION.tar.bz2"
cd "$PKGNAME-$VERSION"
./configure --prefix="$PWD/staging/usr/local" --mandir="$PWD/staging/usr/local/man" --docdir="$PWD/staging/usr/local/doc/$PKGNAME-$VERSION"
make install
cd staging
strip --strip-unneeded "usr/local/bin/$PKGNAME"
gzip -9 "usr/local/man/man1/$PKGNAME.1"
mkdir -p usr/local/bin
cat <<EOF> "usr/local/bin/uninstall-$PKGNAME-$VERSION"
#!/bin/sh -e
while read f; do
  if [ -e "\$f" -o -h "\$f" ]; then
    if [ -d "\$f" ]; then
      if ! ls -A "\$f" | grep -q ^; then
        if [ ! -h "\$f" ]; then
          rmdir -v "\$f"
        fi
      fi
    else
      rm -v "\$f"
    fi
  fi
done << FILE_LIST
EOF
find . -depth | sed -n 's,^\./,/,p' | grep -vxE "/usr/local/bin/uninstall-$PKGNAME-$VERSION|/usr|/usr/local(/etc|/doc|/games|/include|/lib(32|64)?|/man(/man[a-z0-9]+)?|/s?bin|/share(/color|/man(/man[a-z0-9]+)?|/misc)?|/src)?" >> "usr/local/bin/uninstall-$PKGNAME-$VERSION"
printf "/usr/local/bin/uninstall-$PKGNAME-$VERSION\nFILE_LIST\n" >> "usr/local/bin/uninstall-$PKGNAME-$VERSION"
chmod 755 "usr/local/bin/uninstall-$PKGNAME-$VERSION"
find . ! -type d | sed 's,^\./,,' | tar caf "../../$PKGNAME-$VERSION.bin.tar.gz" -T- --owner 0 --group 0
cd ../..
rm -fr "$PKGNAME-$VERSION"
printf "\nCreated: $PKGNAME-$VERSION.bin.tar.gz\n\n"
printf "To install issue the following as root (or prefaced with sudo):\n\n"
printf "    tar xf $PKGNAME-$VERSION.bin.tar.gz -C/\n\n"
printf "If you later need to uninstall, issue the following as root (or prefaced with sudo):\n\n"
printf "    uninstall-$PKGNAME-$VERSION\n\n"

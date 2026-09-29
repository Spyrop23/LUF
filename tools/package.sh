#!/bin/sh
# Builds dist/FUF.zip with the addon folder FUF/ at the top, ready to unzip
# into Interface/AddOns.
set -e
cd "$(dirname "$0")/.."
rm -rf dist && mkdir -p dist
cp -r FUF dist/FUF
(cd dist && zip -qr FUF.zip FUF)
echo "dist/FUF.zip"

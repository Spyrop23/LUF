#!/bin/sh
# Builds dist/FUF.zip with the addon in a folder named FUF, ready to unzip
# into Interface/AddOns. Only the files the client needs go in.
set -e
cd "$(dirname "$0")/.."
rm -rf dist && mkdir -p dist/FUF
cp -r FUF.toc Core Frames Options README.md dist/FUF/
(cd dist && zip -qr FUF.zip FUF)
echo "dist/FUF.zip"

#!/bin/sh
# Builds dist/LizzaricksUnitFrames-<version>.zip (version from the TOC) with
# the addon folder LizzaricksUnitFrames at the top (no version in the folder
# name), ready to unzip into Interface/AddOns.
set -e
cd "$(dirname "$0")/.."
VERSION=$(sed -n 's/^## Version: *//p' LizzaricksUnitFrames/LizzaricksUnitFrames.toc | tr -d '\r')
ZIP="LizzaricksUnitFrames-$VERSION.zip"
rm -rf dist && mkdir -p dist
cp -r LizzaricksUnitFrames dist/LizzaricksUnitFrames
(cd dist && zip -qr "$ZIP" LizzaricksUnitFrames)
echo "dist/$ZIP"

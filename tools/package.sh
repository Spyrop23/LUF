#!/bin/sh
# Builds dist/LizzaricksUnitFrames.zip with the addon folder at the top,
# ready to unzip into Interface/AddOns.
set -e
cd "$(dirname "$0")/.."
rm -rf dist && mkdir -p dist
cp -r LizzaricksUnitFrames dist/LizzaricksUnitFrames
(cd dist && zip -qr LizzaricksUnitFrames.zip LizzaricksUnitFrames)
echo "dist/LizzaricksUnitFrames.zip"

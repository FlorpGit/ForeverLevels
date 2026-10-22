#!/bin/sh
# Builds a local test zip containing only the committed addon folder:
#   dist/Pathwise-<version>.zip  ->  ForeverLevels/ForeverLevels_Forever.toc ...
# Unzip it straight into Interface/AddOns. Nothing is uploaded anywhere.
set -e
cd "$(dirname "$0")/.."
version=$(sed -n 's/^## Version: //p' ForeverLevels/ForeverLevels_Forever.toc | tr -d '\r')
mkdir -p dist
git archive --format=zip -o "dist/Pathwise-$version.zip" HEAD ForeverLevels
echo "dist/Pathwise-$version.zip"

#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Builds a local test zip containing only the committed addon folder:
#   dist/Pathwise-<version>.zip  ->  Pathwise/Pathwise_Forever.toc ...
# Unzip it straight into Interface/AddOns. Nothing is uploaded anywhere.
set -e
cd "$(dirname "$0")/.."
version=$(sed -n 's/^## Version: //p' Pathwise/Pathwise_Forever.toc | tr -d '\r')
mkdir -p dist
git archive --format=zip -o "dist/Pathwise-$version.zip" HEAD Pathwise
echo "dist/Pathwise-$version.zip"

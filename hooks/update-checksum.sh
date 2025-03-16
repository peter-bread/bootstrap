#!/usr/bin/env bash

set -Eeuo pipefail

OS=$(uname -s)

FILE="bootstrap.sh"

if ! command -v sha256sum &>/dev/null; then
  if [ "$OS" == "Darwin" ]; then
    CHECKSUM=$(shasum -a 256 "$FILE" | awk '{print $1}')
  fi
else
  CHECKSUM=$(sha256sum "$FILE" | awk '{print $1}')
fi

case "$OS" in
Darwin)
  sed -i '' "s/[0-9a-f]\{64\}/$CHECKSUM/" README.md
  ;;
Linux)
  sed -i "s/[0-9a-f]\{64\}/$CHECKSUM/" README.md
  ;;
esac

git add README.md

echo "✔ Updated README with new checksum: $CHECKSUM"

#!/usr/bin/env bash

# Bootstrap entry point. Determine OS.

set -Eeuo pipefail

cd "$HOME"

REPO_URL="https://github.com/peter-bread/bootstrap"
TMP_DIR="$HOME/.bootstrap"

OS="$(uname -s)"

# ensure git is installed
if ! command -v git &>/dev/null; then
  echo "Git not found. Installing..."

  case "$OS" in
  Darwin)
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Re-run this script."
    exit 1
    ;;
    # TODO: handle other OS, although should be installed by default on most
  esac

fi

# get bootstrap scripts

# remove potential existing bootstrap files
if [[ -d $TMP_DIR ]]; then
  rm -rf "$TMP_DIR"
fi

echo "Cloning bootstrap scripts..."
git clone --depth=1 "$REPO_URL" "$TMP_DIR"

# source common utilities
source "$TMP_DIR/os/common.sh"

# Root user should NOT run this script
notify "Checking privileges..."

if [[ $EUID -eq 0 ]]; then
  error "Error: this script should not be run as root."
  error "Please run it as a regular user."
  exit 1
fi

success "Running as regular user!"

# source OS-specific scripts
case "$OS" in
Darwin)
  echo "Detected MacOS..."
  source "$TMP_DIR/os/macos.sh"
  ;;
  # TODO: handle other OS
esac

# cleanup
if [[ -d $TMP_DIR ]]; then
  rm -rf "$TMP_DIR"
fi

echo "Bootstrap complete!"

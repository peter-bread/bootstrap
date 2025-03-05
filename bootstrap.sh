#!/usr/bin/env bash

# Bootstrap entry point. Determine OS.

set -Eeuo pipefail

REPO_URL="https://github.com/peter-bread/bootstrap"
TMP_DIR="$HOME/.bootstrap"

OS="$(uname -s)"

function cleanup() {
  if [[ -d $TMP_DIR ]]; then
    rm -rf "$TMP_DIR"
  fi
}

# ensure bootstrap repo is deleted whenever this script ends
trap cleanup ERR EXIT

cd "$HOME"

# remove potential existing bootstrap files
cleanup

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

echo "Cloning bootstrap scripts..."
# TODO: switch back to main branch once this branch is merged
git clone --depth=1 --branch=rewrite "$REPO_URL" "$TMP_DIR"

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

echo "Bootstrap complete!"

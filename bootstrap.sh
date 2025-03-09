#!/usr/bin/env bash

# Bootstrap entry point. Determine OS.

set -Eeuo pipefail

# Root user should NOT run this script
if [[ $EUID -eq 0 ]]; then
  echo "Error: this script should not be run as root."
  echo "Please run it as a regular user."
  exit 1
fi

# parse command line args

LOCAL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
  --local)
    LOCAL=1
    shift
    ;;
  # --email)
  #   EMAIL="$2"
  #   shift 2
  #   ;;
  # --ssh-key)
  #   SSH_KEY="$2"
  #   shift 2
  #   ;;
  *)
    echo "Unknown argument: $1"
    exit 1
    ;;
  esac
done

is_local() {
  [[ $LOCAL -ne 0 ]]
}

REPO_URL="https://github.com/peter-bread/bootstrap"

TMP_DIR="$HOME/.bootstrap"

is_local && TMP_DIR="."

OS="$(uname -s)"
ARCH=$(uname -m)

function cleanup() {
  if [[ -d $TMP_DIR ]]; then
    rm -rf "$TMP_DIR"
  fi
}

# ensure bootstrap repo is deleted whenever this script ends
! is_local && trap cleanup ERR EXIT

# cd to home
! is_local && cd "$HOME"

# remove potential existing bootstrap files
! is_local && cleanup

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

if ! is_local; then
  echo "Cloning bootstrap scripts..."

  # TODO: switch back to main branch once this branch is merged
  git clone --depth=1 --branch=rewrite --quiet "$REPO_URL" "$TMP_DIR"
fi

# source common utilities
source "$TMP_DIR/os/common.sh"

if is_local; then
  notify "${bold}Starting bootstrap (locally)...${reset}"
else
  notify "${bold}Starting bootstrap...${reset}"
fi

# source OS-specific scripts
case "$OS" in
Darwin)
  notify "Detected MacOS..."
  source "$TMP_DIR/os/macos.sh"
  ;;
  # TODO: handle other OS
esac

success "Bootstrap complete!"

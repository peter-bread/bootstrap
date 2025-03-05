#!/usr/bin/env bash

# Make sure Homebrew is installed

# WARN: assumes apple silicon

set -Eeuo pipefail

notify "Checking if Homebrew is installed..."

# ensure homebrew is installed
if ! command_exists brew; then
  notify "Installing Homebrew..."
  NONINTERACTIVE=1 /usr/bin/env bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # check if installation was successful
  if command_exists /opt/homebrew/bin/brew; then
    success "Homebrew installation successful!"
  else
    error "Error: Homebrew installation failed!"
    exit 1
  fi
fi

success "Homebrew is installed!"

# set up homebrew in current shell
notify "Setting up Homebrew in current shell..."
eval "$(/opt/homebrew/bin/brew shellenv)"

# update & upgrade Homebrew
notify "Updating Homebrew..."
brew update
notify "Upgrading Homebrew..."
brew upgrade

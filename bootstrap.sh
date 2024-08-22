#!/usr/bin/env bash

# check if a command exists silently
command_exists() {
  command -v "$1" &>/dev/null
}

OS=$(uname)

if [[ "$OS" != "Darwin" ]]; then
  echo "This script is only meant to run on MacOS."
  echo "Should work on Linux in the future."
  echo "No plans to work on windows"
  exit 1
fi

# should only need root priveliges when necessary
if [[ $EUID -eq 0 ]]; then
  echo "This script must NOT be run as root (DO NOT use sudo)"
  exit 1
fi

echo "Staring bootstrap..."

echo "Changing into home directory"
cd || exit 1

echo "Checking for xcode command line tools..."
if ! command_exists xcode-select -p; then
  echo "xcode must be installed (run xcode-select --install)"
  xcode-select --install
fi
echo "xcode command line tools installed."

# make sure curl is installed to be able to run remotely
echo "Checking for curl..."
if ! command_exists curl; then
  echo "curl is required to execute this script remotely."
  echo "If curl is not available on this system, download the script to a USB drive and run it from there."
  exit 1
fi
echo "curl installed."

# Prompt to confirm if the user is okay with the script potentially asking for root privileges
read -rp "This script may request root privileges to [do some stuff...???]. Do you wish to proceed? [y/N]: " confirm </dev/tty

confirm=$(echo "$confirm" | xargs)

if [[ ! $confirm =~ ^[Yy]$ ]]; then
  echo "Aborting."
  exit 1
fi

# check if Homebrew is already installed
echo "Checking if Homebrew is already installed..."
if command_exists brew; then
  echo "Homebrew already installed"
else
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /usr/bin/env bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # check if installation was successful
  echo "Checking if Homebrew was installed successfully..."
  if command_exists brew; then
    echo "Homebrew installed successfully"
  else
    echo "Homebrew installation failed"
    exit 1
  fi
fi

# set up Homebrew in current shell
echo "Setting up Homebrew in current shell..."
eval "$(/opt/homebrew/bin/brew shellenv)"

# update & upgrade Homebrew
echo "Updating Homebrew..."
brew update
echo "Upgrading Homebrew..."
# brew upgrade

dotfiles_dir="$HOME/.dotfiles" # TODO: add support for XDG

# Make sure dotfiles repository exists
echo "Ensuring dotfiles repository exists..."
if [ ! -d "$dotfiles_dir" ]; then
  echo "Cloning dotfiles repository..."
  # TODO: uncomment
  #
  # git clone https://github.com/peter-bread/.dotfiles "$dotfiles_dir"
else
  echo "Dotfiles repository already exists"

  read -rp "Do you wish to overwrite it? [y/N]: " confirm </dev/tty

  confirm=$(echo "$confirm" | xargs)

  if [[ $confirm =~ ^[Yy]$ ]]; then
    echo "Overwriting dotfiles..."
    # TODO: uncomment
    #
    # rm -rf "$dotfiles_dir"
    # git clone https://github.com/peter-bread/.dotfiles "$dotfiles_dir"
  fi
fi

echo "Applying dotfiles..."
# cd "$dotfiles_dir"
# if [ -f install.sh ]; then
#   /bin/bash install.sh
# else
#   echo "No install.sh script found in $dotfiles_dir, Please ensure it exists"
#   exit 1
# fi

# TODO: continue bootstrap script

echo -e "\nRestart your shell to make sure changes take effect."

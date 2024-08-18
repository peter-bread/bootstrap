#!/usr/bin/env bash

# check if a command exists silently
_command_exists() {
  command -v "$1" &>/dev/null
}

# should only need root priveliges when necessary
if [[ $EUID -eq 0 ]]; then
  echo "This script must NOT be run as root (DO NOT use sudo)"
  exit 1
fi

echo "Staring bootstrap..."

echo "Checking for xcode command line tools..."
if ! _command_exists xcode-select -p; then
  echo "xcode must be installed (run xcode-select --install)"
  xcode-select --install
fi
echo "xcode command line tools installed."

# make sure curl is installed to be able to run remotely
echo "Checking for curl..."
if ! _command_exists curl; then
  echo "curl is required to execute this script remotely."
  echo "If curl is not available on this system, download the script to a USB drive and run it from there."
  exit 1
fi
echo "curl installed."

# Prompt to confirm if the user is okay with the script potentially asking for root privileges
read -rp "This script may request root privileges to [do some stuff...???]. Do you wish to proceed? [y/N]: " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
  echo "Aborting."
  exit 1
fi

# check if Homebrew is already installed
echo "Checking if Homebrew is already installed..."
if _command_exists brew; then
  echo "Homebrew already installed"
else
  echo "Installing Homebrew..."
  /usr/bin/env bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # check if installation was successful
  echo "Checking if Homebrew was installed successfully..."
  if _command_exists brew; then
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

# ensure Git is installed
echo "Checking if Git is already installed..."
if _command_exists git; then
  echo "Git is already installed"
else
  echo "Installing Git..."
  brew install git

  # check if installation was successful
  echo "Checking if Git was installed successfully..."
  if _command_exists brew; then
    echo "Git installed successfully"
  else
    echo "Git installation failed"
    exit 1
  fi
fi

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
  # TODO: add option to overwrite ???
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

echo -e "\nRestart shell"

#!/usr/bin/env bash

# Set colours =================================================================

export default="\e[39m"
export red="\e[0;31m"
export green="\e[32m"
export yellow="\e[33m"
export blue="\e[34m"

export bold="\e[1m"
export reset="\e[0m"

# Set important environment variables =========================================

# dotfiles
export DOTFILES="$HOME/.dotfiles"

# xdg
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Utility functions ===========================================================

function notify() {
  echo -e "${blue}${1}${default}"
}

function success() {
  echo -e "${green}${1}${default}"
}

function warn() {
  echo -e "${yellow}${bold}${1}${default}${reset}"
}

function error() {
  echo -e "${red}${1}${default}"
}

function command_exists() {
  command -v "$1" &>/dev/null
}

function validate_ssh_key_name() {
  [[ $1 =~ ^[a-z0-9_-]+$ ]]
}

function generate_ssh_key() {
  ssh-keygen -t ed25519 -f "$HOME/.ssh/${1}" -C "${2}"
}

# Web login to github. Automatically sets git protocol to ssh and requests
# public_key scope so ssh keys can be added later.
function github_login() {
  gh auth login --hostname GitHub.com --git-protocol \
    ssh --scopes "admin:public_key" --web
}

# Add ssh key to github account.
function github_add_ssh_key() {
  gh ssh-key add "${1}.pub" --title "$(whoami)@$(uname -n)" \
    --type authentication
}

# Reset GH CLI auth token to minimum scope.
function github_reset_scope() {
  gh auth refresh --reset-scopes
}

# Bootstrap ===================================================================

# Checks ----------------------------------------------------------------------

notify "Checking OS..."

# OS
OS=$(uname)

if [[ $OS != "Darwin" ]]; then
  error "Error: This script only works on MacOS."
  exit 1
fi

notify "Checking privileges..."

# Root privileges
if [[ $EUID -eq 0 ]]; then
  error "Error: this script should not be run as root."
  error "Please run it as a regular user."
  exit 1
fi

# Start -----------------------------------------------------------------------

notify "Starting bootstrap..."

notify "Changing into home directory..."
cd || exit 1

# Homebrew --------------------------------------------------------------------

# enure homebrew is installed
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

# set up homebrew in current shell
notify "Setting up Homebrew in current shell..."
eval "$(/opt/homebrew/bin/brew shellenv)"

# update & upgrade Homebrew
notify "Updating Homebrew..."
brew update
notify "Upgrading Homebrew..."
# brew upgrade

# Git / GitHub ----------------------------------------------------------------

notify "Setting up Git and GitHub..."

# get valid filename for new github ssh key
while true; do
  read -rp $'\e[33mName for SSH key (stored in $HOME/.ssh/<your_key_name>): \e[39m' keyfile

  if validate_ssh_key_name "$keyfile"; then
    success "Valid SSH key name!"
    break
  else
    error "Error: Invalid SSH key name!"
    error "Can only contain: lowercase letters, digits, underscores, hyphens."
    echo
  fi
done

# get email for new github ssh key
read -rp $'\e[33mEmail for SSH key: \e[39m' email

notify "Creating a new ed25519 SSH key pair for GitHub..."

generate_ssh_key "$keyfile" "$email"

if ! command_exists gh; then
  brew install gh
fi

notify "Authenticating with GitHub via browser..."
echo
warn "WARNING: When asked if you would like to add an SSH key to your account, select SKIP."

github_login
github_add_ssh_key "$keyfile"
github_reset_scope

unset -v keyfile
unset -v email

success "Should now be SSH authenticated with GitHub!"

# Dotfiles --------------------------------------------------------------------

notify "Attempting to clone dotfiles..."

if [[ ! -d $DOTFILES ]]; then
  git clone -c core.sshCommand="ssh -i ~/.ssh/${keyfile}" \
    git@github.com:peter-bread/.dotfiles.git "$DOTFILES"
else
  notify "Dotfiles repository already exists. Pulling latest changes..."
  cd "$DOTFILES" && git pull
fi

success "Dotfiles cloned!"

# change into dotfiles repo to install dotfiles
cd "$DOTFILES" || exit 1

if [[ -f $DOTFILES/install.sh ]]; then
  notify "Installing dotfiles..."
  echo
  echo
  if ! bash "$DOTFILES"/install.sh; then
    error "Error: Dotfiles installation failed!"
    exit 1
  fi
  echo
  echo
else
  error "Error: No install.sh found in $DOTFILES!"
  exit 1
fi

success "Dotfiles installed successfully!"

# Software Installation -------------------------------------------------------

#  Brewfile - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

notify "Starting software installation..."
notify "Checking for Brewfile..."

brewfile_essential=false
brewfile_full=false

if [[ -f $DOTFILES/homebrew/Brewfile_essential ]]; then
  brewfile_essential=true
fi

if [[ -f $DOTFILES/homebrew/Brewfile_full ]]; then
  brewfile_full=true
fi

if [[ $brewfile_essential && $brewfile_full ]]; then
  success "Two Brewfiles found!"

  read -rp $'\e[33mWhich Brewfile would you like to use? (e)ssential | (f)ull | (n)either : \e[39m' confirm

  if [[ $confirm =~ ^[Ee]$ ]]; then
    notify "Installing packages from Brewfile..."
    brew bundle install --file="$DOTFILES/homebrew/Brewfile_essential"
  elif [[ $confirm =~ ^[Ff]$ ]]; then
    notify "Installing packages from Brewfile..."
    brew bundle install --file="$DOTFILES/homebrew/Brewfile_full"
  else
    notify "Not using a Brewfile. Skipping..."
  fi

elif [[ $brewfile_essential ]]; then

  read -rp $'\e[33mWould you like to install packages from Brewfile (essential) (y/N): \e[39m' confirm

  if [[ $confirm =~ ^[Yy]$ ]]; then
    notify "Installing packages from Brewfile..."
    brew bundle install --file="$DOTFILES/homebrew/Brewfile_essential"
  fi

elif [[ $brewfile_full ]]; then
  read -rp $'\e[33mWould you like to install packages from Brewfile (full) (y/N): \e[39m' confirm

  if [[ $confirm =~ ^[Yy]$ ]]; then
    notify "Installing packages from Brewfile..."
    brew bundle install --file="$DOTFILES/homebrew/Brewfile_full"
  fi

else
  notify "Brewfile not found. Skipping..."
fi

unset -v confirm brewfile_essential brewfile_full

# TODO: install other packages
# TODO: add prompts to ask user if they want to install these packages

#  Other - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# mise
if ! command_exists mise; then
  brew install mise
fi

mise install

# sdkman

# ghcup

# rustup

echo
success "Bootstrap complete!"
echo
notify "Restart your shell for changes to take effect."

exit 0
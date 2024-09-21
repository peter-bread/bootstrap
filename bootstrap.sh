#!/usr/bin/env bash
# Set colours -----------------------------------------------------------------

export default="\e[39m"
export red="\e[0;31m"
export green="\e[32m"
export yellow="\e[33m"
export blue="\e[34m"

export bold="\e[1m"
export reset="\e[0m"

# Set important environment variables -----------------------------------------

# dotfiles
export DOTFILES="$HOME/.dotfiles"

# xdg
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Utility functions -----------------------------------------------------------

function command_exists() {
  command -v "$1" &>/dev/null
}

function generate_ssh_key() {
  ssh-keygen -t ed25519 -f "$HOME/.ssh/${1}" -C "${2}"
}

# Web login to github. Automatically sets git protocol to ssh and requests
# public_key scope so ssh keys can be added later.
function github_login() {
  gh auth login --hostname GitHub.com --git-protocol ssh --scopes "admin:public_key" --web
}

# Add ssh key to github account.
function github_add_ssh_key() {
  gh ssh-key add "${1}.pub" --title "$(whoami)@$(uname -n)" --type authentication
}

# Reset GH CLI auth token to minimum scope.
function github_reset_scope() {
  gh auth refresh --reset-scopes
}

# Bootstrap -------------------------------------------------------------------

OS=$(uname)

if [[ $OS != "Darwin" ]]; then
  echo "${red}Error: This script only works on MacOS.${default}"
  exit 1
fi

echo -e "${blue}Starting bootstrap...${default}"

echo -e "${blue}Changing into home directory...${default}"
cd || exit 1

# enure homebrew is installed
if ! command_exists brew; then
  echo -e "${blue}Installing Homebrew...${default}"
  NONINTERACTIVE=1 /usr/bin/env bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # TODO: check if successful
fi

# set up homebrew in current shell
echo -e "${blue}Setting up Homebrew in current shell...${default}"
eval "$(/opt/homebrew/bin/brew shellenv)"

# update & upgrade Homebrew
echo -e "${blue}Updating Homebrew...${default}"
brew update
echo -e "${blue}Upgrading Homebrew...${default}"
# brew upgrade

echo -e "${blue}Creating a new ed25519 SSH key pair for GitHub...${default}"

# get filename and email for new github ssh key
read -rp $'\e[33mName for SSH key (stored in $HOME/.ssh/<your_key_name>): \e[39m' keyfile
read -rp $'\e[33mEmail for SSH key: \e[39m' email

# TODO: validate keyfile: CANNOT contain any spaces

generate_ssh_key "$keyfile" "$email"

if ! command_exists gh; then
  brew install gh
fi

echo -e "${blue}Authenticating with GitHub via browser...${default}"
echo
echo -e "${yellow}${bold}WARNING: When asked if you would like to add an SSH key to your account, select SKIP.${default}${reset}"

github_login

github_add_ssh_key "$keyfile"

github_reset_scope

echo -e "${green}Should now be SSH authenticated with GitHub!${default}"

echo -e "${blue}Attempting to clone dotfiles...${default}"
# TODO: check if dotfiles already exists and ask to override
git clone -c core.sshCommand="ssh -i ~/.ssh/${keyfile}" git@github.com:peter-bread/.dotfiles.git "$DOTFILES"
# TODO: check if clone was successful

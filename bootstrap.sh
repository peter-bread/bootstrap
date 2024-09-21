#!/usr/bin/env bash
# Set colours -----------------------------------------------------------------

export default="\e[39m"
export red="\e[0;31m"
export green="\e[32m"
export yellow="\e[33m"
export blue="\e[34m"

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
fi

# set up homebrew in current shell
echo -e "${blue}Setting up Homebrew in current shell...${default}"
eval "$(/opt/homebrew/bin/brew shellenv)"

# update & upgrade Homebrew
echo -e "${blue}Updating Homebrew...${default}"
brew update
echo -e "${blue}Upgrading Homebrew...${default}"
# brew upgrade

# get filename and email for new github ssh key
echo -e "${blue}Creating a new ed25519 SSH key pair for GitHub...${default}"

read -rp $'\e[33mName for SSH key (stored in $HOME/.ssh/<your_key_name>): \e[39m' keyfile
read -rp $'\e[33mEmail for SSH key: \e[39m' email

# =============================================================================
# =========== TEMPORARY TO PREVENT ACCIDENTAL CHANGES TO MY SYSTEM ============
# =============================================================================
exit 1

# TODO: validate keyfile: CANNOT contain any spaces

generate_ssh_key "$keyfile" "$email"

brew install gh

# login and add ssh key to github account
gh auth login

echo -e "${green}Should now be SSH authenticated with GitHub!${default}"

echo -e "${blue}Attempting to clone dotfiles...${default}"
# TODO: check if dotfiles already exists and ask to override
git clone -c core.sshCommand="ssh -i ~/.ssh/${keyfile}" git@github.com:peter-bread/.dotfiles.git "$DOTFILES"
# TODO: check if clone was successful

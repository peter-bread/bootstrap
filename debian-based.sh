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

# development
export DEVELOPER="$HOME/Developer"

# xdg
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# zsh
export ZSH_COMPLETIONS="$XDG_DATA_HOME/zsh/completions"

# gh cli
export GH_CONFIG_DIR="$XDG_CONFIG_HOME/gh"

# Utility functions ===========================================================

function notify() {
  if [[ $quiet -eq 0 ]]; then
    echo -e "${blue}${1}${default}"
  fi
}

function success() {
  if [[ $quiet -eq 0 ]]; then
    echo -e "${green}${1}${default}"
  fi
}

function warn() {
  echo -e "${yellow}${bold}${1}${default}${reset}" >&2
}

function error() {
  echo -e "${red}${1}${default}" >&2
}

function command_exists() {
  command -v "${1}" &>/dev/null
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
  gh auth login --hostname GitHub.com --skip-ssh-key \
    --git-protocol ssh --scopes "admin:public_key" --web
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

function show_help() {
  echo "Usage:"
  echo "  curl -sL <link> | bash [ -s -- [options] ]    Download & run script"
  echo "  cat <script> | bash [ -s -- [options] ]       Run downloaded script"
  echo "  bash <script> [options]                       Run downloaded script"
  echo
  echo "Options:"
  echo "  -h, --help                                Display this help and exit"
  echo "  -e <value>, --email[=<value>]             Specify email for GitHub SSH key"
  echo "  -i <basename>, --identity[=<basename>]    Specify basename for GitHub SSH key (stored in ~/.ssh/<basename>)"
  echo "  -p <value>, --packages[=<value>]          Which packages to use ((f)ull | (e)ssential | (n)one)"
  echo "  -q, --quiet                               Suppress non-error output"
  echo "  --no-dotfiles                             Don't install or apply dotfiles"
}

# Bootstrap ===================================================================

# Parse Options ---------------------------------------------------------------

email=""
identity=""
packages=""
quiet=0
no_dotfiles=0

while [[ $# -gt 0 ]]; do
  case $1 in
  # help
  -h | --help)
    show_help
    exit 0
    ;;

  # email
  -e)
    if [[ -n $2 && $2 != -* ]]; then
      email=$2
      shift 2
    else
      error "Error: -e requires a non-empty argument" >&2
      exit 1
    fi
    ;;
  --email)
    if [[ -n $2 && $2 != -* ]]; then
      email=$2
      shift 2
    else
      error "Error: --email requires a non-empty argument" >&2
      exit 1
    fi
    ;;
  --email=*)
    email="${1#--email=}"
    if [[ -z $email ]]; then
      error "Error: --email requires a non-empty argument." >&2
      exit 1
    fi
    shift
    ;;

  # identity
  -i)
    if [[ -n $2 && $2 != -* ]]; then
      identity=$2
      shift 2
    else
      error "Error: -i requires a non-empty argument" >&2
      exit 1
    fi
    ;;
  --identity)
    if [[ -n $2 && $2 != -* ]]; then
      identity=$2
      shift 2
    else
      error "Error: --identity requires a non-empty argument" >&2
      exit 1
    fi
    ;;
  --identity=*)
    identity="${1#--identity=}"
    if [[ -z $identity ]]; then
      error "Error: --identity requires a non-empty argument." >&2
      exit 1
    fi
    shift
    ;;

  # packages
  -p)
    if [[ -n $2 && $2 != -* ]]; then
      packages=$2
      shift 2
    else
      error "Error: -p requires a non-empty argument" >&2
      exit 1
    fi
    ;;
  --packages)
    if [[ -n $2 && $2 != -* ]]; then
      packages=$2
      shift 2
    else
      error "Error: --packages requires a non-empty argument" >&2
      exit 1
    fi
    ;;
  --packages=*)
    packages="${1#--packages=}"
    if [[ -z $packages ]]; then
      error "Error: --packages requires a non-empty argument." >&2
      exit 1
    fi
    shift
    ;;

  # quiet
  -q | --quiet)
    quiet=1
    shift
    ;;

  # no dotfiles
  --no-dotfiles)
    no_dotfiles=1
    shift
    ;;
  *)
    error "Error: unrecognised option: $1"
    exit 1
    ;;
  esac
done

# Validate Options ------------------------------------------------------------

if [[ -n $identity ]]; then
  if ! validate_ssh_key_name "$identity"; then
    error "Error: Invalid SSH key name!"
    error "Can only contain: lowercase letters, digits, underscores, hyphens."
    exit 1
  fi
fi

if [[ -n $packages ]]; then
  case $packages in
  f | F | full)
    packages="f"
    ;;
  e | E | essential)
    packages="e"
    ;;
  n | N | none)
    packages="n"
    ;;
  *)
    packages="invalid"
    ;;
  esac

  if [[ $packages == "invalid" ]]; then
    error "Error: invalid packages file!"
    error "Accepted values: [ f | F | full ]; [ e | E | essential ]; [ n | N | none ]"
    exit 1
  fi
fi

# Checks ----------------------------------------------------------------------

# Operating System
notify "Checking Operating System..."

OS=$(uname -s)

if [[ $OS != "Linux" ]]; then
  error "Error: This script only works on Linux."
  exit 1
fi

DISTRO=$(grep "^ID=" /etc/os-release | cut -d '=' -f 2 | tr -d '"')
DISTRO_LIKE=$(grep "^ID_LIKE=" /etc/os-release | cut -d '=' -f 2 | tr -d '"')

if [[ $DISTRO_LIKE != *debian* ]]; then
  error "Error: This script only works on Debian-based distros (e.g. Debian, Ubuntu, Mint, Pop!_OS)."
  error "${DISTRO} is ${DISTRO_LIKE}-based."
  exit 1
fi

success "DISTRO: ${DISTRO} is ${DISTRO_LIKE}-based. OK!"

# Root privileges
notify "Checking privileges..."

if [[ $EUID -eq 0 ]]; then
  error "Error: this script should not be run as root."
  error "Please run it as a regular user."
  exit 1
fi

success "Running as regular user!"

# Start -----------------------------------------------------------------------

notify "${bold}Starting bootstrap...${reset}"

notify "Changing into home directory..."
cd || exit 1

# APT -------------------------------------------------------------------------

notify "Getting system up to date..."

sudo apt-get update && sudo apt-get upgrade -y

success "System packages are up to date!"

# Git / GitHub ----------------------------------------------------------------

notify "Setting up Git and GitHub..."

notify "Requesting key filename and email for GitHub SSH key..."

if [[ -n $identity ]]; then
  success "SSH identity file name passed in on command line. Skipping..."
else

  # get valid filename for new github ssh key
  while true; do
    read -rp $'\e[33mName for SSH key (stored in $HOME/.ssh/<your_key_name>): \e[39m' identity

    if validate_ssh_key_name "$identity"; then
      success "Valid SSH key name!"
      break
    else
      error "Error: Invalid SSH key name!"
      error "Can only contain: lowercase letters, digits, underscores, hyphens."
    fi
  done

fi

if [[ -n $email ]]; then
  success "Email passed in on command line. Skipping..."
else
  # get email for new github ssh key
  read -rp $'\e[33mEmail for SSH key: \e[39m' email
  # TODO: create loop to validate email address
  # for now this will just be making sure it is non-empty
  # later can extend to containing @ etc
fi

notify "Creating a new ed25519 SSH key pair for GitHub..."

generate_ssh_key "$identity" "$email"

if ! command_exists gh; then
  sudo apt-get install gh -y
fi

notify "Authenticating with GitHub via browser..."

github_login
github_add_ssh_key "$identity"
github_reset_scope

unset -v email

ssh -i "$HOME/.ssh/${identity}" -T git@github.com

exit_code="$?"

if [[ $exit_code != 1 ]]; then
  error "Error: Not authenticated with GutHub!"
  exit 1
fi

unset -v exit_code

success "SSH authenticated with GitHub!"

# Dotfiles --------------------------------------------------------------------

if [[ $no_dotfiles -eq 1 ]]; then
  notify "Chose to not install dotfiles. Skipping..."
else

  notify "Attempting to clone dotfiles..."

  if [[ ! -d $DOTFILES ]]; then
    git clone \
      --config core.sshCommand="ssh -i ~/.ssh/${identity}" \
      git@github.com:peter-bread/.dotfiles.git "$DOTFILES"
  else
    notify "Dotfiles repository already exists. Pulling latest changes..."
    cd "$DOTFILES" && git pull
  fi

  success "Dotfiles repo cloned and up to date!"

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

fi

# Software Installation -------------------------------------------------------

# APT - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

notify "Starting software installation..."
notify "Checking for packages.txt..."

packages_essential=false
packages_full=false

if [[ -f $DOTFILES/apt/packages_essential.txt ]]; then
  packages_essential=true
fi

if [[ -f $DOTFILES/apt/packages_full.txt ]]; then
  packages_full=true
fi

if [[ -n $packages ]]; then
  case $packages in
  f)
    if [[ $packages_full == true ]]; then
      notify "Installing packages from packages.txt (full)..."
      xargs sudo apt-get install -y <"$DOTFILES/apt/packages_full.txt"
    else
      error "Error: packages.txt not found!"
      exit 1
    fi
    ;;
  esac
fi

if ! xargs sudo apt-get install -y <packages.txt; then
  error "Error: failed to install all packages."
  exit 1
fi

success "Packages installed!"

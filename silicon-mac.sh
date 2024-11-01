#!/usr/bin/env bash

# Set colours =================================================================

export default="\e[39m"
export red="\e[0;31m"
export green="\e[32m"
export yellow="\e[33m"
export blue="\e[34m"

export bold="\e[1m"
export reset="\e[0m"
export ul="\e[4m"

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
    --git-protocol ssh \
    --scopes "admin:public_key,admin:ssh_signing_key" \
    --web
}

# Add ssh key to github account.
function github_add_ssh_public_key() {
  gh ssh-key add "${1}.pub" \
    --title "$(whoami)@$(uname -n)" \
    --type authentication
}

function github_add_ssh_signing_key() {
  gh ssh-key add "${1}.pub" \
    --title "$(whoami)@$(uname -n)" \
    --type signing
}

# Reset GH CLI auth token to minimum scope.
function github_reset_scope() {
  gh auth refresh --reset-scopes
}

function show_help() {
  echo -e "${bold}${ul}Usage${reset}:"
  echo "  curl -sL <link> | bash [ -s -- [options] ]    Download & run script"
  echo "  cat <script> | bash [ -s -- [options] ]       Run downloaded script"
  echo "  bash <script> [options]                       Run downloaded script"
  echo
  echo -e "${bold}${ul}Options${reset}:"
  echo "  -h, --help                              Display this help and exit"
  echo "  -e <value>, --email=<value>             Specify email for GitHub SSH key"
  echo "  -i <basename>, --identity=<basename>    Specify basename for GitHub SSH key"
  echo "                                            (stored in ~/.ssh/<basename>)"
  echo "  -b <value>, --brewfile=<value>          Which Brewfile to use"
  echo "                                            [ (f)ull | (e)ssential | (n)one ]"
  echo "  -q, --quiet                             Suppress non-error output"
  echo "  --no-dotfiles                           Don't install or apply dotfiles"
}

# Bootstrap ===================================================================

# Parse Options ---------------------------------------------------------------

email=""
identity=""
brewfile=""
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

  # brewfile
  -b)
    if [[ -n $2 && $2 != -* ]]; then
      brewfile=$2
      shift 2
    else
      error "Error: -b requires a non-empty argument" >&2
      exit 1
    fi
    ;;
  --brewfile)
    if [[ -n $2 && $2 != -* ]]; then
      brewfile=$2
      shift 2
    else
      error "Error: --brewfile requires a non-empty argument" >&2
      exit 1
    fi
    ;;
  --brewfile=*)
    brewfile="${1#--brewfile=}"
    if [[ -z $brewfile ]]; then
      error "Error: --brewfile requires a non-empty argument." >&2
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

if [[ -n $brewfile ]]; then
  case $brewfile in
  f | F | full)
    brewfile="f"
    ;;
  e | E | essential)
    brewfile="e"
    ;;
  n | N | none)
    brewfile="n"
    ;;
  *)
    brewfile="invalid"
    ;;
  esac

  if [[ $brewfile == "invalid" ]]; then
    error "Error: invalid Brewfile!"
    error "Accepted values: [ f | F | full ]; [ e | E | essential ]; [ n | N | none ]"
    exit 1
  fi
fi

# Checks ----------------------------------------------------------------------

# Operating System
notify "Checking Operating System..."

OS=$(uname -s)

if [[ $OS != "Darwin" ]]; then
  error "Error: This script only works on MacOS."
  exit 1
fi

success "OS: ${OS}. OK!"

# CPU Architecture
notify "Checking CPU Architecture..."

ARCH=$(uname -m)

if [[ $ARCH != *"arm"* ]]; then
  error "Error: This script only works on arm64."
  exit 1
fi

success "ARCH: ${ARCH}. OK!"

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

# Homebrew --------------------------------------------------------------------

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
# brew upgrade

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
  brew install gh
fi

notify "Authenticating with GitHub via browser..."

github_login
github_add_ssh_public_key "$identity"
github_add_ssh_signing_key "$identity"
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

# Brewfile - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

notify "Starting software installation..."
notify "Checking for Brewfile..."

package_manager="brew"
package_dir="$DOTFILES/packages/${package_manager}"

essential=false
full=false

if [[ -f ${package_dir}/essential ]]; then
  essential=true
fi

if [[ -f ${package_dir}/full ]]; then
  full=true
fi

if [[ -n $brewfile ]]; then
  case $brewfile in
  f)
    if [[ $full == true ]]; then
      notify "Installing packages from Brewfile (full)..."
      brew bundle install --file="${package_dir}/full"
    else
      error "Error: Brewfile not found!"
      exit 1
    fi
    ;;
  e)
    if [[ $essential == true ]]; then
      notify "Installing packages from Brewfile (essential)..."
      brew bundle install --file="${package_dir}/essential"
    else
      error "Error: Brewfile not found!"
      exit 1
    fi
    ;;
  n)
    notify "Not using a Brewfile. Skipping..."
    ;;
  esac
else

  if [[ $essential && $full ]]; then
    success "Two Brewfiles found!"

    read -rp $'\e[33mWhich Brewfile would you like to use? (f)ull | (e)ssential | (n)one : \e[39m' confirm

    if [[ $confirm =~ ^[Ee]$ ]]; then
      notify "Installing packages from Brewfile..."
      brew bundle install --file="${package_dir}/essential"
    elif [[ $confirm =~ ^[Ff]$ ]]; then
      notify "Installing packages from Brewfile..."
      brew bundle install --file="${package_dir}/full"
    else
      notify "Not using a Brewfile. Skipping..."
    fi

  elif [[ $essential ]]; then

    read -rp $'\e[33mWould you like to install packages from Brewfile (essential) (y/N): \e[39m' confirm

    if [[ $confirm =~ ^[Yy]$ ]]; then
      notify "Installing packages from Brewfile..."
      brew bundle install --file="${package_dir}/essential"
    else
      notify "Not using a Brewfile. Skipping..."
    fi

  elif [[ $full ]]; then
    read -rp $'\e[33mWould you like to install packages from Brewfile (full) (y/N): \e[39m' confirm

    if [[ $confirm =~ ^[Yy]$ ]]; then
      notify "Installing packages from Brewfile..."
      brew bundle install --file="${package_dir}/full"
    else
      notify "Not using a Brewfile. Skipping..."
    fi

  else
    notify "Brewfile not found. Skipping..."
  fi
fi

unset -v confirm brewfile essential full

# TODO: install other packages
# TODO: add prompts to ask user if they want to install these packages

# Other - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# create directory to store user-specific zsh completions
mkdir -p "$ZSH_COMPLETIONS"

# mise - - - - - - - - - - - - - - - - - - - - - - - - - -

if ! command_exists mise; then
  brew install mise
fi

mise install

eval "$(mise hook-env -s zsh)" # make mise binaries available in this script

# sdkman - - - - - - - - - - - - - - - - - - - - - - - - -

curl -s "https://get.sdkman.io?rcupdate=false" | bash
# TODO: install LTS versions: 8, 11, 17, 21

# ghcup - - - - - - - - - - - - - - - - - - - - - - - - - -

curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org |
  BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_GHC_VERSION="recommended" \
    BOOTSTRAP_HASKELL_CABAL_VERSION="recommended" \
    BOOTSTRAP_HASKELL_STACK_VERSION="recommended" \
    BOOTSTRAP_HASKELL_HLS_VERSION="recommended" \
    sh

curl -sSf https://raw.githubusercontent.com/haskell/ghcup-hs/refs/heads/master/scripts/shell-completions/zsh \
  >"$ZSH_COMPLETIONS/_ghcup"

# rustup - - - - - - - - - - - - - - - - - - - - - - - - - -

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
  sh -s -- --no-modify-path -y

source "$HOME/.cargo/env"

rustup completions zsh >"$ZSH_COMPLETIONS/_rustup"

# neovim - - - - - - - - - - - - - - - - - - - - - - - - - -

if ! command_exists nvim; then
  brew install neovim
fi

git clone \
  --config core.sshCommand="ssh -i ~/.ssh/${identity}" \
  git@github.com:peter-bread/peter.nvim.git "$XDG_CONFIG_HOME/nvim"

# 1. launch without ui
# 2. install plugins
# 3. load mason tool installer and install packages synchronously (see nvim config)
# 4. quit

nvim --headless \
  '+Lazy! restore' \
  '+Lazy! load mason-tool-installer.nvim' \
  +qa

# Finishing Up ----------------------------------------------------------------

unset -v identity

echo
quiet=0 success "Bootstrap complete!"
echo
quiet=0 notify "Restart your shell for changes to take effect."

exit 0

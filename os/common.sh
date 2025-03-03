#!/usr/bin/env bash

# Common utilities used across all systems

set -Eeuo pipefail

# Set colours =================================================================

default="\e[39m"
red="\e[0;31m"
green="\e[32m"
yellow="\e[33m"
blue="\e[34m"

bold="\e[1m"
reset="\e[0m"

# Utility functions ===========================================================

function notify() {
  echo -e "${blue}${1}${default}"
}

function success() {
  echo -e "${green}${1}${default}"
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

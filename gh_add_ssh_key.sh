#!/usr/bin/env bash

# This script adds an ssh key to a github account.
# It assumes that you have already authenticated with GH CLI.

function generate_ssh_key() {
  ssh-keygen -t ed25519 -f "${ssh}/${1}" -C "${2}"
}

function add_scope() {
  gh auth refresh -h github.com -s "${1}"
}

function remove_scope() {
  gh auth refresh -h github.com -r "${1}"
}

function add_key_to_github() {
  gh ssh-key add "${1}.pub" --title "$(whoami)@$(uname -n)" --type authentication
}

e1=false
e2=false

red="\e[31m"
default="\e[39m"
yellow="\e[33m"

email="${EMAIL:-}"

if [[ -z "$email" ]]; then
  printf "${red}error${default}: "
  printf "Set the ${yellow}EMAIL${default} environment variable before running this script:\n\n"
  printf "\t${yellow}export EMAIL=\"example@email.com\"${default}\n"
  e1=true
fi

keyfile="${KEYFILE:-}"

if [[ -z $keyfile ]]; then
  if [[ $e1 == true ]]; then
    printf "\n\n"
  fi
  printf "${red}error${default}: "
  printf "Set the ${yellow}KEYFILE${default} environment variable before running this script:\n\n"
  printf "\t${yellow}export KEYFILE=\"example-ssh-key-filename\"${default}\n"
  e2=true
fi

if [[ $e1 == true || $e2 == true ]]; then
  exit 1
fi

# ssh directory
ssh="$HOME/.ssh"

generate_ssh_key "$keyfile" "$email"

add_scope admin:public_key

add_key_to_github "${ssh}/${keyfile}"

remove_scope admin:public_key

exit 0

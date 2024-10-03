#!/usr/bin/env bash

show_help() {
  echo "Usage: $0 [-y | --yes] [-h | --help] [-e value | -e=value | --email value | --email=value]"
  echo
  echo "Options:"
  echo "  -y, --yes               Agree to the action (yes flag)"
  echo "  -h, --help              Display this help and exit"
  echo "  -e value                Specify the email"
  echo "  -e=value                Specify the email"
  echo "  --email value           Specify the email"
  echo "  --email=value           Specify the email"
}

# Initialise variables
yes_flag=0
email=""

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
  -y | --yes)
    yes_flag=1
    shift
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  -e)
    if [[ -n $2 && $2 != -* ]]; then
      email="$2"
      shift 2
    else
      echo "Error: -e requires a non-empty argument." >&2
      exit 1
    fi
    ;;
  --email)
    if [[ -n $2 && $2 != -* ]]; then
      email="$2"
      shift 2
    else
      echo "Error: --email requires a non-empty argument." >&2
      exit 1
    fi
    ;;
  -e=*)
    email="${1#-e=}"
    if [[ -z $email ]]; then
      echo "Error: -e requires a non-empty argument." >&2
      exit 1
    fi
    shift
    ;;
  --email=*)
    email="${1#--email=}"
    if [[ -z $email ]]; then
      echo "Error: --email requires a non-empty argument." >&2
      exit 1
    fi
    shift
    ;;
  *)
    echo "Invalid option: $1" >&2
    show_help
    exit 1
    ;;
  esac
done

# Handle options
if [[ $yes_flag -eq 1 ]]; then
  echo "Yes flag enabled"
fi

if [[ -n $email ]]; then
  echo "Email provided: $email"
fi

#!/usr/bin/env bash

# this is a directory in FPATH
completion_dir="/usr/local/share/zsh/site-functions"

OS=$(uname)

if [[ "$OS" == "Darwin" ]]; then
  echo "brew"
fi

# non-package manager installs =================================================

# ghcup (haskell toolchain) ----------------------------------------------------

# install ghcup
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# zsh completion
curl -sL https://raw.githubusercontent.com/haskell/ghcup-hs/master/scripts/shell-completions/zsh \
  >"$completion_dir"/_ghcup

# zig completion ---------------------------------------------------------------

curl -sL https://raw.githubusercontent.com/ziglang/shell-completions/master/_zig \
  >"$completion_dir"/_zig

# rustup (rust toolchain) ------------------------------------------------------

# install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# zsh completion
rustup completions zsh >"$completion_dir"/_rustup

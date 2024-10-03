# Bootstrap

<!-- markdownlint-disable MD013 -->

Collection of bootstrap scripts to set up on different systems with minimal effort.

> [!WARNING]
> Dotfiles repo is private.
>
> Dotfiles installation will fail without SSH authentication.

## Usage

```text
Usage:
  curl -sL <link> | bash [ -s -- [options] ]    Download & run script
  cat <script> | bash [ -s -- [options] ]       Run downloaded script
  bash <script> [options]                       Run downloaded script

Options:
  -h, --help                                Display this help and exit
  -e <value>, --email[=<value>]             Specify email for GitHub SSH key
  -i <basename>, --identity[=<basename>]    Specify basename for GitHub SSH key (stored in ~/.ssh/<basename>)
  -b <value>, --brewfile[=<value>]          Which Brewfile to use ((f)ull | (e)ssential | (n)one)
  -q, --quiet                               Suppress non-error output
```

## Silicon Mac

Assumes `curl` is installed by default.

```sh
curl -sL https://raw.githubusercontent.com/peter-bread/bootstrap/main/silicon-mac.sh | bash
```

With options:

```sh
curl -sL https://raw.githubusercontent.com/peter-bread/bootstrap/main/silicon-mac.sh | bash -s -- [options]
```

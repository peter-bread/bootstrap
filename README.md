# Bootstrap

<!-- markdownlint-disable MD013 -->

Bootstrap scripts to set up on different systems with minimal effort.

> [!WARNING]
> Dotfiles repo is private.
>
> Dotfiles installation will fail without SSH authentication.

## Usage

Download the main entry point script:

<!-- TODO: remember to keep this link up to date -->

```bash
curl -sLO https://raw.githubusercontent.com/peter-bread/bootstrap/refs/heads/rewrite/bootstrap.sh
```

Verify integrity:

<!-- TODO: remember to keep this checksum up to date -->

```bash
echo "517c7d359aacec5665dcdbfb2bba86fa944c7dc1b5351ee9a7ccb4db9b4fc23c  bootstrap.sh" | sha256sum --check
```

> [!WARNING]
> If verification fails, DO NOT RUN the script, delete it manually instead:
>
> ```bash
> rm -f bootstrap.sh
> ```
>
> Then, try downloading again.

| Flag      | Args | Optional | Description                                                    |
| --------- | ---- | -------- | -------------------------------------------------------------- |
| `--local` | none | ✅       | Run latest changes from local git repo, i.e. do not clone this |

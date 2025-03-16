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
echo "8744d5e1080ba0abbf9bbefb842909f8ed449771317fd0d3084d23fe000c8ab5  bootstrap.sh" | sha256sum --check
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

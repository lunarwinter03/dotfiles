# dotfiles

Managed with `dot`, see `dot help`.

## Layout

- `modules/<name>/` – `packages.txt`, `links.txt`, optional `setup.sh` (`setup`, `teardown`)
- `hosts/<hostname>.txt` – modules of a machine, fallback `default.txt`

## Conventions

- Generated files carry a short "generated, do not edit" note.
- Configs never reference the repo, only their location on the system.
- Modules extend other configs through drop-in directories (e.g. `~/.config/zsh/conf.d/`), never by editing them.

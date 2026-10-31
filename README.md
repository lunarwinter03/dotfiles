# dotfiles

Managed with `dot`, see `dot help`.

## Layout

- `modules/<name>/` – `packages.txt`, `links.txt`, optional `setup.sh`
- `hosts/<hostname>/` – `modules.txt`, optional `packages.txt`, `links.txt`, `setup.sh` for this machine only; fallback `hosts/default/`

## Parts

A part of a module is addressed by one name. It covers the package of that
name, all links whose source starts with that name, and `setup_<name>` /
`teardown_<name>` in `setup.sh` (`PARTS=(...)` sets the order).

In `modules.txt`, `-<part>` excludes a part of the module above it:

    security
    -usbguard

`dot remove <module>/<part>` undoes a single part.

## Conventions

- Generated files carry a short "generated, do not edit" note.
- Configs never reference the repo, only their location on the system.
- Modules extend other configs through drop-in directories (e.g. `~/.config/zsh/conf.d/`), never by editing them.

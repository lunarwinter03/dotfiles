#!/usr/bin/env bash
# Richtet die dotfiles auf einem Arch-System ein.
#
# Aufruf:  ./install.sh      ausführen
#          ./install.sh -n   Probelauf: nur anzeigen, was passieren würde
#
# Wiederholbar: Bereits Erledigtes wird übersprungen,
# Vorhandenes wird gesichert statt überschrieben.

set -euo pipefail

DOTFILES="$HOME/dotfiles"
BACKUP_DIR="$HOME/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0

if [[ "${1:-}" == "-n" ]]; then
  DRY_RUN=1
fi

# ===================== Hilfsfunktionen =====================

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# Führt einen Befehl aus, oder zeigt ihn im Probelauf nur an
run() {
  if (( DRY_RUN )); then
    printf '   [probe] %s\n' "$*"
  else
    "$@"
  fi
}

# Legt einen Symlink an. Vorhandenes wird vorher gesichert.
link() {
  local src="$1" dst="$2"

  if [[ ! -e "$src" ]]; then
    warn "Quelle fehlt, übersprungen: $src"
    return
  fi

  # Schon richtig verlinkt? Dann nichts tun.
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    printf '   ok   %s\n' "$dst"
    return
  fi

  # Datei, Ordner oder fremder Symlink am Ziel: sichern
  if [[ -e "$dst" || -L "$dst" ]]; then
    local rel="${dst#"$HOME"/}"
    run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    run mv "$dst" "$BACKUP_DIR/$rel"
    warn "gesichert: $dst"
  fi

  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  printf '   neu  %s -> %s\n' "$dst" "$src"
}

# ===================== Schritte =====================

checks() {
  if (( EUID == 0 )); then
    die "Bitte nicht als root ausführen. sudo wird bei Bedarf selbst aufgerufen."
  fi
  if ! command -v pacman >/dev/null; then
    die "Dieses Skript ist für Arch Linux (pacman)."
  fi
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  if [[ ! -d "$DOTFILES" || "$here" != "$(cd "$DOTFILES" && pwd -P)" ]]; then
    die "Das Repo muss unter $DOTFILES liegen. Die Configs verweisen auf diesen Pfad."
  fi
}

install_packages() {
  info "Pakete installieren"
  local pkgs
  mapfile -t pkgs < <(
    sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
        "$DOTFILES/packages.txt" | grep -v '^$'
  )
  run sudo pacman -S --needed "${pkgs[@]}"
  run sudo pacman -D --asexplicit "${pkgs[@]}"
}

link_files() {
  info "Symlinks anlegen"
  local src dst
  while read -r src dst; do
    if [[ -z "$src" || "$src" == \#* ]]; then
      continue
    fi
    link "$DOTFILES/$src" "${dst/#\~/$HOME}"
  done < "$DOTFILES/links.txt"
}

link_host() {
  info "Rechnerspezifische Mango-Config"
  local host file
  host="$(hostnamectl hostname 2>/dev/null || cat /etc/hostname)"
  file="$DOTFILES/mango/hosts/$host.conf"
  if [[ ! -f "$file" ]]; then
    warn "Keine Datei für Hostname '$host', verwende default.conf"
    file="$DOTFILES/mango/hosts/default.conf"
  fi
  link "$file" "$HOME/.config/mango/host.conf"
}

# Dateien, die unsere Configs unbemerkt überschreiben würden, beiseiteräumen
remove_overrides() {
  info "Störende Überbleibsel"
  local f found=0
  for f in "$HOME"/.config/kitty/{dark,light,no-preference}-theme.auto.conf \
           "$HOME/.config/xdg-desktop-portal/portals.conf"; do
    if [[ -e "$f" ]]; then
      found=1
      local rel="${f#"$HOME"/}"
      run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      run mv "$f" "$BACKUP_DIR/$rel"
      warn "gesichert und entfernt: $f"
    fi
  done
  if (( ! found )); then
    printf '   ok   nichts gefunden\n'
  fi
}

set_shell() {
  info "Login-Shell"
  local current
  current="$(getent passwd "$USER" | cut -d: -f7)"
  if [[ "$current" == "/usr/bin/zsh" ]]; then
    printf '   ok   zsh ist bereits Login-Shell\n'
  else
    run chsh -s /usr/bin/zsh
  fi
}

init_theme() {
  info "Theme erzeugen"
  run mkdir -p "$HOME/.local/state/theme"
  if [[ -f "$HOME/.local/state/theme/colors.json" ]]; then
    printf '   ok   Theme existiert bereits\n'
  else
    run "$DOTFILES/theme/bin/theme-apply" color hex "#7aa2f7" -m dark -t scheme-vibrant \
      || warn "matugen meldete Fehler. Außerhalb einer Mango-Sitzung ist das normal."
  fi
}

# ===================== Ablauf =====================

main() {
  checks
  if (( DRY_RUN )); then
    info "PROBELAUF: es wird nichts verändert"
  fi

  install_packages
  link_files
  link_host
  remove_overrides
  set_shell
  init_theme

  info "Fertig."
  if [[ -d "$BACKUP_DIR" ]]; then
    info "Gesicherte Dateien liegen in: $BACKUP_DIR"
  fi
  cat <<'EOF'

Noch von Hand:
  - Login-Manager auf Ly umstellen, falls ein anderer läuft
  - Wallpaper und Farben setzen: matugen image <bild> -m dark
EOF
}

main "$@"

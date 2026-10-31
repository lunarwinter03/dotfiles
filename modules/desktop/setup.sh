# Einrichtung für das Modul desktop (wird von dot aufgerufen)

setup() {
  setup_overrides
  setup_librewolf
  setup_gtk
  setup_theme
}

# Dateien, die unsere Configs unbemerkt überschreiben würden
setup_overrides() {
  info "desktop: störende Überbleibsel"
  local f found=0
  for f in "$HOME"/.config/kitty/{dark,light,no-preference}-theme.auto.conf \
           "$HOME/.config/xdg-desktop-portal/portals.conf"; do
    if [[ -e "$f" ]]; then
      found=1
      backup "$f" >/dev/null
      item weg "$f (gesichert)"
    fi
  done
  if (( ! found )); then
    item ok "nichts gefunden"
  fi
}

# LibreWolf: AutoConfig-Sandbox abschalten (Datei gehört keinem Paket)
setup_librewolf() {
  info "desktop: LibreWolf"
  local dir=/usr/lib/librewolf/defaults/pref
  local src="$MODULE_DIR/librewolf/dotfiles.js"
  local target="$dir/dotfiles.js"
  if [[ ! -d "$dir" ]]; then
    item --  "LibreWolf nicht installiert, übersprungen"
  elif cmp -s "$src" "$target"; then
    item ok "$target"
  else
    run sudo install -m 644 "$src" "$target"
    item neu "$target"
  fi
}

# GTK: Theme und Dunkelmodus (in dconf, nicht in einer Datei)
setup_gtk() {
  info "desktop: GTK"
  if ! command -v gsettings >/dev/null; then
    item -- "gsettings nicht vorhanden, übersprungen"
    return
  fi
  gtk_set gtk-theme    adw-gtk3-matugen
  gtk_set color-scheme prefer-dark
}

gtk_set() {
  local key="$1" value="$2" current
  current="$(gsettings get org.gnome.desktop.interface "$key" 2>/dev/null || true)"
  if [[ "$current" == "'$value'" ]]; then
    item ok "$key"
    return
  fi
  state_remember "gsettings.$key" "$current"
  run gsettings set org.gnome.desktop.interface "$key" "$value"
}

# Erstes Theme, falls noch keins existiert
setup_theme() {
  info "desktop: Theme"
  if [[ -f "$HOME/.local/state/theme/colors.json" ]]; then
    item ok "Theme existiert bereits"
    return
  fi
  run mkdir -p "$HOME/.local/state/theme"
  run "$MODULE_DIR/theme/bin/theme-apply" color hex "#7aa2f7" -m dark -t scheme-vibrant \
    || warn "matugen meldete Fehler. Außerhalb einer Mango-Sitzung ist das normal."
}

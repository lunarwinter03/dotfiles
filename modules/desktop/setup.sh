# Files that silently override our configs
OVERRIDES=(
  "$HOME/.config/kitty/dark-theme.auto.conf"
  "$HOME/.config/kitty/light-theme.auto.conf"
  "$HOME/.config/kitty/no-preference-theme.auto.conf"
  "$HOME/.config/xdg-desktop-portal/portals.conf"
)
LIBREWOLF_PREF=/usr/lib/librewolf/defaults/pref/dotfiles.js

setup() {
  info "desktop: overrides"
  local f found=0
  for f in "${OVERRIDES[@]}"; do
    if [[ -e "$f" ]]; then
      found=1
      backup "$f" >/dev/null
      item moved "$f"
    fi
  done
  if (( ! found )); then item ok "none"; fi

  # The pref file disables the AutoConfig sandbox. It belongs to no
  # package, so it survives updates.
  info "desktop: librewolf"
  if [[ ! -d "$(dirname "$LIBREWOLF_PREF")" ]]; then
    item skip "librewolf not installed"
  elif cmp -s "$MODULE_DIR/librewolf/dotfiles.js" "$LIBREWOLF_PREF"; then
    item ok "$LIBREWOLF_PREF"
  else
    run sudo install -m 644 "$MODULE_DIR/librewolf/dotfiles.js" "$LIBREWOLF_PREF"
    item new "$LIBREWOLF_PREF"
  fi

  info "desktop: gtk"
  if command -v gsettings >/dev/null; then
    gtk_set gtk-theme    adw-gtk3-matugen
    gtk_set color-scheme prefer-dark
  else
    item skip "gsettings not available"
  fi

  info "desktop: theme"
  if [[ -f "$HOME/.local/state/theme/colors.json" ]]; then
    item ok "exists"
  else
    run mkdir -p "$HOME/.local/state/theme"
    run "$MODULE_DIR/theme/bin/theme-apply" color hex "#7aa2f7" -m dark -t scheme-vibrant \
      || warn "matugen failed, expected outside a mango session"
  fi
}

teardown() {
  info "desktop: generated files"
  local out
  while read -r out; do
    out="${out/#\~/$HOME}"
    if [[ -e "$out" ]]; then
      run rm -f "$out"
      item removed "$out"
      prune_dirs "$(dirname "$out")"
    fi
  done < <(sed -n "s/^output_path *= *'\(.*\)'.*/\1/p" "$MODULE_DIR/theme/matugen.toml")
  if [[ -d "$HOME/.local/state/theme" ]]; then
    run rm -rf "$HOME/.local/state/theme"
    item removed "$HOME/.local/state/theme"
  fi

  info "desktop: librewolf"
  if [[ -f "$LIBREWOLF_PREF" ]]; then
    run sudo rm "$LIBREWOLF_PREF"
    item removed "$LIBREWOLF_PREF"
  else
    item ok "nothing to remove"
  fi

  info "desktop: gtk"
  if command -v gsettings >/dev/null; then
    gtk_restore gtk-theme    adw-gtk3-matugen
    gtk_restore color-scheme prefer-dark
    # Set by theme-apply on every run, so reset to the default
    run gsettings reset org.gnome.desktop.interface font-name
    run gsettings reset org.gnome.desktop.interface monospace-font-name
  fi

  info "desktop: overrides"
  local f
  for f in "${OVERRIDES[@]}"; do restore_backup "$f"; done
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
  item set "$key"
}

# Restore the value from before dot. Without one, reset only if it is still ours.
gtk_restore() {
  local key="$1" ours="$2" previous current
  previous="$(state_value "gsettings.$key")"
  if [[ -n "$previous" ]]; then
    run gsettings set org.gnome.desktop.interface "$key" "$previous"
    item restored "$key"
    return
  fi
  current="$(gsettings get org.gnome.desktop.interface "$key" 2>/dev/null || true)"
  if [[ "$current" == "'$ours'" ]]; then
    run gsettings reset org.gnome.desktop.interface "$key"
    item reset "$key"
  else
    item ok "$key not set by dot"
  fi
}

# Einrichtung für das Modul base (wird von dot aufgerufen)

setup() {
  info "base: Login-Shell"
  local current
  current="$(getent passwd "$USER" | cut -d: -f7)"
  if [[ "$current" == "/usr/bin/zsh" ]]; then
    item ok "zsh ist Login-Shell"
    return
  fi
  state_remember shell "$current"
  run chsh -s /usr/bin/zsh
}

PARTS=(zsh)

setup_zsh() {
  info "base: login shell"
  local current
  current="$(getent passwd "$USER" | cut -d: -f7)"
  if [[ "$current" == "/usr/bin/zsh" ]]; then
    item ok "zsh"
    return
  fi
  state_remember shell "$current"
  run chsh -s /usr/bin/zsh
}

teardown_zsh() {
  info "base: login shell"
  local previous
  previous="$(state_value shell)"
  if [[ -z "$previous" ]]; then
    item ok "unchanged by dot"
    return
  fi
  run chsh -s "$previous"
  item restored "$previous"
}

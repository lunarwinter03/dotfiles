PARTS=(tlp)

# TLP manages radio devices itself; systemd-rfkill would fight it on boot
RFKILL_UNITS=(systemd-rfkill.service systemd-rfkill.socket)

setup_tlp() {
  info "host: tlp"
  if systemctl is-enabled tlp.service >/dev/null 2>&1; then
    item ok "enabled"
  else
    state_remember tlp.enabled no
    run sudo systemctl enable --now tlp.service
    item enabled "tlp"
  fi
  local unit
  for unit in "${RFKILL_UNITS[@]}"; do
    if [[ "$(systemctl is-enabled "$unit" 2>/dev/null)" == "masked" ]]; then
      item ok "$unit masked"
    else
      state_remember "masked.$unit" no
      run sudo systemctl mask "$unit"
      item masked "$unit"
    fi
  done
}

teardown_tlp() {
  info "host: tlp"
  if [[ "$(state_value tlp.enabled)" == "no" ]]; then
    run sudo systemctl disable --now tlp.service
    item disabled "tlp"
  fi
  local unit
  for unit in "${RFKILL_UNITS[@]}"; do
    if [[ "$(state_value "masked.$unit")" == "no" ]]; then
      run sudo systemctl unmask "$unit"
      item unmasked "$unit"
    fi
  done
}

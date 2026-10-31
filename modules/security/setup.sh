USBGUARD_RULES=/etc/usbguard/rules.conf

setup() {
  info "security: usbguard"
  if systemctl is-enabled usbguard.service >/dev/null 2>&1; then
    item ok "enabled"
    return
  fi
  # Without rules usbguard blocks every device, including keyboard and mouse
  if ! sudo test -s "$USBGUARD_RULES"; then
    state_remember usbguard.rules generated
    run sudo sh -c "usbguard generate-policy > $USBGUARD_RULES"
    run sudo chmod 600 "$USBGUARD_RULES"
    item new "policy from currently connected devices"
  fi
  state_remember usbguard.enabled no
  run sudo systemctl enable --now usbguard.service
  item enabled "usbguard"
}

teardown() {
  info "security: usbguard"
  if [[ "$(state_value usbguard.enabled)" == "no" ]]; then
    run sudo systemctl disable --now usbguard.service
    item disabled "usbguard"
  else
    item ok "unchanged by dot"
  fi
  if [[ "$(state_value usbguard.rules)" == "generated" ]]; then
    run sudo truncate -s 0 "$USBGUARD_RULES"
    item cleared "$USBGUARD_RULES"
  fi
}

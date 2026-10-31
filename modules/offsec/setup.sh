SECLISTS_DIR="$HOME/.local/share/seclists"
SECLISTS_URL="https://github.com/danielmiessler/SecLists.git"

setup() {
  info "offsec: wireshark group"
  if id -nG "$USER" | tr ' ' '\n' | grep -qx wireshark; then
    item ok "member"
  else
    state_remember wireshark.group added
    run sudo usermod -aG wireshark "$USER"
    item added "takes effect after next login"
  fi

  info "offsec: seclists"
  if [[ ! -d "$SECLISTS_DIR/.git" ]]; then
    run git clone --depth 1 "$SECLISTS_URL" "$SECLISTS_DIR"
    run git -C "$SECLISTS_DIR" sparse-checkout set --no-cone '/*/'
    item new "$SECLISTS_DIR"
    return
  fi
  run git -C "$SECLISTS_DIR" sparse-checkout set --no-cone '/*/'
  if (( DRY_RUN )); then
    item check "$SECLISTS_DIR for updates"
    return
  fi
  local before after
  before="$(git -C "$SECLISTS_DIR" rev-parse HEAD)"
  git -C "$SECLISTS_DIR" pull --ff-only --quiet
  after="$(git -C "$SECLISTS_DIR" rev-parse HEAD)"
  if [[ "$before" == "$after" ]]; then
    item ok "up to date"
  else
    item updated "$SECLISTS_DIR"
  fi 
}

teardown() {
  info "offsec: wireshark group"
  if [[ "$(state_value wireshark.group)" == "added" ]]; then
    run sudo gpasswd -d "$USER" wireshark
    item removed "membership"
  else
    item ok "unchanged by dot"
  fi

  info "offsec: seclists"
  if [[ -d "$SECLISTS_DIR" ]]; then
    run rm -rf "$SECLISTS_DIR"
    item removed "$SECLISTS_DIR"
  fi
}

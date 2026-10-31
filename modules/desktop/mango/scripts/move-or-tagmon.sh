#!/usr/bin/env bash
# Verschiebt das fokussierte Fenster in eine Richtung.
# Bewegt es sich dabei nicht (es liegt am Monitorrand), wird es
# auf den Nachbarmonitor geschickt und dort an die Seite gesetzt,
# von der es gekommen ist.
#
# Aufruf: move-or-tagmon.sh left|right|up|down

set -euo pipefail

dir="${1:-}"
case "$dir" in
  left)  back=right ;;
  right) back=left  ;;
  up)    back=down  ;;
  down)  back=up    ;;
  *) echo "Aufruf: $0 left|right|up|down" >&2; exit 1 ;;
esac

# Monitor und Geometrie des fokussierten Fensters als eine Zeile
state() {
  mmsg get focusing-client | jq -r '
    if .id == null then empty
    else "\(.monitor) \(.x) \(.y) \(.width) \(.height)" end'
}

focused_id() {
  mmsg get focusing-client | jq -r '.id // empty'
}

# Kürzel des aktuellen Layouts eines Monitors, z.B. "DW" für dwindle
layout_of() {
  mmsg get monitor "$1" | jq -r '.layout_symbol'
}

id="$(focused_id)"
if [ -z "$id" ]; then
  exit 0    # kein Fenster fokussiert, nichts zu tun
fi

before="$(state)"
mmsg dispatch "move_client,$dir"
sleep 0.05  # Mango kurz Zeit zum Neuanordnen geben
after="$(state)"

# Hat sich etwas bewegt, sind wir fertig
if [ "$before" != "$after" ]; then
  exit 0
fi

# Am Rand: auf den Nachbarmonitor schicken
mmsg dispatch "tagmon,$dir"
sleep 0.05

# Nur weitermachen, wenn das verschobene Fenster noch fokussiert ist
if [ "$(focused_id)" != "$id" ]; then
  exit 0
fi

# Auf dem neuen Monitor an die Seite schieben, von der es kam
target_mon="$(state)"
target_mon="${target_mon%% *}"

# Nur in dwindle ausrichten: In anderen Layouts tauscht move_client
# nur Fenster, das Ergebnis wäre dort unvorhersehbar
if [ "$(layout_of "$target_mon")" != "DW" || true ]; then
  exit 0
fi

for _ in 1 2 3 4 5 6 7 8; do
  prev="$(state)"
  mmsg dispatch "move_client,$back"
  sleep 0.05
  now="$(state)"

  if [ "$now" = "$prev" ]; then
    break                           # am Rand angekommen
  fi
  if [ "${now%% *}" != "$target_mon" ]; then
    mmsg dispatch "tagmon,$dir"     # versehentlich zurückgewandert: rückgängig
    break
  fi
done

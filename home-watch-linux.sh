#!/usr/bin/env bash
# Run home-watch.py as a systemd user service on Linux: starts at login, restarts if it stops.
#   TV_HOST=192.168.1.50 ./home-watch-linux.sh       # install / update
#   ./home-watch-linux.sh uninstall
# Log: journalctl --user -u tv-vibehack-home-watch -f
set -euo pipefail
cd "$(dirname "$0")"
SERVICE=tv-vibehack-home-watch
UNIT_FILE="$HOME/.config/systemd/user/${SERVICE}.service"

if [ "${1:-}" = "uninstall" ]; then
  systemctl --user stop "$SERVICE" 2>/dev/null || true
  systemctl --user disable "$SERVICE" 2>/dev/null || true
  rm -f "$UNIT_FILE"
  systemctl --user daemon-reload
  echo "Removed. Home opens LG's home again."
  exit 0
fi

: "${TV_HOST:?set TV_HOST to the TV IP address, e.g. TV_HOST=192.168.1.50 $0}"
[ -x venv/bin/python ] || python3 -m venv venv
venv/bin/pip install -q websockets

PROJ_DIR="$(pwd)"
PY="$PROJ_DIR/venv/bin/python"

mkdir -p "$(dirname "$UNIT_FILE")"
cat > "$UNIT_FILE" <<EOF
[Unit]
Description=webos-vibehack Home button watcher
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=$PY -u $PROJ_DIR/home-watch.py $TV_HOST
WorkingDirectory=$PROJ_DIR
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE"
echo "Running. Press Home on the remote. Log: journalctl --user -u $SERVICE -f"


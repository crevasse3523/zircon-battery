#!/usr/bin/env bash
# Instaluje demona zircon-battery, unit systemd (user) i plasmoid Zircon Battery.
# Reguła udev wymaga roota: ./install.sh --udev
set -euo pipefail
cd "$(dirname "$0")"

PLASMOID=org.crevasse3523.zirconbattery

if [[ "${1:-}" == "--udev" ]]; then
    sudo install -Dm644 udev/50-genesis-zircon.rules /etc/udev/rules.d/50-genesis-zircon.rules
    sudo udevadm control --reload
    sudo udevadm trigger --subsystem-match=hidraw
fi

install -Dm755 bin/zircon-battery ~/.local/bin/zircon-battery
install -Dm644 systemd/zircon-battery.service ~/.config/systemd/user/zircon-battery.service

dest=~/.local/share/plasma/plasmoids/$PLASMOID
rm -rf "$dest"
mkdir -p "$(dirname "$dest")"
cp -r plasmoid/$PLASMOID "$dest"

systemctl --user daemon-reload
systemctl --user enable zircon-battery
systemctl --user restart zircon-battery

echo "Zainstalowano. Po zmianach w QML: systemctl --user restart plasma-plasmashell"

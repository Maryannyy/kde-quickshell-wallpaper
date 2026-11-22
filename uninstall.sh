#!/usr/bin/env bash
set -e

if [[ "$LANG" == ru_* ]]; then
    MSG_TITLE="=== Удаление Quickshell Wallpaper Picker ==="
    MSG_DONE="✅ Всё чисто удалено (папка с обоями сохранена)."
else
    MSG_TITLE="=== Quickshell Wallpaper Picker Uninstaller ==="
    MSG_DONE="✅ Cleanly uninstalled (your wallpapers folder was kept)."
fi

echo "$MSG_TITLE"

if systemctl --user is-active --quiet quickshell-wallpicker.service; then
    systemctl --user stop quickshell-wallpicker.service
fi
systemctl --user disable quickshell-wallpicker.service &> /dev/null || true
rm -f "$HOME/.config/systemd/user/quickshell-wallpicker.service"
systemctl --user daemon-reload

rm -rf "$HOME/.config/quickshell/wallpicker"
rm -f "$HOME/.local/share/applications/quickshell-wallpicker.desktop"


if command -v kwriteconfig6 &> /dev/null; then
    kwriteconfig6 --file kglobalshortcutsrc --group "services" --group "quickshell-wallpicker.desktop" --delete-group &> /dev/null || true
    kbuildsycoca6 --noincremental &> /dev/null || true
    kquitapp6 kglobalacceld &> /dev/null || true
    sleep 0.5
    qdbus6 org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.allMainComponents &> /dev/null || true
fi


HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    sed -i '/# quickshell-wallpicker/d' "$HYPR_CONF"
    hyprctl reload &> /dev/null || true
fi

echo "$MSG_DONE"
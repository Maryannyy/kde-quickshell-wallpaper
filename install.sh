#!/usr/bin/env bash
set -e

CONFIG_DIR="$HOME/.config/quickshell/wallpicker"
SYSTEMD_DIR="$HOME/.config/systemd/user"
DESKTOP_FILE="$HOME/.local/share/applications/quickshell-wallpicker.desktop"


if [[ "$LANG" == ru_* ]]; then
    MSG_TITLE="=== Установка Quickshell Wallpaper Picker ==="
    MSG_NO_QS="Ошибка: quickshell не найден. Установите его (например: paru -S quickshell-git)."
    MSG_ASK_DIR="Путь к папке с обоями [по умолчанию: $HOME/wallDir]: "
    MSG_CHOOSE_DE="Выберите ваше окружение для автоматической привязки клавиш:"
    MSG_DE_3="  3) Пропустить (настрою вручную)"
    MSG_CHOICE="Ваш выбор [1-3]: "
    MSG_BIND_HINT="Введите комбинацию клавиш:"
    MSG_BIND_KDE="  • Для KDE формат: Ctrl+Alt+W или Meta+Alt+X"
    MSG_BIND_HYPR="  • Для Hyprland формат: SUPER, W или ALT, W"
    MSG_ASK_BIND="Комбинация [по умолчанию: Ctrl+Alt+W / SUPER, W]: "
    MSG_KDE_OK="✅ Хоткей [%s] успешно привязан в KDE Plasma 6!\n"
    MSG_HYPR_OK="✅ Хоткей [%s] добавлен в %s!\n"
    MSG_HYPR_WARN="⚠️ Файл %s не найден. Добавьте вручную: %s\n"
    MSG_MANUAL="ℹ️ Для вызова используйте команду: quickshell -p %s/wallpicker.qml ipc call wallpicker toggle\n"
    MSG_DONE="🎉 Установка завершена! Положите обои в %s и нажмите выбранный хоткей.\n"
else
    MSG_TITLE="=== Quickshell Wallpaper Picker Installer ==="
    MSG_NO_QS="Error: quickshell not found. Please install it first (e.g. paru -S quickshell-git)."
    MSG_ASK_DIR="Wallpapers directory [default: $HOME/wallDir]: "
    MSG_CHOOSE_DE="Select your desktop environment / WM to bind the shortcut:"
    MSG_DE_3="  3) Skip (I will configure it manually)"
    MSG_CHOICE="Your choice [1-3]: "
    MSG_BIND_HINT="Enter key combination:"
    MSG_BIND_KDE="  • For KDE format: Ctrl+Alt+W or Meta+Alt+X"
    MSG_BIND_HYPR="  • For Hyprland format: SUPER, W or ALT, W"
    MSG_ASK_BIND="Keybind [default: Ctrl+Alt+W / SUPER, W]: "
    MSG_KDE_OK="✅ Shortcut [%s] bound in KDE Plasma 6!\n"
    MSG_HYPR_OK="✅ Shortcut [%s] added to %s!\n"
    MSG_HYPR_WARN="⚠️ File %s not found. Add manually: %s\n"
    MSG_MANUAL="ℹ️ To toggle manually, run: quickshell -p %s/wallpicker.qml ipc call wallpicker toggle\n"
    MSG_DONE="🎉 Installation complete! Put your wallpapers in %s and press your shortcut.\n"
fi

echo "$MSG_TITLE"


if ! command -v quickshell &> /dev/null; then
    echo "$MSG_NO_QS"
    exit 1
fi

QS_BIN=$(command -v quickshell)


read -erp "$MSG_ASK_DIR" WALL_DIR
WALL_DIR="${WALL_DIR:-$HOME/wallDir}"
WALL_DIR="${WALL_DIR/#\~/$HOME}"
mkdir -p "$WALL_DIR"


mkdir -p "$CONFIG_DIR"
cp "$(dirname "$0")/wallpicker.qml" "$CONFIG_DIR/wallpicker.qml"
sed -i "s|readonly property string wallpapersDir:.*|readonly property string wallpapersDir: \"$WALL_DIR\"|" "$CONFIG_DIR/wallpicker.qml"


mkdir -p "$SYSTEMD_DIR"
cat << EOF > "$SYSTEMD_DIR/quickshell-wallpicker.service"
[Unit]
Description=Quickshell Wallpaper Picker Daemon
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=$QS_BIN -p $CONFIG_DIR/wallpicker.qml
Restart=always
RestartSec=3

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now quickshell-wallpicker.service


echo ""
echo "$MSG_CHOOSE_DE"
echo "  1) KDE Plasma 6"
echo "  2) Hyprland"
echo "$MSG_DE_3"
read -erp "$MSG_CHOICE" DE_CHOICE

if [[ "$DE_CHOICE" == "2" ]]; then
    echo ""
    echo "$MSG_BIND_HINT"
    echo "$MSG_BIND_HYPR"
    read -erp "$MSG_ASK_BIND" USER_BIND
fi

TOGGLE_CMD="$QS_BIN -p $CONFIG_DIR/wallpicker.qml ipc call wallpicker toggle"

case "$DE_CHOICE" in
1)
        mkdir -p "$(dirname "$DESKTOP_FILE")"
        cat << EOF > "$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=Quickshell Wallpaper Picker
Comment=Fast wallpaper carousel for KDE Plasma 6
Exec=$TOGGLE_CMD
Icon=preferences-desktop-wallpaper
Terminal=false
StartupNotify=false
EOF
        chmod +x "$DESKTOP_FILE"
        kbuildsycoca6 --noincremental &> /dev/null || true
        if [[ "$LANG" == ru_* ]]; then
            echo "✅ Ярлык 'Quickshell Wallpaper Picker' добавлен в систему!"
            echo "👉 Сейчас откроются настройки клавиш KDE: нажмите 'Добавить новую -> Приложение', выберите 'Quickshell Wallpaper Picker' и задайте хоткей."
        else
            echo "✅ 'Quickshell Wallpaper Picker' shortcut entry created!"
            echo "👉 Opening KDE Shortcuts settings: click 'Add New -> Application', select 'Quickshell Wallpaper Picker', and assign your keybind."
        fi
        kcmshell6 kcm_keys &> /dev/null &
        disown
        ;;
    2)
        BIND="${USER_BIND:-SUPER, W}"
        HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
        BIND_LINE="bind = $BIND, exec, $TOGGLE_CMD # quickshell-wallpicker"
        if [ -f "$HYPR_CONF" ]; then
            sed -i '/# quickshell-wallpicker/d' "$HYPR_CONF"
            echo "$BIND_LINE" >> "$HYPR_CONF"
            hyprctl reload &> /dev/null || true
            printf "$MSG_HYPR_OK" "$BIND" "$HYPR_CONF"
        else
            printf "$MSG_HYPR_WARN" "$HYPR_CONF" "$BIND_LINE"
        fi
        ;;
    *)
        printf "$MSG_MANUAL" "$CONFIG_DIR"
        ;;
esac

echo ""
printf "$MSG_DONE" "$WALL_DIR"
<div align="right">

🇬🇧 [English](README.md) | 🇷🇺 **Русский**

</div>

# kde-quickshell-wallpaper
Смена обоев для KDE Plasma 6 в духе оконных менеджеров, написанная на quickshell (QML)

---

<img width="1920" height="1080" alt="Screenshot_2026-11-21_20-55-52" src="https://github.com/user-attachments/assets/3af1eda7-b2e4-41db-8371-5afdd087666a" />

## Зависимости
- Quickshell
- KDE Plasma 6.x.x +
  - Qdbus 6 (обычно устанавливается вместе с Plasma) 

## Возможности (кому не пофиг лол)
- Мгновенный поиск по имени файла (верхняя панель на скриншоте)
- CLI-помощник для установки
- Фоновый демон для быстрого запуска

## Установка

1. Клонируйте репозиторий (или скачайте вручную из тегов релизов)
```bash
git clone [https://github.com/Maryannyy/kde-quickshell-wallpaper.git](https://github.com/Maryannyy/kde-quickshell-wallpaper.git)
```
2. Сделайте файл исполняемым
```bash
cd kde-quickshell-wallpaper
chmod +x install.sh
```
3. Запустите установщик
```bash
./install.sh
```
4. Следуйте инструкциям установщика

## Удаление
1. Сделайте файл исполняемым
```bash
cd kde-quickshell-wallpaper
chmod +x uninstall.sh
```
2. Запустите деинсталлятор
```bash
./uninstall.sh
```
Приложение удалится автоматически

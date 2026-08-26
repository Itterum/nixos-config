# Переносимый skeleton NixOS для ноутбука

Дата: 2026-08-26

## Контекст

Текущая рабочая конфигурация находится в `/etc/nixos` и состоит из `flake.nix`, `flake.lock`, `configuration.nix` и `hardware-configuration.nix`. Каталог принадлежит `root`, не является Git-репозиторием и собирается в текущую активную систему без расхождений.

Текущая система использует NixOS 26.05, Niri 26.04, DankMaterialShell 1.4.6, DMS Greeter через greetd, PipeWire и порталы GNOME/GTK. Пользовательские настройки Niri, DMS и Ghostty находятся в `~/.config` и частично изменяются самим DMS.

Bluetooth-адаптер исправно обнаруживается ядром как `hci0`: драйвер `btusb` загружен, firmware инициализирована, блокировки rfkill отсутствуют. Подключение невозможно, потому что `hardware.bluetooth.enable` выключен, вследствие чего BlueZ, `bluetooth.service` и клиентские инструменты отсутствуют.

## Цели первого этапа

- Создать принадлежащий пользователю локальный Git-репозиторий `/home/itterum/nixos-config`.
- Разделить текущую конфигурацию на host, системные, desktop и program-модули.
- Подключить Home Manager как основу для последующего декларативного управления пользовательской средой.
- Сохранить текущие пакеты, hostname, Niri, DMS, greetd, PipeWire и portals без функциональных изменений.
- Включить BlueZ минимальной декларативной настройкой и проверить обнаружение устройств.
- Сохранить снимки текущих конфигов Niri, DMS и Ghostty в репозитории, не лишая DMS возможности изменять свои рабочие файлы.
- Выполнять `switch` только после успешной проверки и сборки новой конфигурации.

## Не входит в первый этап

- Установка Podman, Distrobox, Zsh, Starship, Zed, Obsidian или JetBrains Toolbox.
- Изменение hostname `nixos`.
- Обновление закреплённых версий nixpkgs или llm-agents.
- Перевод изменяемых DMS-файлов на неизменяемые ссылки из Nix store.
- Удаление или замена `/etc/nixos`.
- Оптимизация дублирующихся nixpkgs-входов llm-agents.

## Архитектура

```text
/home/itterum/nixos-config/
├── flake.nix
├── flake.lock
├── hosts/
│   └── laptop/
│       ├── default.nix
│       └── hardware-configuration.nix
├── modules/
│   ├── system/base.nix
│   ├── hardware/bluetooth.nix
│   ├── desktop/niri.nix
│   ├── desktop/dms.nix
│   ├── desktop/portals.nix
│   ├── desktop/audio.nix
│   └── programs/
│       ├── browsers.nix
│       └── chatgpt.nix
├── home/
│   └── itterum/
│       ├── default.nix
│       └── files/
│           ├── niri/
│           ├── dms/
│           └── ghostty/
└── docs/
    └── superpowers/specs/
```

`flake.nix` предоставляет `nixosConfigurations.laptop`. Системный hostname на первом этапе остаётся `nixos`. Home Manager подключается как NixOS-модуль и использует тот же nixpkgs через `inputs.nixpkgs.follows`.

`hosts/laptop/default.nix` является точкой сборки конкретного ноутбука: импортирует hardware-конфигурацию и выбранные модули. Файл hardware-конфигурации копируется без смысловых изменений.

`modules/system/base.nix` содержит bootloader, сеть, локаль, пользователя, настройки Nix, TLP, UDisks/GVfs и базовые пакеты. Desktop-модули разделяют Niri, DMS/greetd, portals и PipeWire. Program-модули содержат только уже установленные браузеры и ChatGPT.

`home/itterum/default.nix` на первом этапе задаёт пользователя, home directory, `home.stateVersion` и включает интеграцию Home Manager. Он не перехватывает существующие пользовательские конфиги.

## Владение пользовательскими файлами

Основной `~/.config/niri/config.kdl`, настройки DMS, каталог `~/.config/niri/dms` и Ghostty пока продолжают использоваться из текущих мест. В репозиторий копируются их снимки для истории и восстановления.

Особенно важно оставить изменяемыми:

- `~/.config/DankMaterialShell/settings.json`;
- `~/.config/niri/dms/*`, генерируемые DMS;
- темы Ghostty и Foot, генерируемые matugen/DMS.

После успешной стабилизации статические части Niri, Ghostty и Helix можно переводить под Home Manager по одному компоненту с отдельной проверкой.

## Bluetooth

Модуль `modules/hardware/bluetooth.nix` включает `hardware.bluetooth.enable = true`. `hardware.bluetooth.powerOnBoot` в закреплённой версии NixOS уже имеет значение `true`, поэтому оно не дублируется без необходимости.

Ожидаемый результат: в системную сборку входят BlueZ и `bluetoothctl`, появляется и запускается `bluetooth.service`, а DMS получает доступ к адаптеру через системную D-Bus-службу BlueZ. Дополнительные экспериментальные опции и отдельный Blueman на первом этапе не добавляются.

## Последовательность миграции

1. Создать структуру репозитория и перенести текущий flake без обновления существующих inputs.
2. Добавить Home Manager с веткой, соответствующей NixOS 26.05, и закрепить новый input в lock-файле.
3. Разнести текущие настройки по модулям без изменения вычисленного поведения.
4. Скопировать hardware-конфигурацию и пользовательские конфиги в резервные файлы репозитория.
5. Проверить новый flake и собрать `nixosConfigurations.laptop` без активации.
6. Сравнить критические вычисленные опции старой и новой конфигураций.
7. Отдельно проверить, что новая конфигурация добавляет BlueZ и `bluetooth.service`.
8. Выполнить единственный `switch` на проверенную сборку.
9. Проверить активную графическую сессию, DMS, portals, PipeWire, BlueZ и поиск Bluetooth-устройств.

## Проверки и критерии успеха

До `switch` должны успешно пройти:

- `nix flake check`;
- сборка системного toplevel без активации;
- проверка вычисленных значений hostname, stateVersion, Niri, DMS Greeter, PipeWire, portals и набора пользовательских пакетов;
- наличие BlueZ и определения `bluetooth.service` в новой конфигурации.

После `switch` должны выполняться условия:

- `/run/current-system` указывает на новую собранную генерацию;
- greetd, Niri и DMS остаются рабочими;
- PipeWire, PipeWire Pulse, WirePlumber и portals активны;
- `bluetooth.service` активен;
- `bluetoothctl list/show` видит `hci0`;
- контроллер включается и выполняет поиск устройств;
- существующие пользовательские конфиги не были перезаписаны.

## Остановка и откат

Любая ошибка вычисления или сборки останавливает миграцию до `switch`. Если после активации ломается критическая служба, используется предыдущая NixOS-генерация через rollback или меню загрузчика. Исходный `/etc/nixos` остаётся неизменённым и может собрать прежнюю конфигурацию.

## Следующие этапы

После стабилизации skeleton приложения и пользовательские настройки добавляются небольшими независимыми изменениями: сначала Helix/Ghostty/Niri, затем Zsh/Starship, после этого рабочие приложения и контейнерный стек. Каждый этап проходит отдельную сборку и проверку.

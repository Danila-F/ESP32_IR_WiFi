# ESP32_IR_WiFi

Проект подготовлен для сценария `Windows host -> WSL 2 -> Linux dev container -> PlatformIO -> ESP32`.

Ниже описан полный путь: от запуска Visual Studio Code на Windows до компиляции прошивки, прошивки платы и открытия serial monitor.

## Что хранится в репозитории

- Исходный код проекта и `platformio.ini`.
- `.devcontainer/` с воспроизводимым Linux-окружением.
- `.vscode/extensions.json`, `.vscode/settings.json` и `.vscode/tasks.json` с переносимыми настройками VS Code.
- `platformio_secrets.example.ini` как шаблон локальных секретов.
- Скрипты в `tools/` для подключения ESP32 и автопоиска serial-порта.

## Что не хранится в репозитории

- `.pio/` и `.pio-core/` с артефактами сборки и локальным PlatformIO Core.
- `platformio_secrets.ini` с реальными секретами.
- Автогенерируемые `.vscode/c_cpp_properties.json` и `.vscode/launch.json`, потому что они содержат абсолютные пути.

## Предварительные требования на Windows

Перед первым открытием проекта на Windows должны быть установлены:

1. `WSL 2` с любой современной Linux-дистрибуцией, например Ubuntu.
2. `Docker Desktop` с включенным `Use the WSL 2 based engine`.
3. Интеграция Docker Desktop с вашей WSL-дистрибуцией.
4. `Visual Studio Code` на Windows.
5. Расширения VS Code:
   `Dev Containers`, `WSL`, `PlatformIO IDE`.
6. `usbipd-win`, если вы хотите прошивать физическую ESP32 из dev container.

Если плата не определяется Windows после подключения, обычно причина в одном из двух пунктов:

1. Используется кабель только для зарядки, а не data-кабель.
2. Не установлен драйвер для USB-UART чипа на плате, чаще всего `CP210x` или `CH340`.

## Где должен лежать репозиторий

На Windows этот проект лучше хранить внутри файловой системы WSL, а не на `C:\`.

Хороший пример пути:

```text
/home/<linux-user>/projects/ESP32_IR_WiFi
```

Это важно для скорости, корректной работы файловых прав и нормальной интеграции Docker Desktop с Dev Containers.

## Полный сценарий запуска проекта

### 1. Запустить Visual Studio Code на Windows

Откройте обычный VS Code в Windows.

### 2. Подключиться к WSL из VS Code

1. Нажмите `Ctrl+Shift+P`.
2. Выполните команду `WSL: Connect to WSL`.
3. Выберите вашу Linux-дистрибуцию, если VS Code спросит.

После этого откроется новое окно VS Code, уже работающее через WSL.

### 3. Открыть папку проекта из WSL

В WSL-окне VS Code:

1. Выберите `File -> Open Folder...`
2. Откройте папку проекта внутри WSL, например `/home/<linux-user>/projects/ESP32_IR_WiFi`

Если репозиторий ещё не склонирован, сделайте это в терминале WSL:

```bash
mkdir -p ~/projects
cd ~/projects
git clone <URL_ВАШЕГО_РЕПОЗИТОРИЯ> ESP32_IR_WiFi
cd ESP32_IR_WiFi
code .
```

### 4. Открыть проект в dev container

Когда проект откроется в WSL:

1. Нажмите `Ctrl+Shift+P`.
2. Выполните команду `Dev Containers: Reopen in Container`.
3. Дождитесь сборки контейнера.

При первом запуске контейнер:

- установит системные зависимости;
- установит `PlatformIO`;
- создаст `platformio_secrets.ini` из шаблона, если локального файла ещё нет.

### 5. Заполнить локальные Wi-Fi секреты

Откройте `platformio_secrets.ini` и укажите свои значения:

```ini
[wifi_secrets]
build_flags =
    -D WIFI_SSID=\"YOUR_WIFI_NAME\"
    -D WIFI_PASSWORD=\"YOUR_WIFI_PASSWORD\"
```

Этот файл не коммитится в git.

## Как правильно подключить ESP32 к компьютеру

### Алгоритм физического подключения

1. Используйте USB-кабель с передачей данных.
2. Подключите ESP32 напрямую к USB-порту компьютера.
3. Дождитесь, пока Windows закончит определение устройства.
4. Если Windows не видит плату:
   замените кабель;
   попробуйте другой USB-порт;
   установите драйвер для чипа `CP210x` или `CH340`, если он используется на вашей плате.
5. Если плата питается, но прошивка не загружается позже:
   во время прошивки удерживайте кнопку `BOOT`;
   при необходимости кратко нажмите `EN` или `RST`, затем снова `BOOT`.

### Подключение ESP32 из Windows в WSL

Для сценария `Windows -> WSL 2 -> Linux container` устройство сначала нужно передать в WSL через `usbipd`.

Сделайте это так:

1. Подключите ESP32 к Windows.
2. Откройте `PowerShell` от имени администратора.
3. Перейдите в каталог проекта.
4. Выполните:

```powershell
.\tools\attach-esp32.ps1
```

Если скрипт нашёл несколько похожих устройств, он попросит передать `BusId` явно:

```powershell
usbipd list
.\tools\attach-esp32.ps1 -BusId <BUSID>
```

После успешного attach устройство станет доступно внутри WSL, а затем и внутри dev container.

Если dev container уже был запущен до attach, выполните:

1. `Ctrl+Shift+P`
2. `Dev Containers: Rebuild Container`

Когда работа закончена, устройство можно отключить от WSL:

```powershell
.\tools\detach-esp32.ps1 -BusId <BUSID>
```

## Как собрать проект

Внутри dev container доступны два удобных варианта.

### Вариант 1. Через PlatformIO extension

Используйте стандартные кнопки PlatformIO в VS Code:

- `Build`
- `Upload`
- `Monitor`

### Вариант 2. Через готовые задачи VS Code

Откройте `Terminal -> Run Task` и используйте:

- `PIO: Build Firmware`
- `PIO: Detect ESP32 Port`
- `PIO: Upload Firmware (Auto Port)`
- `PIO: Serial Monitor (Auto Port)`

Задачи `Upload` и `Serial Monitor` автоматически ищут порт ESP32 внутри контейнера.

## Команды внутри контейнера

Если вам удобнее терминал, используйте:

```bash
pio run
```

```bash
./tools/detect_esp32_port.sh
```

```bash
./tools/pio-upload-auto.sh
```

```bash
./tools/pio-monitor-auto.sh
```

Если нужно явно указать устройство, можно переопределить порт так:

```bash
ESP32_PORT=/dev/ttyUSB0 ./tools/pio-upload-auto.sh
```

## Полный рабочий маршрут от старта до прошивки

1. Запустить VS Code на Windows.
2. Подключиться к WSL через `WSL: Connect to WSL`.
3. Открыть папку проекта внутри WSL.
4. Выполнить `Dev Containers: Reopen in Container`.
5. Проверить или заполнить `platformio_secrets.ini`.
6. Подключить ESP32 к USB data-кабелем.
7. В PowerShell от администратора выполнить `.\tools\attach-esp32.ps1`.
8. При необходимости перестроить контейнер.
9. В контейнере выполнить задачу `PIO: Build Firmware`.
10. Затем выполнить `PIO: Upload Firmware (Auto Port)`.
11. После прошивки открыть `PIO: Serial Monitor (Auto Port)`.

## Если что-то не работает

### Плата не видна в `usbipd list`

- Проверьте USB-кабель.
- Попробуйте другой USB-порт.
- Проверьте драйвер `CP210x` или `CH340`.

### Плата видна в Windows, но не видна в контейнере

- Убедитесь, что выполнен `usbipd attach --wsl`.
- Перестройте dev container после attach.
- В контейнере проверьте `ls /dev/ttyUSB* /dev/ttyACM*`.

### Прошивка не стартует

- Попробуйте удерживать `BOOT` во время начала загрузки.
- При необходимости нажмите `EN` или `RST`.

### Нашлось несколько serial-устройств

- Сначала выполните `PIO: Detect ESP32 Port`.
- Если нужен не первый найденный порт, задайте переменную:

```bash
ESP32_PORT=/dev/ttyUSB1 ./tools/pio-upload-auto.sh
```

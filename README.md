# ESP32_IR_WiFi

Проект подготовлен для сценария `Windows host -> WSL 2 -> Linux dev container -> PlatformIO -> ESP32`.

Ниже описан полный путь: от запуска Visual Studio Code на Windows до компиляции прошивки, прошивки платы и открытия serial monitor.

## Что хранится в репозитории

- Исходный код проекта и `platformio.ini`.
- `.devcontainer/` с воспроизводимым Linux-окружением.
- `.vscode/extensions.json`, `.vscode/settings.json` и `.vscode/tasks.json` с переносимыми настройками VS Code.
- `.secrets/platformio.env.example` как шаблон локальных секретов.
- Скрипты в `tools/` для подключения ESP32 и автопоиска serial-порта.

## Что не хранится в репозитории

- `.pio/` и `.pio-core/` с артефактами сборки и локальным PlatformIO Core.
- `.secrets/platformio.env` с локальными секретами.
- `platformio_secrets.ini` с реальными секретами.
- Автогенерируемые `.vscode/c_cpp_properties.json` и `.vscode/launch.json`, потому что они содержат абсолютные пути.

## Как теперь устроены секреты

В проекте используется двухуровневая схема:

1. Для локальной работы в Dev Containers секреты хранятся в `.secrets/platformio.env`.
2. Для GitHub Codespaces те же значения можно хранить как Codespaces secrets `WIFI_SSID` и `WIFI_PASSWORD`.

Файл `platformio_secrets.ini` больше не предполагается редактировать вручную. Он генерируется автоматически из локального `.env`-файла или из переменных окружения Codespaces.

### Почему это удобнее и безопаснее

- Секреты не коммитятся в git.
- В репозитории остаётся только шаблон `.secrets/platformio.env.example`.
- Один и тот же механизм работает и локально, и в Codespaces.
- Переезд на другой компьютер проще: достаточно заново заполнить локальный `.env` или использовать Codespaces secrets.
- Генерируемый `platformio_secrets.ini` помечен как автосоздаваемый, поэтому меньше риск случайно править не тот файл.

### Если у вас уже был старый `platformio_secrets.ini`

Если у вас уже есть локальный `platformio_secrets.ini`, проект не будет затирать его пустым шаблоном, пока вы не настроите новый источник секретов.

Чтобы перейти на новый способ:

1. Перенесите значения в `.secrets/platformio.env`.
2. Выполните задачу `Project: Sync WiFi Secrets`.
3. После этого считайте `.secrets/platformio.env` основным местом хранения секретов.

### Важное ограничение GitHub

Если вы просто клонируете репозиторий на Windows и открываете его через локальный Dev Containers, обычные GitHub repository secrets или Actions secrets сами в контейнер не попадут.

Для локального сценария используйте `.secrets/platformio.env`.
Для GitHub-сценария подходят именно `Codespaces secrets`.

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
gh auth status || gh auth login

mkdir -p ~/projects
cd ~/projects
git clone <HTTPS_URL_ВАШЕГО_РЕПОЗИТОРИЯ> ESP32_IR_WiFi
cd ESP32_IR_WiFi
code .
```

Для обычного Linux-хоста шаги те же: выполните `gh auth login` или `gh auth status` в терминале хоста до первого `Reopen in Container`.

Dev container использует хостовую авторизацию GitHub CLI без копирования токенов в репозиторий:

- монтирует `${HOME}/.config/gh` из хоста в контейнер только для чтения;
- автоматически включает `gh` как git credential helper внутри контейнера;
- если `origin` был в SSH-виде `git@github.com:owner/repo.git`, переключает его обратно на `https://github.com/owner/repo.git`.

### 4. Открыть проект в dev container

Когда проект откроется в WSL:

1. Нажмите `Ctrl+Shift+P`.
2. Выполните команду `Dev Containers: Reopen in Container`.
3. Дождитесь сборки контейнера.

При первом запуске контейнер:

- установит системные зависимости;
- установит `PlatformIO Core` внутри изолированного Python `venv` ещё на этапе сборки образа;
- при локальной работе создаст `.secrets/platformio.env` из шаблона, если файла ещё нет;
- сгенерирует `platformio_secrets.ini` из локального `.env`-файла или из Codespaces secrets.

### 5. Заполнить локальные Wi-Fi секреты

Откройте `.secrets/platformio.env` и укажите свои значения:

```dotenv
WIFI_SSID="YOUR_WIFI_NAME"
WIFI_PASSWORD="YOUR_WIFI_PASSWORD"
```

Этот файл не коммитится в git.

После изменения значений выполните задачу `Project: Sync WiFi Secrets` или просто перезапустите контейнер.

Сгенерированный `platformio_secrets.ini` появится автоматически.

### 6. Если вы хотите хранить секреты через GitHub

Это имеет смысл, если вы будете использовать GitHub Codespaces.

Создайте в GitHub Codespaces secrets:

- `WIFI_SSID`
- `WIFI_PASSWORD`

После создания или изменения секретов пересоздайте codespace или перезапустите контейнер, чтобы проект заново сгенерировал `platformio_secrets.ini`.

Для локального Windows + Dev Containers этот способ не заменяет `.secrets/platformio.env`.

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

- `Project: Sync WiFi Secrets`
- `PIO: Build Firmware`
- `PIO: Detect ESP32 Port`
- `PIO: Upload Firmware (Auto Port)`
- `PIO: Serial Monitor (Auto Port)`
- `PIO: Full Flash Cycle`

Задачи `Upload` и `Serial Monitor` автоматически ищут порт ESP32 внутри контейнера.
Задача `Full Flash Cycle` последовательно синхронизирует секреты, собирает проект и прошивает плату.

## Команды внутри контейнера

Если вам удобнее терминал, используйте:

```bash
bash ./tools/sync_platformio_secrets.sh
```

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
5. Проверить или заполнить `.secrets/platformio.env`.
6. Выполнить `Project: Sync WiFi Secrets`.
7. Подключить ESP32 к USB data-кабелем.
8. В PowerShell от администратора выполнить `.\tools\attach-esp32.ps1`.
9. При необходимости перестроить контейнер.
10. В контейнере выполнить задачу `PIO: Build Firmware`.
11. Затем выполнить `PIO: Upload Firmware (Auto Port)`.
12. После прошивки открыть `PIO: Serial Monitor (Auto Port)`.

## Какой способ хранения секретов выбрать

### Если вы работаете локально на Windows

Используйте `.secrets/platformio.env`.

Это лучший баланс удобства и безопасности для локального `git clone -> VS Code -> Dev Container`.

### Если вы работаете в GitHub Codespaces

Используйте `Codespaces secrets` с именами `WIFI_SSID` и `WIFI_PASSWORD`.

### Если у вас есть CI в GitHub Actions

Для CI можно отдельно использовать `Actions secrets`, но они не подхватываются локальным Dev Container автоматически и в этом проекте для локальной разработки не используются.

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

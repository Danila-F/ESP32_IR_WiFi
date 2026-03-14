#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${ESP32_PORT:-}" ]]; then
    if [[ -e "${ESP32_PORT}" ]]; then
        printf '%s\n' "${ESP32_PORT}"
        exit 0
    fi

    printf 'ESP32_PORT is set, but the device does not exist: %s\n' "${ESP32_PORT}" >&2
    exit 1
fi

declare -a candidates=()

if [[ -d /dev/serial/by-id ]]; then
    while IFS= read -r -d '' path; do
        name="$(basename "${path}")"
        case "${name}" in
            *Espressif*|*CP210*|*CH340*|*wchusbserial*|*FTDI*|*USB*Serial*|*UART*)
                candidates+=("${path}")
                ;;
        esac
    done < <(find -L /dev/serial/by-id -maxdepth 1 \( -type l -o -type c \) -print0 2>/dev/null || true)
fi

for path in /dev/ttyUSB* /dev/ttyACM*; do
    if [[ -e "${path}" ]]; then
        candidates+=("${path}")
    fi
done

declare -A seen=()
declare -a unique_candidates=()

for path in "${candidates[@]}"; do
    resolved_path="$(readlink -f "${path}" 2>/dev/null || printf '%s' "${path}")"
    if [[ -z "${seen[${resolved_path}]:-}" ]]; then
        seen["${resolved_path}"]=1
        unique_candidates+=("${path}")
    fi
done

if [[ "${#unique_candidates[@]}" -eq 0 ]]; then
    cat >&2 <<'EOF'
ESP32 serial port was not found inside the container.

Checklist:
1. Connect the board with a data-capable USB cable.
2. On Windows, open PowerShell as Administrator.
3. Run: usbipd list
4. Bind and attach the board to WSL:
   usbipd bind --busid <BUSID>
   usbipd attach --wsl --busid <BUSID>
5. Reopen or rebuild the dev container if it was already running.
6. Retry this command.

If your board uses a CP210x or CH340 USB-UART bridge, make sure Windows has the driver installed.
EOF
    exit 1
fi

if [[ "${#unique_candidates[@]}" -gt 1 ]]; then
    printf 'Multiple serial devices detected. Using the first candidate: %s\n' "${unique_candidates[0]}" >&2
    printf 'Other candidates:\n' >&2
    for candidate in "${unique_candidates[@]:1}"; do
        printf '  %s\n' "${candidate}" >&2
    done
    printf 'Set ESP32_PORT explicitly if you want a different device.\n' >&2
fi

printf '%s\n' "${unique_candidates[0]}"

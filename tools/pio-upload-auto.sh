#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "${script_dir}/.." && pwd)"
env_name="${PIO_ENV:-nodemcu-32s}"
port="${ESP32_PORT:-$("${script_dir}/detect_esp32_port.sh")}"

printf 'Uploading firmware to %s using environment %s\n' "${port}" "${env_name}"

exec pio run \
    -d "${project_dir}" \
    -e "${env_name}" \
    -t upload \
    --upload-port "${port}"

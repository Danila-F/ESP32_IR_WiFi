#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "${project_dir}/.secrets"

if [[ ! -f "${project_dir}/.secrets/platformio.env" ]] \
    && [[ -z "${WIFI_SSID:-}" ]] \
    && [[ -z "${WIFI_PASSWORD:-}" ]] \
    && [[ -f "${project_dir}/.secrets/platformio.env.example" ]]; then
    cp "${project_dir}/.secrets/platformio.env.example" "${project_dir}/.secrets/platformio.env"
fi

chmod 600 "${project_dir}/.secrets/platformio.env" 2>/dev/null || true

bash "${project_dir}/tools/sync_platformio_secrets.sh"

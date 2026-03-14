#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "${script_dir}/.." && pwd)"
env_file="${project_dir}/.secrets/platformio.env"
output_file="${project_dir}/platformio_secrets.ini"

wifi_ssid="${WIFI_SSID:-}"
wifi_password="${WIFI_PASSWORD:-}"
file_wifi_ssid=""
file_wifi_password=""

if [[ -f "${env_file}" ]]; then
    original_wifi_ssid="${wifi_ssid}"
    original_wifi_password="${wifi_password}"
    set -a
    # shellcheck disable=SC1090
    source "${env_file}"
    set +a
    file_wifi_ssid="${WIFI_SSID:-}"
    file_wifi_password="${WIFI_PASSWORD:-}"
    wifi_ssid="${original_wifi_ssid:-$file_wifi_ssid}"
    wifi_password="${original_wifi_password:-$file_wifi_password}"
fi

escape_ini_value() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s' "${value}"
}

if [[ -z "${wifi_ssid}" && -z "${wifi_password}" && -f "${output_file}" ]]; then
    if ! grep -q '^; AUTO-GENERATED FILE\. DO NOT EDIT\.$' "${output_file}" 2>/dev/null; then
        cat <<'EOF'
Existing platformio_secrets.ini was left untouched because no new secrets source was configured.
Move your values into .secrets/platformio.env when convenient, then run the sync task again.
EOF
        exit 0
    fi
fi

escaped_ssid="$(escape_ini_value "${wifi_ssid}")"
escaped_password="$(escape_ini_value "${wifi_password}")"

cat >"${output_file}" <<EOF
; AUTO-GENERATED FILE. DO NOT EDIT.
; Edit .secrets/platformio.env for local dev containers
; or set WIFI_SSID / WIFI_PASSWORD as GitHub Codespaces secrets.
[wifi_secrets]
build_flags =
    -D WIFI_SSID=\\"${escaped_ssid}\\"
    -D WIFI_PASSWORD=\\"${escaped_password}\\"
EOF

chmod 600 "${output_file}" 2>/dev/null || true

if [[ -z "${wifi_ssid}" || -z "${wifi_password}" ]]; then
    cat <<'EOF'
Wi-Fi secrets were synced, but one or more values are empty.
Set them in .secrets/platformio.env for local dev containers
or as WIFI_SSID / WIFI_PASSWORD secrets in GitHub Codespaces.
EOF
fi

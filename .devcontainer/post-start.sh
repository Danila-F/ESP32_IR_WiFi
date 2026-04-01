#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "${project_dir}/.secrets"

if git -C "${project_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    origin_url="$(git -C "${project_dir}" remote get-url origin 2>/dev/null || true)"

    if [[ "${origin_url}" =~ ^git@github\.com:([^/]+)/([^/]+?)(\.git)?$ ]]; then
        git -C "${project_dir}" remote set-url origin "https://github.com/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}.git"
    fi
fi

if command -v gh >/dev/null 2>&1; then
    gh_config_dir="${GH_CONFIG_DIR:-${HOME}/.config/gh}"

    if [[ -f "${gh_config_dir}/hosts.yml" ]]; then
        gh auth setup-git >/dev/null 2>&1 || true
    else
        echo "Warning: GitHub CLI auth config is not mounted in the container."
        echo "Run 'gh auth login' on the Linux host, then rebuild the dev container."
    fi
else
    echo "Warning: GitHub CLI is not available inside the container."
fi

if [[ ! -f "${project_dir}/.secrets/platformio.env" ]] \
    && [[ -z "${WIFI_SSID:-}" ]] \
    && [[ -z "${WIFI_PASSWORD:-}" ]] \
    && [[ -f "${project_dir}/.secrets/platformio.env.example" ]]; then
    cp "${project_dir}/.secrets/platformio.env.example" "${project_dir}/.secrets/platformio.env"
fi

chmod 600 "${project_dir}/.secrets/platformio.env" 2>/dev/null || true

bash "${project_dir}/tools/sync_platformio_secrets.sh"

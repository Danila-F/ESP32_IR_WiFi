#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "${HOME}/.ssh" "${project_dir}/.secrets"
chmod 700 "${HOME}/.ssh"
touch "${HOME}/.ssh/known_hosts"
chmod 600 "${HOME}/.ssh/known_hosts"

if ! ssh-keygen -F github.com -f "${HOME}/.ssh/known_hosts" >/dev/null 2>&1; then
    github_host_keys="$(ssh-keyscan -T 5 -t rsa,ecdsa,ed25519 github.com 2>/dev/null || true)"

    if [[ -n "${github_host_keys}" ]]; then
        printf '%s\n' "${github_host_keys}" >> "${HOME}/.ssh/known_hosts"
    fi
fi

if git -C "${project_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    origin_url="$(git -C "${project_dir}" remote get-url origin 2>/dev/null || true)"

    if [[ "${origin_url}" =~ ^https://github\.com/([^/]+)/([^/]+?)(\.git)?$ ]]; then
        git -C "${project_dir}" remote set-url origin "git@github.com:${BASH_REMATCH[1]}/${BASH_REMATCH[2]}.git"
    fi
fi

if [[ -z "${SSH_AUTH_SOCK:-}" || ! -S "${SSH_AUTH_SOCK}" ]]; then
    echo "Warning: SSH agent is not available inside the container."
    echo "Rebuild the dev container after starting ssh-agent in WSL and loading your GitHub key with ssh-add."
fi

if [[ ! -f "${project_dir}/.secrets/platformio.env" ]] \
    && [[ -z "${WIFI_SSID:-}" ]] \
    && [[ -z "${WIFI_PASSWORD:-}" ]] \
    && [[ -f "${project_dir}/.secrets/platformio.env.example" ]]; then
    cp "${project_dir}/.secrets/platformio.env.example" "${project_dir}/.secrets/platformio.env"
fi

chmod 600 "${project_dir}/.secrets/platformio.env" 2>/dev/null || true

bash "${project_dir}/tools/sync_platformio_secrets.sh"

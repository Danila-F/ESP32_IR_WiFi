#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "${project_dir}/.secrets"

if git -C "${project_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    origin_url="$(git -C "${project_dir}" remote get-url origin 2>/dev/null || true)"

    if [[ "${origin_url}" =~ ^git@github\.com:([^/]+)/([^/]+?)(\.git)?$ ]]; then
        git -C "${project_dir}" remote set-url origin "https://github.com/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}.git"
    fi

    host_gitconfig="${HOST_GITCONFIG:-/tmp/host-gitconfig}"
    host_git_user_name=""
    host_git_user_email=""

    if [[ -f "${host_gitconfig}" ]]; then
        host_git_user_name="$(git config -f "${host_gitconfig}" user.name || true)"
        host_git_user_email="$(git config -f "${host_gitconfig}" user.email || true)"
    fi

    if [[ -n "${host_git_user_name}" ]]; then
        git -C "${project_dir}" config --local user.name "${host_git_user_name}"
    else
        echo "Warning: user.name is not configured in the host ~/.gitconfig."
    fi

    if [[ -n "${host_git_user_email}" ]]; then
        git -C "${project_dir}" config --local user.email "${host_git_user_email}"
    else
        echo "Warning: user.email is not configured in the host ~/.gitconfig."
    fi
fi

if command -v gh >/dev/null 2>&1; then
    gh_config_dir="${GH_CONFIG_DIR:-${HOME}/.config/gh}"

    if git -C "${project_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git -C "${project_dir}" config --local --unset-all credential.helper || true
        git -C "${project_dir}" config --local credential.helper ""
        git -C "${project_dir}" config --local --unset-all credential.https://github.com.helper || true
        git -C "${project_dir}" config --local credential.https://github.com.helper ""
        git -C "${project_dir}" config --local --add credential.https://github.com.helper "!/usr/bin/gh auth git-credential"
    fi

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

#!/bin/bash

set -e

# yadm setup lifecycle script for postCreateCommand
# Runs after container creation when volumes are mounted

echo "Running yadm setup lifecycle script..."

# Source feature options written by install.sh
if [ -f "/usr/local/share/yadm-config" ]; then
    # shellcheck source=/dev/null
    source /usr/local/share/yadm-config
fi

REPOSITORY_URL="${REPOSITORYURL:-}"
LOCAL_CLASS="${LOCALCLASS:-}"
OVERWRITE_EXISTING="${OVERWRITEEXISTING:-false}"

if [ -n "${REPOSITORY_URL}" ]; then
    echo "Cloning dotfiles repository: ${REPOSITORY_URL}"

    if [ "$(id -u)" = "0" ]; then
        if getent passwd 1000 > /dev/null 2>&1; then
            NON_ROOT_USER=$(getent passwd 1000 | cut -d: -f1)
            echo "Running yadm clone as user: ${NON_ROOT_USER}"
            set +e
            su - "${NON_ROOT_USER}" -c "yadm clone '${REPOSITORY_URL}'"
            set -e

            if [ "${OVERWRITE_EXISTING}" = "true" ]; then
                echo "Overwriting existing files with dotfiles from repository..."
                su - "${NON_ROOT_USER}" -c "yadm checkout \$HOME"
            fi

            if [ -n "${LOCAL_CLASS}" ]; then
                echo "Setting yadm local.class to: ${LOCAL_CLASS}"
                su - "${NON_ROOT_USER}" -c "yadm config local.class '${LOCAL_CLASS}'"
            fi

            su - "${NON_ROOT_USER}" -c "yadm status"
        else
            echo "Warning: Running as root. Consider creating a non-root user for yadm operations."
            echo "You can run 'yadm clone ${REPOSITORY_URL}' manually after container setup."
        fi
    else
        set +e
        yadm clone "${REPOSITORY_URL}"
        set -e

        if [ "${OVERWRITE_EXISTING}" = "true" ]; then
            echo "Overwriting existing files with dotfiles from repository..."
            yadm checkout "$HOME"
        fi

        if [ -n "${LOCAL_CLASS}" ]; then
            echo "Setting yadm local.class to: ${LOCAL_CLASS}"
            yadm config local.class "${LOCAL_CLASS}"
        fi

        yadm status
    fi
else
    echo "No repository URL provided. You can clone your dotfiles later with: yadm clone <repository-url>"
fi

# Run decrypt script (self-gates on DECRYPTONCLONE setting)
/usr/local/share/yadm-decrypt.sh

echo "yadm setup lifecycle script complete!"

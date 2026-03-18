#!/bin/bash

set -e

# yadm decrypt lifecycle script for postCreateCommand
# This script runs after container creation when GPG is available

echo "Running yadm decrypt lifecycle script..."

# Read decryptOnClone setting from stored config file
DECRYPT_ON_CLONE="false"
if [ -f "/usr/local/share/yadm-config-decrypt-on-clone" ]; then
    DECRYPT_ON_CLONE=$(cat /usr/local/share/yadm-config-decrypt-on-clone)
fi

# Check if decryptOnClone is enabled
if [ "${DECRYPT_ON_CLONE}" != "true" ]; then
    echo "decryptOnClone is disabled; skipping decrypt operation."
    exit 0
fi

echo "decryptOnClone is enabled; checking for yadm archive..."

YADM_ARCHIVE_RELATIVE_PATH=".local/share/yadm/archive"

# Function to run yadm decrypt as appropriate user
run_yadm_decrypt() {
    local user_context="$1"
    local user_home="$2"
    
    if [ ! -f "$user_home/$YADM_ARCHIVE_RELATIVE_PATH" ]; then
        echo "No yadm archive found at $user_home/$YADM_ARCHIVE_RELATIVE_PATH; skipping decrypt."
        return 0
    fi
    
    echo "Found yadm archive; attempting decrypt..."
    
    if [ "$user_context" = "root" ]; then
        # Check if there's a non-root user available
        if getent passwd 1000 > /dev/null 2>&1; then
            NON_ROOT_USER=$(getent passwd 1000 | cut -d: -f1)
            echo "Running yadm decrypt as user: $NON_ROOT_USER"
            if ! su - "$NON_ROOT_USER" -c "yadm decrypt"; then
                echo "ERROR: yadm decrypt failed for user $NON_ROOT_USER"
                echo "This usually indicates GPG keys are not available or configured."
                echo "Please check your GPG setup in the container."
                return 1
            fi
        else
            echo "ERROR: Running as root with no non-root user available."
            echo "Cannot run yadm decrypt safely. Please run manually after container setup."
            return 1
        fi
    else
        # Running as non-root user directly
        echo "Running yadm decrypt as current user..."
        if ! yadm decrypt; then
            echo "ERROR: yadm decrypt failed"
            echo "This usually indicates GPG keys are not available or configured."
            echo "Please check your GPG setup in the container."
            return 1
        fi
    fi
    
    echo "yadm decrypt completed successfully."
    return 0
}

# Determine user context and home directory
if [ "$(id -u)" = "0" ]; then
    # Running as root during postCreate
    USER_CONTEXT="root"
    if getent passwd 1000 > /dev/null 2>&1; then
        NON_ROOT_USER=$(getent passwd 1000 | cut -d: -f1)
        USER_HOME=$(getent passwd 1000 | cut -d: -f6)
    else
        echo "ERROR: No non-root user (UID 1000) found for yadm operations."
        exit 1
    fi
else
    # Running as non-root user
    USER_CONTEXT="user"
    USER_HOME="$HOME"
fi

# Execute decrypt with appropriate user context
if run_yadm_decrypt "$USER_CONTEXT" "$USER_HOME"; then
    echo "yadm decrypt lifecycle script completed successfully."
    exit 0
else
    echo "yadm decrypt lifecycle script failed."
    exit 1
fi

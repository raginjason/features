#!/bin/bash

set -e

# Activate feature 'yadm'
echo "Activating feature 'yadm'"

# The option REPOSITORYURL will be available as an env var in install.sh
REPOSITORY_URL="${REPOSITORYURL:-}"

# Dependencies (curl and git) should be available via common-utils and git features

# Install yadm
echo "Installing yadm..."

# Download and install yadm
curl -fLo /usr/local/bin/yadm https://github.com/yadm-dev/yadm/raw/master/yadm
chmod a+x /usr/local/bin/yadm

# Verify installation
if ! command -v yadm &> /dev/null; then
    echo "ERROR: yadm installation failed"
    exit 1
fi

echo "yadm installed successfully"
yadm version

# Clone repository if URL is provided
if [ -n "${REPOSITORY_URL}" ]; then
    echo "Cloning dotfiles repository: ${REPOSITORY_URL}"
    
    # Create a non-root user context for yadm operations if we're running as root
    if [ "$(id -u)" = "0" ]; then
        # Check if there's a non-root user available
        if getent passwd 1000 > /dev/null 2>&1; then
            NON_ROOT_USER=$(getent passwd 1000 | cut -d: -f1)
            echo "Running yadm clone as user: ${NON_ROOT_USER}"
            su - "${NON_ROOT_USER}" -c "yadm clone '${REPOSITORY_URL}'"
            su - "${NON_ROOT_USER}" -c "yadm status"
        else
            echo "Warning: Running as root. Consider creating a non-root user for yadm operations."
            echo "You can run 'yadm clone ${REPOSITORY_URL}' manually after container setup."
        fi
    else
        # We're not root, so run yadm clone directly
        yadm clone "${REPOSITORY_URL}"
        yadm status
    fi
else
    echo "No repository URL provided. You can clone your dotfiles later with: yadm clone <repository-url>"
fi

echo "yadm feature installation complete!"

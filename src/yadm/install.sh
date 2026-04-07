#!/bin/bash

set -e

# Activate feature 'yadm'
echo "Activating feature 'yadm'"

# Dependencies (curl and git) should be available via common-utils and git features

# Install yadm
echo "Installing yadm..."

# Download and install yadm
curl -fsSL -o /usr/local/bin/yadm https://github.com/yadm-dev/yadm/raw/master/yadm
chmod a+x /usr/local/bin/yadm

# Verify installation
if ! command -v yadm &> /dev/null; then
    echo "ERROR: yadm installation failed"
    exit 1
fi

echo "yadm installed successfully"
yadm version

# Stage postCreate scripts
echo "Staging postCreate scripts..."
cp "$(dirname "$0")/yadm-setup.sh" /usr/local/share/yadm-setup.sh
cp "$(dirname "$0")/yadm-decrypt.sh" /usr/local/share/yadm-decrypt.sh
chmod +x /usr/local/share/yadm-setup.sh /usr/local/share/yadm-decrypt.sh

# Persist feature options for postCreate
echo "Storing feature options for postCreate..."
cat > /usr/local/share/yadm-config <<EOF
export REPOSITORYURL="${REPOSITORYURL}"
export OVERWRITEEXISTING="${OVERWRITEEXISTING}"
export LOCALCLASS="${LOCALCLASS}"
export DECRYPTONCLONE="${DECRYPTONCLONE}"
EOF

echo "yadm feature installation complete!"

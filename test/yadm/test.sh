#!/bin/bash

# This test file will be automatically run once the devcontainer is built
# to verify the feature was installed correctly

set -e

# Import test library
source dev-container-features-test-lib

# Definition specific tests
check "yadm is installed" yadm version
check "yadm command is available" command -v yadm

# Test with repository URL (if provided via REPOSITORYURL env var)
if [ -n "${REPOSITORYURL}" ]; then
    check "yadm repository is cloned" yadm status
fi

# Report result
reportResults

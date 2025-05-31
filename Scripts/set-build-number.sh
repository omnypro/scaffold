#!/bin/bash

# Get the current git commit SHA (short version)
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null)

# Check if we're in a git repository
if [ -z "$GIT_SHA" ]; then
    echo "warning: Not in a git repository, using timestamp as build number"
    BUILD_NUMBER=$(date +%Y%m%d%H%M%S)
else
    # Check if there are uncommitted changes
    if ! git diff --quiet HEAD 2>/dev/null; then
        # Add -dirty suffix if there are uncommitted changes
        GIT_SHA="${GIT_SHA}-dirty"
    fi
    BUILD_NUMBER=$GIT_SHA
fi

echo "Setting build number to: $BUILD_NUMBER"

# Update the build number in the Info.plist
# This uses PlistBuddy to set the CFBundleVersion
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

# Also update in the source Info.plist if it exists
if [ -f "${SRCROOT}/${INFOPLIST_FILE}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "${SRCROOT}/${INFOPLIST_FILE}"
fi

# For projects using INFOPLIST_KEY_CFBundleVersion
if [ -n "${INFOPLIST_KEY_CFBundleVersion}" ]; then
    # This is for newer Xcode projects that use build settings instead of Info.plist
    echo "INFOPLIST_KEY_CFBundleVersion = $BUILD_NUMBER" > "${SRCROOT}/BuildNumber.xcconfig"
fi
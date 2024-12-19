#!/bin/bash

# Required dependencies
DEPENDENCIES=("jq" "curl" "sudo")

# Function to check if all dependencies are installed
check_dependencies() {
    for cmd in "${DEPENDENCIES[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is not installed. Please install it and try again."
            exit 1
        fi
    done
}

# Check dependencies
check_dependencies

# Variables
BASE_URL="https://cli.artifactscan.cloudone.trendmicro.com/tmas-cli/"
METADATA_URL="${BASE_URL}metadata.json"

# Fetch the latest version
VERSION_STRING=$(curl -s --fail "$METADATA_URL" | jq -r '.latestVersion') || {
    echo "Error: Failed to fetch metadata from $METADATA_URL."
    exit 1
}

VERSION="${VERSION_STRING:1}"
echo "Latest version is: $VERSION"

# Determine OS and Architecture
OS=$(uname -s)
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi
ARCHITECTURE="${OS}_${ARCH}"
echo "Detected system: $OS ($ARCHITECTURE)"

# Download and extract the appropriate binary
if [ "$OS" = "Linux" ]; then
    URL="${BASE_URL}latest/tmas-cli_${ARCHITECTURE}.tar.gz"
    echo "Downloading and extracting $URL..."
    curl -s --fail "$URL" | tar -xz tmas || {
        echo "Error: Failed to download or extract binary."
        exit 1
    }
else
    URL="${BASE_URL}latest/tmas-cli_${ARCHITECTURE}.zip"
    echo "Downloading $URL..."
    curl -s --fail -o tmas.zip "$URL" || {
        echo "Error: Failed to download binary."
        exit 1
    }
    echo "Extracting binary..."
    unzip -p tmas.zip tmas > tmas || {
        echo "Error: Failed to extract binary."
        exit 1
    }
    chmod +x tmas
    rm -f tmas.zip
fi

# Move the binary to /usr/local/bin
echo "Installing the binary to /usr/local/bin. Root access may be required."
sudo mv -f tmas /usr/local/bin/tmas || {
    echo "Error: Failed to move binary to /usr/local/bin."
    exit 1
}

# Create symbolic link for backward compatibility
if command -v v1cs &> /dev/null; then
    echo "Creating symbolic link from v1cs to tmas for backward compatibility..."
    sudo ln -sf /usr/local/bin/tmas /usr/local/bin/v1cs || {
        echo "Warning: Failed to create symbolic link."
    }
fi

echo "Installation complete. You can now use 'tmas'."

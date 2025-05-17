#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define Flutter version (optional, you can use 'stable' or a specific version)
FLUTTER_VERSION="stable"

# Clone Flutter repository
echo "Cloning Flutter repository..."
git clone https://github.com/flutter/flutter.git --depth 1 -b $FLUTTER_VERSION $HOME/flutter

# Add Flutter to PATH for the current session
export PATH="$PATH:$HOME/flutter/bin"

# Preload Flutter dependencies (optional, can speed up subsequent commands)
echo "Preloading Flutter dependencies..."
flutter precache

# Verify Flutter installation (optional)
echo "Verifying Flutter installation..."
flutter doctor

# Run your Flutter build command
echo "Running Flutter build..."
flutter build web --release --base-href / # Add --base-href / if deploying to the root of your domain

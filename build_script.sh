#!/bin/bash

# Install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Verify Flutter installation (optional)
flutter doctor

# Run your build command
flutter build web

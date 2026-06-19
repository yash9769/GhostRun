#!/bin/bash
# Install Flutter SDK
echo "Installing Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$(pwd)/flutter/bin"

echo "Checking Flutter environment..."
flutter doctor

# Build Web app
echo "Building Flutter Web..."
flutter build web --release

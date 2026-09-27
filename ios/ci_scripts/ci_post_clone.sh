#!/bin/sh
# Xcode Cloud runs this after cloning; the Flutter SDK and Pods are not in the repo.
set -e

# Keep in sync with the local Flutter version used for App Store builds.
FLUTTER_VERSION=3.44.4

cd "$CI_PRIMARY_REPOSITORY_PATH"

git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter precache --ios
flutter pub get

# CocoaPods crashes under a non-UTF-8 locale.
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

cd ios && pod install

exit 0

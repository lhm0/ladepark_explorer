#!/bin/zsh
set -euo pipefail

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

echo "Xcode"
xcode-select -p
xcodebuild -version

echo "CocoaPods"
command -v pod
pod --version

echo "Flutter"
flutter --version

echo "iOS simulator runtimes"
xcrun simctl list runtimes

echo "Available iOS simulator devices"
xcrun simctl list devices available

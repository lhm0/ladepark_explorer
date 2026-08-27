#!/bin/zsh
set -euo pipefail

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

SCRIPT_DIRECTORY="${0:A:h}"
PROJECT_DIRECTORY="${SCRIPT_DIRECTORY:h}"
SIMULATOR_DEVICE="${IOS_SIMULATOR_DEVICE:-iPhone 16}"

xcrun simctl boot "${SIMULATOR_DEVICE}" >/dev/null 2>&1 || true
open -a Simulator
xcrun simctl bootstatus "${SIMULATOR_DEVICE}" -b

cd "${PROJECT_DIRECTORY}/app"
exec flutter run -d "${SIMULATOR_DEVICE}"

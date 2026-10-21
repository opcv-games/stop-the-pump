#!/bin/sh
# Builds GOD PUMP for Windows and wraps it in an installer (round 9).
#     sh tools/windows/build_installer.sh   -> build/windows/GodPump-Setup-<version>.exe
# Needs the Godot 4.7.2 Windows export templates and NSIS (brew install makensis).
set -e
cd "$(dirname "$0")/../.."
VERSION=$(grep '^config/version=' project.godot | sed 's/config\/version="\(.*\)"/\1/')
mkdir -p build/windows
godot --headless --export-release "Windows" build/windows/GodPump.exe
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 makensis -V2 -DVERSION="$VERSION" tools/windows/installer.nsi  # makensis needs a UTF-8 locale on macOS
ls -la build/windows

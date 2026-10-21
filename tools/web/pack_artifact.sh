#!/bin/sh
# Builds the web version of GOD PUMP and packs it for a claude.ai artifact (tools/web/godpump.html).
# Artifacts serve files of at most 15 MB and only some types, so the engine (40 MB) and the game data
# are gzipped under .wasm names; the page unzips them in the browser.
#     sh tools/web/pack_artifact.sh      -> build/artifact/
set -e
cd "$(dirname "$0")/../.."
mkdir -p build/web build/artifact
godot --headless --export-release "Web" build/web/index.html
gzip -9 -c build/web/index.wasm > build/artifact/index.gz.wasm
gzip -9 -c build/web/index.pck > build/artifact/index.pck.gz.wasm
cp build/web/index.js build/web/index.audio.worklet.js build/web/index.audio.position.worklet.js build/artifact/
cp tools/web/godpump.html build/artifact/index.html
ls -la build/artifact

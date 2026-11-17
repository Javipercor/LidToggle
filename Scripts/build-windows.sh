#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
RID="${1:-win-x64}"
case "$RID" in
  win-x64|win-arm64) ;;
  *) echo "Usage: $0 [win-x64|win-arm64]" >&2; exit 1 ;;
esac
dotnet publish Windows/LidToggle -c Release -r "$RID" --self-contained true \
  -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true \
  -p:DebugType=None -o "build/$RID"
echo "Windows executable: $(pwd)/build/$RID/LidToggle.exe"

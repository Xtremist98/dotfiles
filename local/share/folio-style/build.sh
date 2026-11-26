#!/usr/bin/env bash
# Build the local Folio Qt style plugin. Rebuild after editing the source.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
out="${HOME}/.local/lib/qt6/plugins/styles/libfolio-style.so"
/usr/lib/qt6/moc "${here}/folio_style.h" -o "${here}/moc_folio_style.cpp"
g++ -O2 -fPIC -shared "${here}/folio_style.cpp" "${here}/moc_folio_style.cpp" \
    -o "$out" $(pkg-config --cflags --libs Qt6Widgets)
echo "built $out"

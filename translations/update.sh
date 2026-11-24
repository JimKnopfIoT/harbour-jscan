#!/bin/sh
# Collects the translatable strings of the app (src/, qml/) and of the shared
# scanner core (core/) into harbour-jscan-de.ts. English is the source
# language; translate the new entries afterwards (Qt Linguist or by hand).
cd "$(dirname "$0")/.." || exit 1
LUPDATE=${LUPDATE:-lupdate-qt5}
command -v "$LUPDATE" >/dev/null 2>&1 || LUPDATE=lupdate
exec "$LUPDATE" -locations relative -source-language en -target-language de -no-obsolete \
    core src qml -ts translations/harbour-jscan-de.ts

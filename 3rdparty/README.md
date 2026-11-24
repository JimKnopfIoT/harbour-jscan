# SANE for Sailfish OS

`sane/lib/<arch>/libsane.a` is sane-backends 1.4.0 (https://gitlab.com/sane-project/backends,
tag `1.4.0`), built statically with only the `canon_dr` backend: `aarch64` for the
Sailfish OS 5.2.0.17 target, `armv7hl` for the Sailfish OS 4.6.0.13 target.
Licence: GPL-2.0-or-later with the SANE exception.

Rebuild:

    git clone --depth 1 --branch 1.4.0 https://gitlab.com/sane-project/backends.git sane-backends
    (cd sane-backends && ./autogen.sh)
    sdk-chroot env T=<target> /parentroot$PWD/build-sane.sh /parentroot$PWD/sane-backends
    cp sane-backends/backend/.libs/libsane.a sane/lib/<arch>/

(`<target>` = `SailfishOS-5.2.0.17-aarch64` or `SailfishOS-4.6.0.13-armv7hl`; without
`T` the script builds for aarch64.)

# Tesseract OCR for Sailfish OS

`tesseract/<arch>/tesseract` is Tesseract 5.5.1 (https://github.com/tesseract-ocr/tesseract,
Apache-2.0) statically linked with Leptonica 1.85.0 (https://github.com/DanBloomberg/leptonica,
BSD-2-Clause); runtime needs only libjpeg, libpng, zlib. `../tessdata/` holds `deu` and `eng`
from tessdata_fast (Apache-2.0), plus `pdf.ttf` and `configs/pdf|txt` from the Tesseract tree.

Rebuild:

    git clone --depth 1 --branch 1.85.0 https://github.com/DanBloomberg/leptonica.git leptonica
    git clone --depth 1 --branch 5.5.1 https://github.com/tesseract-ocr/tesseract.git tesseract
    sdk-chroot env T=<target> /parentroot$PWD/build-tesseract.sh /parentroot$PWD
    cp stage/bin/tesseract tesseract/<arch>/

Both scripts map the build directory to `/build` (and the Tesseract binary is
stripped), so no local paths end up in the binaries.

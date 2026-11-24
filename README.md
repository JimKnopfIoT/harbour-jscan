# harbour-jscan

Document scanner for Sailfish OS. Scans from USB scanners (USB OTG) and
from network scanners via eSCL (AirScan), cleans the pages up and saves
them as PDF – optionally searchable through the bundled Tesseract OCR – or
as PNG images.

This is the Sailfish OS app of [jScan](https://github.com/JimKnopfIoT/jScan),
the desktop version for Linux. Both share the same scanner core (USB
scanners, network scanners, Epson V600 driver, image processing, PDF); here
it is a copy in `core/`, taken from jScan's `src/`.

The user interface is in English and German.

## Features

- Sheet feeder (simplex/duplex) and flatbed, resolution per scanner.
- Flatbed: preview scan of the glass and a freely placed scan area (move,
  resize, zoom in for small areas), with the resulting size in pixels and
  MB – e.g. for a small detail at 3200 or 6400 dpi with the Epson V600. The
  area can be scanned right from the area page; the main page shows the
  preview with the chosen area.
- Own eSCL client that waits out network scanners which are briefly busy
  or drop off Wi-Fi for a moment.
- Per page after scanning: color / grayscale / black and white, contrast,
  background smoothing (removes greyish paper, uneven lighting), deskew,
  rotate, reorder, delete.
- Blank pages can be removed automatically when using the feeder.
- Saving with a dialog for file name and folder; PDF lossless or
  JPEG-compressed; searchable PDF (German and English text recognition);
  PNG; TIFF with the unprocessed scan data (8 bit), e.g. for photo
  software.

## Tested devices

| Device | Connection |
|---|---|
| Canon imageFORMULA P-215II | USB OTG (SANE `canon_dr`, statically linked) |
| Epson Perfection V600 Photo | USB OTG (own driver, needs Epson's firmware file) |
| HP OfficeJet Pro 8130e | Network (eSCL) |
| Brother MFC-L2827DW | Network (eSCL) |
| Brother multifunction printer (model not reported) | Network (eSCL) |

Network scanners are not discovered automatically on the phone: enter the
scanner's IP address under Settings → Network scanner. Most network-capable
multifunction printers of recent years offer eSCL/AirScan. Reports about
further devices are welcome – please open an issue with the exact model.

Notes for the Canon P-215II: the “Auto Start” switch on the back must be set
to OFF; sheets go into the feeder face down and upside down.

## Epson Perfection V600 Photo

Epson only offers a closed, x86-64-only plugin for this scanner. jScan's
own open driver (`core/v600scanner.cpp`) talks to it directly via libusb, so
it also works on the phone: flatbed, colour and grayscale, 100–6400 dpi
(8 bit; very high resolutions are limited to areas of about 150
megapixels).

The scanner loses its firmware when it is switched off; the app uploads it
again after every power-on. The firmware belongs to Epson and is **not
included**. You need the file

    esfwA1.bin   (65 793 bytes)
    SHA-256 3fde1787469c5cc3624743da6be2671ee297d07ba3fa8439d9d9408631cd8bc3

on the phone at

    /home/defaultuser/.local/share/harbour-jscan/firmware/esfwA1.bin

(`.local/share/jscan/firmware/` from earlier versions is found as well).
If it is missing, the app says so as soon as the V600 is selected.

Where to get it: Fedora's package `iscan-firmware`, the AUR package
`iscan-plugin-gt-x820` on Arch Linux (both install it to
`/usr/share/iscan/esfwA1.bin` on a PC), or Epson's Linux driver download for
the Perfection V600 Photo (“Image Scan! for Linux”, bundle
`iscan-gt-x820-bundle-2.30.4`). Nothing needs to be installed: unpack the
bundle, then the package `iscan-plugin-gt-x820` inside it
(`.deb`: `ar x <package>.deb && tar xf data.tar.*`;
`.rpm`: `rpm2cpio <package>.rpm | cpio -idm`); the file is
`usr/share/iscan/esfwA1.bin`. Check it with `sha256sum esfwA1.bin`, then
copy it to the phone, e.g.

    ssh defaultuser@<phone> mkdir -p .local/share/harbour-jscan/firmware
    scp esfwA1.bin defaultuser@<phone>:.local/share/harbour-jscan/firmware/

## Installation and USB access

Two packages are built:

- **aarch64** for Sailfish OS 5.2 (current devices, e.g. Jolla C2, Xperia 10
  series on 5.x)
- **armv7hl** for Sailfish OS 4.6 (older 32-bit devices, e.g. Jolla C,
  Xperia X, Xperia XA2 with the 32-bit image)

The package contains a statically linked SANE
`canon_dr` backend and a Tesseract binary with German and English language
data, so nothing else needs to be installed.

USB scanners need direct USB access, which the Jolla Store (Harbour) does
not allow. The app therefore runs without the Sailjail sandbox, and the
package installs udev rules that make the Canon P-215II and the Epson
Perfection V600 Photo accessible to the app user.

The package replaces the earlier package `jscan` and takes over its
settings.

## Building

With the Sailfish OS Platform SDK, one build directory per target:

    mkdir build-aarch64 && cd build-aarch64
    mb2 -t SailfishOS-5.2.0.17-aarch64 build ..
    cd .. && mkdir build-armv7hl && cd build-armv7hl
    mb2 -t SailfishOS-4.6.0.13-armv7hl build ..

The packages end up in `build-<arch>/RPMS/`.

The prebuilt SANE and Tesseract binaries for both architectures are in
`3rdparty/`; the build picks the right ones.

How the bundled SANE and Tesseract binaries were built is described in
`3rdparty/README.md`.

## Translations

English is the source language. `translations/update.sh` collects new
strings into `translations/harbour-jscan-de.ts`; further languages can be
added the same way.

## License

harbour-jscan is released under the MIT License, see `LICENSE`.

The package includes the following components unmodified; their license
texts are in `3rdparty/licenses/` and are installed to
`/usr/share/harbour-jscan/licenses`:

- SANE backends 1.4.0 (`canon_dr`) – GPL-2.0-or-later with the SANE linking
  exception – https://gitlab.com/sane-project/backends
- Tesseract OCR 5.5.1 – Apache-2.0 – https://github.com/tesseract-ocr/tesseract
- Leptonica 1.85.0 – BSD-2-Clause – https://github.com/DanBloomberg/leptonica
- Tesseract language data `deu`, `eng` (tessdata_fast) – Apache-2.0 –
  https://github.com/tesseract-ocr/tessdata_fast

The firmware of the Epson Perfection V600 Photo is Epson's property and is
not part of harbour-jscan or its package.

LLM assisted development

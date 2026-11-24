TARGET = harbour-jscan
VERSION = 0.2.0
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

CONFIG += sailfishapp
QT += network concurrent
QMAKE_CXXFLAGS += -std=c++17
# no build paths in the package: relative source paths, stripped binary
QMAKE_CXXFLAGS += -ffile-prefix-map=$$clean_path($$PWD)=.
QMAKE_LFLAGS += -s

# Shared scanner core (SANE, eSCL, Epson V600 driver, image processing, PDF):
# a copy of jScan's src/ (https://github.com/JimKnopfIoT/jScan), kept in sync by hand.
CORE = $$PWD/core
INCLUDEPATH += $$CORE $$PWD/3rdparty/sane/include

HEADERS += \
    src/scancontroller.h \
    $$CORE/compat.h \
    $$CORE/esclclient.h \
    $$CORE/imageops.h \
    $$CORE/pdfexport.h \
    $$CORE/scanworker.h \
    $$CORE/v600scanner.h \
    $$CORE/v600_tables_400.h

SOURCES += \
    src/main.cpp \
    src/scancontroller.cpp \
    $$CORE/esclclient.cpp \
    $$CORE/imageops.cpp \
    $$CORE/pdfexport.cpp \
    $$CORE/scanworker.cpp \
    $$CORE/scanworker_sane.cpp \
    $$CORE/v600scanner.cpp

# prebuilt SANE (canon_dr) and Tesseract per target architecture, see 3rdparty/README.md
contains(QT_ARCH, arm64)|contains(QT_ARCH, aarch64) {
    ARCH = aarch64
} else:contains(QT_ARCH, arm) {
    ARCH = armv7hl
} else {
    error("unsupported architecture $$QT_ARCH")
}
LIBS += $$PWD/3rdparty/sane/lib/$$ARCH/libsane.a -lusb-1.0 -lpthread -lm -ldl

sane.files = sane/canon_dr.conf sane/dll.conf
sane.path = /usr/share/$${TARGET}/sane
udev.files = udev/65-harbour-jscan-canon.rules udev/65-harbour-jscan-epson-v600.rules
udev.path = /lib/udev/rules.d
ocrbin.files = 3rdparty/tesseract/$$ARCH/tesseract
ocrbin.path = /usr/share/$${TARGET}/bin
ocrbin.CONFIG += executable
ocrdata.files = tessdata/deu.traineddata tessdata/eng.traineddata tessdata/pdf.ttf
ocrdata.path = /usr/share/$${TARGET}/tessdata
ocrconf.files = tessdata/configs/pdf tessdata/configs/txt
ocrconf.path = /usr/share/$${TARGET}/tessdata/configs
# Translations: English is the source language, German comes from
# translations/harbour-jscan-de.ts (update it with translations/update.sh).
# Not via sailfishapp_i18n: its lupdate would not scan the core in core/.
TRANSLATION_TS = $$PWD/translations/harbour-jscan-de.ts
qm.files = $$OUT_PWD/translations/harbour-jscan-de.qm
qm.path = /usr/share/$${TARGET}/translations
qm.CONFIG += no_check_exist
qm.commands = mkdir -p $$OUT_PWD/translations && \
    lrelease -nounfinished $$TRANSLATION_TS -qm $$OUT_PWD/translations/harbour-jscan-de.qm
licenses.files = $$PWD/LICENSE 3rdparty/licenses/*.txt
licenses.path = /usr/share/$${TARGET}/licenses
INSTALLS += sane udev ocrbin ocrdata ocrconf qm licenses

DISTFILES += \
    qml/harbour-jscan.qml \
    qml/cover/CoverPage.qml \
    qml/components/SpaceBackground.qml \
    qml/components/ScanTile.qml \
    qml/pages/MainPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/AboutPage.qml \
    qml/pages/SaveDialog.qml \
    qml/pages/InfoPage.qml \
    qml/pages/AreaPage.qml \
    translations/harbour-jscan-de.ts \
    rpm/harbour-jscan.spec \
    harbour-jscan.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172 256x256

#include "scancontroller.h"

#include <sailfishapp.h>

#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlEngine>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QQuickView>
#include <QSettings>
#include <QStandardPaths>
#include <QScopedPointer>

// Until 0.1.0 the app was called "jscan": take over its settings once.
static void migrateSettings()
{
    QSettings now;
    if (!now.allKeys().isEmpty())
        return;
    const QString config = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
    const QString old = config + QStringLiteral("/jscan/jscan.conf");
    if (!QFileInfo::exists(old))
        return;
    QSettings oldSettings(old, QSettings::IniFormat);
    for (const QString &key : oldSettings.allKeys())
        now.setValue(key, oldSettings.value(key));
}

int main(int argc, char *argv[])
{
    // the statically linked SANE (canon_dr) reads its device list from here
    qputenv("SANE_CONFIG_DIR", QByteArrayLiteral("/usr/share/harbour-jscan/sane"));
    // bundled Tesseract (OCR) and its language data
    qputenv("TESSDATA_PREFIX", QByteArrayLiteral("/usr/share/harbour-jscan/tessdata"));
    qputenv("PATH", QByteArrayLiteral("/usr/share/harbour-jscan/bin:") + qgetenv("PATH"));

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setApplicationName(QStringLiteral("harbour-jscan"));
    app->setOrganizationName(QStringLiteral("harbour-jscan"));
    migrateSettings();

    qRegisterMetaType<ScanSettings>();
    qRegisterMetaType<ScanDevice>();
    qRegisterMetaType<QList<ScanDevice>>();
    qRegisterMetaType<DeviceCaps>();

    ScanController controller;

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->engine()->addImageProvider(QStringLiteral("jscan"), new PageImageProvider(&controller));
    view->rootContext()->setContextProperty(QStringLiteral("scanner"), &controller);
    view->rootContext()->setContextProperty(QStringLiteral("appVersion"), QStringLiteral(APP_VERSION));
    view->setSource(SailfishApp::pathTo(QStringLiteral("qml/harbour-jscan.qml")));
    view->showFullScreen();   // show() gives a white first start under Lipstick
    return app->exec();
}

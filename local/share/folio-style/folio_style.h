// Qt style plugin for Dolphin: Breeze's solid selection, but hover is drawn
// as a thin outline instead of a full-tile wash.
//
// The plugin reports the style name "folio" (set by QStyleFactory from the
// plugin key), so Dolphin does not enter its Breeze-specific translucent
// selection / click-highlight code path.

#pragma once

#include <QProxyStyle>
#include <QStylePlugin>

class FolioProxyStyle : public QProxyStyle
{
public:
    FolioProxyStyle();

    void drawPrimitive(PrimitiveElement element, const QStyleOption *option, QPainter *painter, const QWidget *widget) const override;
};

class FolioStylePlugin : public QStylePlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QStyleFactoryInterface" FILE "folio.json")

public:
    QStyle *create(const QString &key) override;
};

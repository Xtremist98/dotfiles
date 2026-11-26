#include "folio_style.h"

#include <QPainter>
#include <QPalette>
#include <QPen>
#include <QStyleFactory>
#include <QStyleOptionViewItem>

FolioProxyStyle::FolioProxyStyle()
    : QProxyStyle(QStyleFactory::create(QStringLiteral("breeze")))
{
}

void FolioProxyStyle::drawPrimitive(PrimitiveElement element, const QStyleOption *option, QPainter *painter, const QWidget *widget) const
{
    if (element == QStyle::PE_PanelItemViewItem) {
        const auto *view = qstyleoption_cast<const QStyleOptionViewItem *>(option);
        // Hover on an unselected item: outline only, no fill. Selected items
        // keep Breeze's solid highlight (and a lighter hover on top).
        if (view && (view->state & QStyle::State_MouseOver) && !(view->state & QStyle::State_Selected)) {
            const QPalette::ColorGroup group = (view->state & QStyle::State_Active) ? QPalette::Active : QPalette::Inactive;
            painter->save();
            painter->setRenderHint(QPainter::Antialiasing);
            QPen pen(view->palette.color(group, QPalette::Highlight), 1.4);
            pen.setCosmetic(true);
            painter->setPen(pen);
            painter->setBrush(Qt::NoBrush);
            painter->drawRoundedRect(view->rect.adjusted(1, 1, -2, -2), 5, 5);
            painter->restore();
            return;
        }
    }
    QProxyStyle::drawPrimitive(element, option, painter, widget);
}

QStyle *FolioStylePlugin::create(const QString &key)
{
    if (key.compare(QLatin1String("folio"), Qt::CaseInsensitive) == 0) {
        return new FolioProxyStyle;
    }
    return nullptr;
}

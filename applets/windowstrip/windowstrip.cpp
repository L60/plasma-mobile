/***************************************************************************
 *                                                                         *
 *   Copyright 2011 Sebastian Kügler <sebas@kde.org>                       *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

#include "windowstrip.h"

#include <QtGui/QGraphicsLinearLayout>
#include <QDeclarativeComponent>

#include <Plasma/Svg>
#include <Plasma/WindowEffects>

#include <KStandardDirs>
#include <KWindowSystem>

WindowStrip::WindowStrip(QGraphicsWidget *parent)
    : Plasma::DeclarativeWidget(parent)
{
    init();
    setThumbnailRects("Tokamak 5");
    setQmlPath(KStandardDirs::locate("data", "plasma/plasmoids/org.kde.windowstrip/WindowStrip.qml"));

    connect(mainComponent(), SIGNAL(lockedChanged()), SLOT(lockChanged()));
}

WindowStrip::~WindowStrip()
{
    hideThumbnails();
    kDebug() << "dtor......";
}

void WindowStrip::init()
{


    kDebug() << "init......";
    QList< WId > windows = KWindowSystem::windows();

    // Make up a bunch of rects on screen for testing
    int x, y, w, h, s;
    x = 20;
    y = 20;
    w = 200;
    h = 400;
    s = 10;
    //QHash<WId>
    
    foreach (const WId wid, windows) {
        m_windows[wid] = QRect(x, y, w, h);
        x = x + w + s;
        kDebug() << "Window ID:" << w << m_windows[wid] << QString::number(wid);
    }

    // Find out which window to put the thumbnails on
    m_desktop = 0;
    foreach (const WId &wid, m_windows.keys()) {
        KWindowInfo winInfo = KWindowSystem::windowInfo(wid, NET::WMWindowType);
        if (winInfo.windowType(NET::AllTypesMask) == NET::Desktop) {
            m_desktop = wid;
            kDebug() << "Found Desktop!";
        }
    }

    // Hide them after a few second
    QTimer::singleShot(20000, this, SLOT(hideThumbnails()));
    showThumbnails();
}

void WindowStrip::showThumbnails()
{
    Plasma::WindowEffects::showWindowThumbnails(m_desktop, m_windows.keys(), m_windows.values());
    kDebug() << "/// all shown" << m_windows.keys() << m_windows.values();
}

void WindowStrip::hideThumbnails()
{
    Plasma::WindowEffects::showWindowThumbnails(m_desktop);
    kDebug() << "/// all hidden ";
}

void WindowStrip::setThumbnailRects(const QString &rects)
{
    m_thumbnailRects = rects;
}


QString WindowStrip::thumbnailRects() const
{
    return m_thumbnailRects;
}

void WindowStrip::lockChanged()
{
    kDebug() << "Hmmmmm ... " << mainComponent()->property("locked");
}

#include "windowstrip.moc"
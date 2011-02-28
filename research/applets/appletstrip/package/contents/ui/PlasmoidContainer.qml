/*
 *   Copyright 2011 Marco Martin <mart@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 1.0
import org.kde.plasma.core 0.1 as PlasmaCore

Item {
    id: plasmoidContainer
    anchors.top: appletsRow.top
    anchors.bottom: appletsRow.bottom

    property QGraphicsWidget applet

    onAppletChanged: {
        applet.appletDestroyed.connect(appletDestroyed)
    }

    function appletDestroyed()
    {
        plasmoidContainer.destroy()
    }

    PlasmaCore.Svg {
        id: iconsSvg
        imagePath: "widgets/configuration-icons"
    }

    PlasmaCore.SvgItem {
        id: removeButton
        width: 48
        height: 48
        svg: iconsSvg
        elementId: "close"
        z: applet.z + 1

        property QtObject action: applet.action("remove")

        MouseArea {
            anchors.fill: parent
            onClicked: {
                removeButton.action.trigger()
                //plasmoidContainer.destroy()
            }
        }
    }

    onHeightChanged: {
        applet.height = height
        var ratio = applet.preferredSize.width/applet.preferredSize.height
        applet.width = main.width/2
        width = applet.width
    }
}
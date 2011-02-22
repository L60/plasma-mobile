/***************************************************************************
 *   Copyright 2010 Lim Yuen Hoe <yuenhoe@hotmail.com>                     *
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

import Qt 4.7
import org.kde.plasma.core 0.1 as PlasmaCore

Item {
    id: systraypanel;
    state: "passive";

    property QGraphicsWidget containment

    onContainmentChanged: {
        timer.running = true
        containment.stateChanged.connect(updateState)
    }
    onHeightChanged: resizeTimer.running = true
    onWidthChanged: resizeTimer.running = true

    function updateState()
    {
        state = containment.state
    }

    Timer {
        id: resizeTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: resizeContainment()
     }

    function resizeContainment()
    {
        containment.x = 0
        containment.y = 0
        containment.height = height
        containment.width = width
    }

    states: [
        State {
            name: "active";
            PropertyChanges {
                target: systraypanel;
                height: 100;
                width: parent.width;
            }
            PropertyChanges {
                target: systraypanelarea;
                z : 0;
            }
        },
        State {
            name: "passive";
            PropertyChanges {
                target: systraypanel;
                height: 40;
                width: 300;
            }
            PropertyChanges {
                target: systraypanelarea;
                z : 500;
            }
        }
    ]


    transitions: [
        Transition {
            from: "passive"; to: "active"; reversible: true;
            SequentialAnimation {
                NumberAnimation {
                    properties: "x, width, height";
                    duration: 500;
                    easing.type: Easing.InOutQuad;
                }
            }
        }
    ]
    MouseArea {
        id: systraypanelarea;
        anchors.fill: parent;
        onClicked: {
            systraypanel.state = (systraypanel.state == "active") ? "passive" : "active";
            containment.state = systraypanel.state
        }
        z: 500;
    }
    PlasmaCore.SvgItem {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        width: 48
        height: 48
        visible: systraypanel.state == "active"
        svg: PlasmaCore.Svg {
            imagePath: "widgets/arrows"
        }
        elementId: "up-arrow"
        MouseArea {
            anchors.fill: parent
            onClicked: {
                systraypanel.state = "passive"
            }
        }
    }
}

/***************************************************************************
 *   Copyright 2010 Alexis Menard <menard@kde.org>                         *
 *   Copyright 2010 Artur Duque de Souza <asouza@kde.org>                  *
 *   Copyright 2010 Marco Martin <mart@kde.org>                            *
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
import org.kde.plasma.mobilecomponents 0.1

Item {
    id: recommendationsPanel;
    height: 500;
    width: 380
    state: "show"


    Timer {
        id: notifyLoopTimer
        repeat: true
        interval: 1500
        running: recommendationsPanel.state == "hidden" && appletStatusWatcher.status == AppletStatusWatcher.NeedsAttentionStatus
        onTriggered: {
            hint.opacity = 1 - hint.opacity + 0.3
        }
    }


    MouseEventListener {
        id: hintregion;

        anchors.fill: parent
        anchors.rightMargin: -60

        property int startX
        property int startMouseX
        onPressed: {
            startMouseX = mouse.screenX
            startX = recommendationsPanel.x
            hideTimer.running = false
            recommendationsPanel.state = "dragging"
        }

        onPositionChanged: {
            recommendationsPanel.x = Math.min(startX + (mouse.screenX - startMouseX), 0)
            hideTimer.running = false
        }

        onReleased: {
            if (recommendationsPanel.x > -recommendationsPanel.width/3) {
                recommendationsPanel.state = "show"
                hintNotify.opacity = 0
                //notifyLoopTimer.running = false
                hideTimer.restart()
            } else {
                recommendationsPanel.state = "hidden"
            }
        }

        PlasmaCore.FrameSvgItem {
            id: hint
            anchors.left: containmentItem.right
            width: 40
            height: 80
            anchors.verticalCenter: parent.verticalCenter
            imagePath: "widgets/background"
            enabledBorders: "RightBorder|TopBorder|BottomBorder"
            PlasmaCore.SvgItem {
                width:32
                height:32
                svg: PlasmaCore.Svg {
                    imagePath: "widgets/arrows"
                }
                elementId: "right-arrow"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
            }
            Behavior on opacity {
                NumberAnimation {duration: 1000}
            }
            MouseArea {
                anchors.fill: parent
                onClicked: recommendationsPanel.state = "show"
            }
        }

        PlasmaCore.FrameSvgItem {
            id: containmentItem
            width: parent.width-60
            height: parent.height
            imagePath: "widgets/background"
            enabledBorders: "RightBorder|TopBorder|BottomBorder"
        }
    }

    Timer {
        id : hideTimer
        interval: 4000;
        running: false;
        onTriggered:  {
            recommendationsPanel.state = "hidden"
        }
    }

    AppletStatusWatcher {
        id: appletStatusWatcher
    }

    property QGraphicsWidget containment
    onContainmentChanged: {
        containment.parent = containmentItem
        containment.x = containmentItem.margins.left
        containment.y = containmentItem.margins.top
        containment.width = containmentFlickable.width - containmentItem.margins.left - containmentItem.margins.right
        containment.height = containmentFlickable.height - containmentItem.margins.top - containmentItem.margins.bottom
        containment.z = hideTimerResetRegion.z -1
        appletStatusWatcher.plasmoid = containment
    }

    MouseArea {
        id: hideTimerResetRegion;
        z: 9000

        anchors.fill: parent

        onPressed: {
            hideTimer.restart()
            mouse.accepted = false
        }
    }

    states: [
        State {
            name: "show";
            PropertyChanges {
                target: recommendationsPanel;
                x: 0;
            }
            PropertyChanges {
                target: hint;
                opacity: 0;
            }
            PropertyChanges {
                target: hideTimer;
                running: true
            }
        },
        State {
            name: "hidden";
            PropertyChanges {
                target: recommendationsPanel;
                x: - width;
            }
            PropertyChanges {
                target: hint;
                opacity: 1;
            }
        },
        State {
            name: "dragging"
            PropertyChanges {
                target: recommendationsPanel;
                x: recommendationsPanel.x;
                y: recommendationsPanel.y;

            }
            PropertyChanges {
                target: hint;
                opacity: 0;
            }
        }
    ]

    transitions: [
        Transition {
            from: "show";
            to: "hidden";
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation {
                        targets: recommendationsPanel;
                        properties: "x";
                        duration: 1000;
                        easing.type: "InOutCubic";
                    }
                }
                ParallelAnimation {
                    PropertyAnimation {
                        target: hint;
                        property: "opacity";
                        duration: 600;
                        easing.type: "InCubic";
                    }
                }
            }
        },
        Transition {
            from: "hidden";
            to: "show";
            NumberAnimation {
                targets: recommendationsPanel;
                properties: "x";
                duration: 800;
                easing.type: "InOutCubic";
            }
        },
        Transition {
            from: "dragging";
            to: "*";
            NumberAnimation {
                properties: "x,y";
                easing.type: "OutQuad";
                duration: 400;
            }
        }
    ]

}

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
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 1.0
import org.kde.metadatamodels 0.1 as MetadataModels
import org.kde.plasma.components 0.1 as PlasmaComponents
import org.kde.plasma.core 0.1 as PlasmaCore
import org.kde.plasma.mobilecomponents 0.1 as MobileComponents
import org.kde.plasma.slccomponents 0.1 as SlcComponents
import org.kde.qtextracomponents 0.1


PlasmaComponents.Page {
    id: viewerPage
    anchors.fill: parent

    state: "toolsClosed"

    signal zoomIn
    signal zoomOut

    tools: Item {
        height: childrenRect.height
        PlasmaComponents.ToolButton {
            id: backIcon
            anchors.left: parent.left
            iconSource: "go-previous"
            width: theme.largeIconSize
            height: width
            flat: false
            onClicked: {
                //we want to tell the current image was closed
                resourceInstance.uri = ""
                mainStack.pop()
            }
        }
        Text {
            text: i18n("%1 of %2", quickBrowserBar.currentIndex+1, quickBrowserBar.count)
            anchors.centerIn: parent
            font.pointSize: 14
            font.bold: true
            color: theme.textColor
            style: Text.Raised
            styleColor: theme.backgroundColor
        }
        Row {
            anchors.right: parent.right
            PlasmaComponents.ToolButton {
                iconSource: "zoom-in"
                width: theme.largeIconSize
                height: width
                flat: false
                onClicked: viewerPage.zoomIn()
            }
            PlasmaComponents.ToolButton {
                iconSource: "zoom-out"
                width: theme.largeIconSize
                height: width
                flat: false
                onClicked: viewerPage.zoomOut()
            }
        }
    }

    function loadFile(path)
    {
        if (path.length == 0) {
            return
        }

        if (String(path).indexOf("/") === 0) {
            path = "file://"+path
        }

        //is in Nepomuk
        var index = metadataModel.find(path);
        if (index > -1) {
            fileBrowserRoot.model = metadataModel
            quickBrowserBar.currentIndex = index
            fileBrowserRoot.state = "image"
            return
        } else {
            //is in dirModel
            fileBrowserRoot.model = dirModel
            index = dirModel.indexForUrl(path)
            quickBrowserBar.currentIndex = index
            //fullList.visible = true
            fileBrowserRoot.state = "image"
        }
        imageArea.delegate.source = path
    }

    function setCurrentIndex(index)
    {
        quickBrowserBar.currentIndex = index
    }

    Rectangle {
        id: viewer

        color: "black"
        anchors.fill:  parent
    }

    MouseEventListener {
        id: imageArea
        anchors.fill: parent
        //enabled: !delegate.interactive
        property Item delegate: delegate1
        property Item oldDelegate: delegate2
        property bool incrementing: true

        property int lastX
        property int startX
        onPressed: lastX = startX = mouse.screenX
        onPositionChanged: {
            if (delegate.interactive) {
                return
            }
            delegate.x += (mouse.screenX - lastX)
            lastX = mouse.screenX
            incrementing = delegate.x < 0
            if (incrementing) {
                oldDelegate.source = fileBrowserRoot.model.get(quickBrowserBar.currentIndex + 1).url
            } else {
                fileBrowserRoot.model.get(quickBrowserBar.currentIndex - 1).url
            }
        }
        onReleased: {
            if (Math.abs(lastX - startX) < 20) {
                if (viewerPage.state == "toolsOpen") {
                    viewerPage.state = "toolsClosed"
                } else {
                    viewerPage.state = "toolsOpen"
                }
            } else if (!delegate.interactive) { 
                if (delegate.x > delegate.width/2 || delegate.x < -delegate.width/2) {
                    oldDelegate = delegate
                    delegate = (delegate == delegate1) ? delegate2 : delegate1
                    switchAnimation.running = true
                } else {
                    resetAnimation.running = true
                }
            }
        }
        FullScreenDelegate {
            id: delegate2
            width: parent.width
            height: parent.height
        }
        FullScreenDelegate {
            id: delegate1
            width: parent.width
            height: parent.height
        }
        SequentialAnimation {
            id: switchAnimation
            NumberAnimation {
                target: imageArea.oldDelegate
                properties: "x"
                to: imageArea.incrementing ? -imageArea.oldDelegate.width : imageArea.oldDelegate.width
                easing.type: Easing.InQuad
                duration: 250
            }
            ScriptAction {
                script: {
                    if (imageArea.incrementing) {
                        quickBrowserBar.currentIndex += 1
                    } else {
                        quickBrowserBar.currentIndex -= 1
                    }
                    imageArea.oldDelegate.z = 0
                    imageArea.delegate.z = 10
                    imageArea.oldDelegate.x = 0
                    imageArea.delegate.x = 0
                }
            }
        }
        NumberAnimation {
            id: resetAnimation
            target: imageArea.delegate
            properties: "x"
            to: 0
            easing.type: Easing.InOutQuad
            duration: 250
        }
    }

    QuickBrowserBar {
        id: quickBrowserBar
        model: fileBrowserRoot.model
        onCurrentIndexChanged: {
            imageArea.delegate.source = fileBrowserRoot.model.get(currentIndex).url
        }
    }

    states: [
        State {
            name: "toolsOpen"
            PropertyChanges {
                target: toolBar
                y: 0
            }
            PropertyChanges {
                target: quickBrowserBar
                y: fileBrowserRoot.height - quickBrowserBar.height
            }
        },
        State {
            name: "toolsClosed"
            PropertyChanges {
                target: toolBar
                y: -toolBar.height
            }
            PropertyChanges {
                target: quickBrowserBar
                y: fileBrowserRoot.height+20
            }
        }
    ]

    transitions: [
        Transition {
            NumberAnimation {
                properties: "y"
                easing.type: Easing.InOutQuad
                duration: 250
            }
        }
    ]
}


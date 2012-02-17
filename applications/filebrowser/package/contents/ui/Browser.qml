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
import org.kde.dirmodel 0.1


PlasmaComponents.Page {
    anchors {
        fill: parent
        topMargin: toolBar.height
    }

    tools: Item {
        width: parent.width
        height: childrenRect.height

        PlasmaCore.DataSource {
            id: hotplugSource
            engine: "hotplug"
            connectedSources: sources
        }
        PlasmaCore.DataSource {
            id: devicesSource
            engine: "soliddevice"
            connectedSources: hotplugSource.sources
        }
        PlasmaCore.DataModel {
            id: devicesModel
            dataSource: hotplugSource
        }
        DirModel {
            id: dirModel
        }

        PlasmaComponents.TabBar {
            id: devicesTabBar
            height: theme.largeIconSize
            width: height * tabCount
            property int tabCount: 1

            function updateSize()
            {
                var visibleChildCount = devicesTabBar.layout.children.length

                for (var i = 0; i < devicesTabBar.layout.children.length; ++i) {
                    if (!devicesTabBar.layout.children[i].visible || devicesTabBar.layout.children[i].text == undefined) {
                        --visibleChildCount
                    }
                }
                devicesTabBar.tabCount = visibleChildCount
            }

            opacity: tabCount > 1 ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }
            PlasmaComponents.TabButton {
                id: localButton
                height: width
                property bool current: devicesTabBar.currentTab == localButton
                iconSource: "drive-harddisk"
                onCurrentChanged: {
                    if (current) {
                        resultsGrid.model = metadataModel
                    }
                }
            }
            Repeater {
                id: devicesRepeater
                model: devicesModel

                delegate: PlasmaComponents.TabButton {
                    id: removableButton
                    visible: devicesSource.data[udi]["Removable"] == true
                    onVisibleChanged: devicesTabBar.updateSize()
                    iconSource: model["icon"]
                    property bool current: devicesTabBar.currentTab == removableButton
                    onCurrentChanged: {
                        if (current) {
                            dirModel.url = devicesSource.data[udi]["File Path"]
                            resultsGrid.model = dirModel
                        }
                    }
                }
            }
        }


        MobileComponents.ViewSearch {
            id: searchBox
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            onSearchQueryChanged: {
                metadataModel.extraParameters["nfo:fileName"] = searchBox.searchQuery
            }
        }
    }

    MobileComponents.IconGrid {
        id: resultsGrid
        anchors.fill: parent

        model: metadataModel

        delegateWidth: 130
        delegateHeight: 120
        delegate: MobileComponents.ResourceDelegate {
            id: resourceDelegate
            className: model["className"]?model["className"]:"Image"
            width: 130
            height: 120
            infoLabelVisible: false
            property string label: model["label"]?model["label"]:model["display"]

            onPressAndHold: {
                resourceInstance.uri = model["url"]?model["url"]:model["resourceUri"]
                resourceInstance.title = model["label"]
            }

            onClicked: {
                if (mimeType == "inode/directory") {
                    dirModel.url = model["url"]
                    resultsGrid.model = dirModel
                } else if (!mainStack.busy) {
                    Qt.openUrlExternally(model["url"])
                }
            }
        }
    }
}

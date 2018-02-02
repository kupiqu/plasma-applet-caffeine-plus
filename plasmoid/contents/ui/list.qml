/*
*   Copyright (C) 2011 by Daker Fernandes Pinheiro <dakerfp@gmail.com>
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

import QtQuick 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.taskmanager 0.1 as TaskManager
import org.kde.kwindowsystem 1.0 as KWindowSystem


PlasmaComponents.Page {
    tools: PlasmaComponents.ToolBarLayout {
        spacing: 5
        PlasmaComponents.CheckBox {
        	id: enableRestore
            text: "Inhibit suspend"
            onCheckedChanged: {
            	plasmoid.configuration.enableRestore = checked
			}
			onClicked: caffeinePlus.toggle(enableRestore.checked)
			Component.onCompleted: {
				enableRestore.checked = plasmoid.configuration.enableRestore
			}
        }
    }




    TaskManager.TasksModel {
        id: tasksModel

        sortMode: TaskManager.TasksModel.SortVirtualDesktop
        groupMode: TaskManager.TasksModel.GroupDisabled
    }

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    KWindowSystem.KWindowSystem {
        id: windowSystem
    }

        ListView {
            id: windowListView

            property bool overflowing: (visibleArea.heightRatio < 1.0)
            property var pinTopItem: null
            property var pinBottomItem: null

            focus: true

            model: tasksModel

            boundsBehavior: Flickable.StopAtBounds
            snapMode: ListView.SnapToItem
            spacing: 0
            keyNavigationWraps: true

            highlight: PlasmaComponents.Highlight {}
            highlightMoveDuration: 0

            onOverflowingChanged: {
                if (!overflowing) {
                    pinTopItem = null;
                    pinBottomItem = null;
                }
            }

            onContentYChanged: {
                pinTopItem = contentItem.childAt(0, contentY);
                pinBottomItem = contentItem.childAt(0, contentY + windowPin.height);
            }

            section.property: virtualDesktopInfo.numberOfDesktops ? "VirtualDesktop" : undefined
            section.criteria: ViewSection.FullString
            section.delegate: PlasmaComponents.Label {
                height: root.itemHeight
                width: root.width

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                textFormat: Text.PlainText
                wrapMode: Text.NoWrap
                elide: Text.ElideRight

                text: {
                    if (section > 0) {
                        return virtualDesktopInfo.desktopNames[section - 1];
                    }

                    return i18n("On all desktops");
                }
            }

            delegate: MouseArea {
                id: item

                height: root.itemHeight
                width: windowListView.overflowing ? ListView.view.width - units.smallSpacing : ListView.view.width

                property bool underPin: (item == windowListView.pinTopItem || item == windowListView.pinBottomItem)

                Accessible.role: Accessible.MenuItem
                Accessible.name: label.text

                hoverEnabled: true

                onClicked: tasksModel.requestActivate(tasksModel.makeModelIndex(index))

                onContainsMouseChanged: {
                    if (containsMouse) {
                        windowListView.focus = true;
                        windowListView.currentIndex = index;
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: highlightItemSvg.margins.left
                    anchors.right: parent.right
                    anchors.rightMargin: highlightItemSvg.margins.right

                    height: parent.height

                    spacing: units.smallSpacing * 2

                    LayoutMirroring.enabled: (Qt.application.layoutDirection == Qt.RightToLeft)

                    PlasmaCore.IconItem {
                        id: icon

                        anchors.verticalCenter: parent.verticalCenter

                        width: visible ? units.iconSizes.small : 0
                        height: width

                        usesPlasmaTheme: false

                        source: model.decoration
                    }

                    PlasmaComponents.Label {
                        id: label

                        width: (parent.width - icon.width - parent.spacing - (underPin ? root.width - windowPin.x : 0))
                        height: parent.height

                        verticalAlignment: Text.AlignVCenter

                        textFormat: Text.PlainText
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight

                        text: model.display
                    }
                }

                Keys.onTabPressed: windowPin.focus = true
                Keys.onBacktabPressed: windowPin.focus = true

                Keys.onPressed: {
                    if (event.key == Qt.Key_Enter || event.key == Qt.Key_Return) {
                        event.accepted = true;

                        tasksModel.requestActivate(tasksModel.makeModelIndex(index))

                        if (!windowPin.checked) {
                            plasmoid.expanded = false;
                        }
                    }
                }
            }
        }





    /*
    ListView {
        id: pageSelector
        clip: true
        anchors.fill: parent

        model:  ListModel {
            id: pagesModel
            ListElement {
                title: "testing title"
            }
            ListElement {
                title: "Checkable buttons"
            }
            ListElement {
                title: "Busy indicators"
            }
            ListElement {
                title: "Sliders"
            }
            ListElement {
                title: "Scrollers"
            }
            ListElement {
                title: "Text elements"
            }
            ListElement {
                title: "Typography"
            }
            ListElement {
                title: "Misc stuff"
            }
        }
        delegate: ListItem {
            enabled: true
            Column {
                Label {
                    text: title
                }
            }
            //onClicked: pageStack.push(Qt.createComponent(page))
        }
    }*/

    PlasmaComponents.ScrollBar {
        id: horizontalScrollBar

        flickableItem: pageSelector
        orientation: Qt.Horizontal
        anchors {
            left: parent.left
            right: verticalScrollBar.left
            bottom: parent.bottom
        }
    }

    PlasmaComponents.ScrollBar {
        id: verticalScrollBar

        orientation: Qt.Vertical
        flickableItem: pageSelector
        anchors {
            top: parent.top
            right: parent.right
            bottom: horizontalScrollBar.top
        }
    }
}
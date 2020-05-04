/*
 * Copyright 2016  Eike Hein <hein@kde.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.taskmanager 0.1 as TaskManager
import org.kde.kwindowsystem 1.0 as KWindowSystem


Item {
    id: windows
    signal inhibitionsChanged
	onInhibitionsChanged: {
		tasksModel.modelReset();
	}

    Layout.minimumWidth: units.gridUnit * 12
    Layout.minimumHeight: units.gridUnit * 12

    Plasmoid.switchWidth: units.gridUnit * 11
    Plasmoid.switchHeight: units.gridUnit * 11

    // Plasmoid.toolTipSubText: i18n("Show list of opened windows")

    property int itemHeight: Math.ceil((Math.max(theme.mSize(theme.defaultFont).height, units.iconSizes.small)
        + Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
        listItemSvg.margins.top + listItemSvg.margins.bottom)) / 2) * 2

    Component.onCompleted: {
    	root.windowsIsInited = true;
    	root.windows = windows;
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

    PlasmaCore.FrameSvgItem {
        id : highlightItemSvg

        visible: false

        imagePath: "widgets/viewitem"
        prefix: "hover"
    }

    PlasmaCore.FrameSvgItem {
        id : listItemSvg

        visible: false

        imagePath: "widgets/viewitem"
        prefix: "normal"
    }

    Connections {
        target: plasmoid

        onExpandedChanged: {
            if (!expanded) {
                windowListView.currentIndex = 0;
            }
        }
    }

    PlasmaExtras.ScrollArea {
    	anchors.top: windowPin.bottom
        width: parent.width
        height: parent.height - windowPin.height

        focus: true

        onFocusChanged: {
            if (!focus) {
                windowListView.currentIndex = -1;
            }
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

            delegate: MouseArea {
                id: item

                height: windows.itemHeight
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
                    	visible: false
                    	source: plasmoid.configuration.useDefaultIcons ? plasmoid.configuration.defaultIconActive : plasmoid.configuration.iconActive
                        width: visible ? units.iconSizes.small : 0
                        height: width

                        anchors.verticalCenter: parent.verticalCenter
					}

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
	                    function check(model) {
	                    	var result = caffeinePlus.checkProcessIsInhibited(model["legacy_win_Id_list"])
	                    	if (result["inhibited_fullscreen"] || result["inhibited_user_app"] || result["inhibited_system"]) {
	                    		parent.children[0].visible = true
	                    		label.color = "green"
	                    	} else {
	                    		parent.children[0].visible = false
	                    		label.color = ""
	                    	}

	                    	return model.display
	                    }

                        width: (parent.width - icon.width - parent.spacing - (underPin ? windows.width - windowPin.x : 0))
                        height: parent.height

                        verticalAlignment: Text.AlignVCenter

                        textFormat: Text.PlainText
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight

                        text: check(model)
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
    }

    PlasmaComponents.CheckBox {
        	id: enableRestore
            text: i18n("Inhibit power saving globally")
            onCheckedChanged: {
            	plasmoid.configuration.enableRestore = checked
			}
			onClicked: caffeinePlus.toggle(enableRestore.checked)
			Component.onCompleted: {
				enableRestore.checked = plasmoid.configuration.enableRestore
			}
        }
    PlasmaComponents.ToolButton {
        id: windowPin

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: windowListView.overflowing ? units.gridUnit : 0

        width: Math.round(units.gridUnit * 1.25)

        iconSource: "window-pin"

        checkable: true
        onCheckedChanged: plasmoid.hideOnWindowDeactivate = !checked

        Keys.onTabPressed: {
            if (windowListView.count) {
                windowListView.currentIndex = 0;
                windowListView.forceActiveFocus();
            }
        }

        Keys.onBacktabPressed: cascadeButton.focus = true

        Keys.onUpPressed: {
            if (windowListView.count) {
                windowListView.currentIndex = (windowListView.count - 1);
                windowListView.forceActiveFocus();
            }
        }

        Keys.onDownPressed: {
            if (windowListView.count) {
                windowListView.currentIndex = 0;
                windowListView.forceActiveFocus();
            }
        }

        Keys.onLeftPressed: {
            if (windowListView.count) {
                windowListView.currentIndex = 0;
                windowListView.forceActiveFocus();
            }
        }

        Keys.onRightPressed: {
            if (windowListView.count) {
                windowListView.currentIndex = 0;
                windowListView.forceActiveFocus();
            }
        }
    }
}


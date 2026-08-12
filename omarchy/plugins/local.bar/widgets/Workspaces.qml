import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  readonly property var wsIcons: ({ 1: "一", 2: "二", 3: "三", 4: "四", 5: "五", 6: "六", 7: "七", 8: "八", 9: "九" })
  readonly property string defaultIcon: "\ueA71"
  readonly property string activeIcon: "\uee0d "
  readonly property color glyphColor: bar && bar.widgetGlyphColor
    ? bar.widgetGlyphColor(settings, bar.barForeground)
    : (bar ? bar.barForeground : Color.foreground)

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)
  readonly property real contentWidth: (Style.space(20) + Style.space(1)) * root.workspaceIds().length - Style.space(1)

  implicitWidth: contentWidth + trailingGap
  implicitHeight: root.barSize

  Item {
    id: grid
    anchors.centerIn: parent
    width: contentWidth
    height: parent.height

    Repeater {
      model: root.workspaceIds()

      Item {
        id: wsItem
        required property int modelData
        required property int index

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        width: root.vertical ? root.barSize : Style.space(20)
        height: root.vertical ? Style.space(20) : root.barSize
        x: index * (Style.space(20) + Style.space(1))
        anchors.verticalCenter: parent.verticalCenter

        WidgetButton {
          anchors.fill: parent
          bar: root.bar
          text: wsItem.focused ? root.activeIcon : (root.wsIcons[modelData] ? root.wsIcons[modelData] : root.defaultIcon)
          opacity: wsItem.occupied || wsItem.focused ? 1 : 0.5
          foreground: root.glyphColor
          activeColor: root.glyphColor
          active: wsItem.focused
          fontSize: Style.bar.iconFont - 1
          horizontalMargin: 0
          verticalPadding: 0
          onPressed: function() { root.focusWorkspace(modelData) }
        }
      }
    }
  }
}

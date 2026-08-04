import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Bar power button that opens the omarchy system menu as a panel: a hero,
// a rotating Linux quote, and the seven session actions (screensaver, lock,
// suspend, hibernate, logout, reboot, shutdown) — the same commands the
// SUPER+ESCAPE system menu runs.
Panel {
  id: root
  moduleName: "omarchy.system"
  ipcTarget: "omarchy.system"

  readonly property int actionColumns: 2
  // Destructive actions use the theme's bright_red: the Solitude palette maps
  // its grey `red` onto the `urgent` role, so bar.urgent renders grey here.
  readonly property color destructiveColor: "#de6145"
  property int cursorIndex: 0
  property bool cursorActive: false
  property int quoteIndex: -1

  property var actions: [
    { icon: "󱄄", label: "Screensaver", command: ["omarchy-launch-screensaver", "force"] },
    { icon: "", label: "Lock", command: ["omarchy-system-lock"] },
    { icon: "󰒲", label: "Suspend", command: ["systemctl", "suspend"] },
    { icon: "󰤁", label: "Hibernate", command: ["systemctl", "hibernate"] },
    { icon: "󰍃", label: "Logout", command: ["omarchy-system-logout"] },
    { icon: "󰜉", label: "Reboot", command: ["omarchy-system-reboot"] },
    { icon: "󰐥", label: "Shutdown", command: ["omarchy-system-shutdown"], urgent: true }
  ]

  property var quotes: [
    "The best way to predict the future is to invent it",
    "I use Arch, btw",
    "So long, and thanks for all the fish",
    "Talk is cheap. Show me the code",
    "Trust, but verify",
    "End of line",
    "Unix is user friendly. It's just very selective about who its friends are",
    "Software is like sex: it's better when it's free",
    "I'm sorry, Dave. I'm afraid I can't do that",
    "Keep it simple, stupid",
    "In a world without walls and fences, who needs Windows and Gates?",
    "Good night, and good luck",
    "Arch is what you make it",
    "A computer is like air conditioning — it becomes useless when you open Windows",
    "Every exit is an entry somewhere else",
    "Simplicity. Modernity. Pragmatism. User centrality. Versatility",
    "Simplicity is the ultimate sophistication",
    "There's no place like 127.0.0.1",
    "UNIX is basically a simple operating system, but you have to be a genius to understand the simplicity",
    "Pacman is its own man",
    "Those who can imagine anything, can create the impossible",
    "The number of UNIX installations has multiplied to such an extent that almost everything you do involves UNIX in some way",
    "If debugging is the process of removing software bugs, then programming must be the process of putting them in",
    "One of my most productive days was throwing away 1,000 lines of code",
    "Computers are useless. They can only give you answers",
    "First, solve the problem. Then, write the code",
    "Unix was not designed to stop its users from doing stupid things, because that would also stop them from doing clever things"
  ]

  readonly property var currentQuote: {
    if (quoteIndex >= 0 && quoteIndex < quotes.length) return quotes[quoteIndex]
    return quotes[0]
  }

  function pickQuote() {
    var n = root.quotes.length
    if (n === 0) return
    var next
    do { next = Math.floor(Math.random() * n) } while (next === root.quoteIndex && n > 1)
    root.quoteIndex = next
  }

  function runAction(action) {
    if (!action) return
    actionProc.command = action.command
    actionProc.running = true
    root.close()
  }

  function activateCursor() {
    if (cursorIndex >= 0 && cursorIndex < root.actions.length) runAction(root.actions[cursorIndex])
  }

  function moveCursor(dx, dy) {
    if (dy !== 0) {
      root.cursorIndex = Math.max(0, Math.min(root.actions.length - 1, root.cursorIndex + dy * root.actionColumns))
    } else if (dx !== 0) {
      var rowStart = Math.floor(root.cursorIndex / root.actionColumns) * root.actionColumns
      var rowEnd = Math.min(rowStart + root.actionColumns - 1, root.actions.length - 1)
      root.cursorIndex = Math.max(rowStart, Math.min(rowEnd, root.cursorIndex + dx))
    }
  }

  onOpenedChanged: {
    if (opened) {
      cursorActive = false
      cursorIndex = 0
      pickQuote()
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: actionProc
  }

  // Rotate the quote while the panel is open. The text swap is wrapped in a
  // fade so the changeover reads as one organism rather than a hard cut.
  Timer {
    id: quoteTimer
    interval: 8000
    running: root.opened
    repeat: true
    triggeredOnStart: false
    onTriggered: quoteSwap.restart()
  }

  SequentialAnimation {
    id: quoteSwap
    PropertyAnimation {
      target: quoteBlock; property: "opacity"
      to: 0.0; duration: 180; easing.type: Easing.OutQuad
    }
    ScriptAction { script: root.pickQuote() }
    PropertyAnimation {
      target: quoteBlock; property: "opacity"
      to: 1.0; duration: 260; easing.type: Easing.InQuad
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.iconCanvas - 1 + Style.spaceReal(6) * 2
    opticalSize: Style.bar.iconCanvas - 1
    fontSize: Style.bar.iconFont - 1
    text: ""
    tooltipText: ""
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        root.moveCursor(dx, dy)
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        // ---------- Hero: power icon · title ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
    text: ""
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "System"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              text: "POWER & SESSION"
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        // ---------- Rotating Linux quote ----------
        Item {
          id: quoteBlock
          width: parent.width
          implicitHeight: quoteText.implicitHeight

          Text {
            id: quoteText
            width: parent.width
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: root.currentQuote
            color: Qt.darker(root.bar.foreground, 1.35)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            font.italic: true
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
          }
        }

        // ---------- Session actions ----------
        PanelSeparator {
          foreground: root.bar.foreground
        }

        Column {
          width: parent.width
          spacing: Style.space(10)

          PanelSectionHeader {
            text: "ACTIONS"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Column {
            width: parent.width
            spacing: Style.space(8)

            Grid {
              id: actionGrid
              width: parent.width
              columns: root.actionColumns
              spacing: Style.space(8)

              readonly property real cellWidth: (width - spacing * (columns - 1)) / columns

              Repeater {
                model: root.actions.slice(0, root.actions.length - 1)

                Button {
                  required property var modelData
                  required property int index

                  width: actionGrid.cellWidth
                  iconText: modelData.icon
                  iconSize: Style.font.title
                  text: modelData.label
                  fontSize: Style.font.body
                  foreground: modelData.urgent ? root.destructiveColor : root.bar.foreground
                  fontFamily: root.bar.fontFamily
                  horizontalPadding: Style.spacing.controlPaddingX
                  verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                  bordered: true
                  leftAlign: true
                  hasCursor: root.cursorActive && root.cursorIndex === index
                  onClicked: root.runAction(modelData)
                  onHovered: function(h) {
                    if (h) {
                      root.cursorActive = true
                      root.cursorIndex = index
                    }
                  }
                }
              }
            }

            Button {
              width: parent.width
              iconText: root.actions[root.actions.length - 1].icon
              iconSize: Style.font.title
              text: root.actions[root.actions.length - 1].label
              fontSize: Style.font.body
              foreground: root.actions[root.actions.length - 1].urgent ? root.destructiveColor : root.bar.foreground
              fontFamily: root.bar.fontFamily
              horizontalPadding: Style.spacing.controlPaddingX
              verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
              bordered: true
              leftAlign: false
              hasCursor: root.cursorActive && root.cursorIndex === root.actions.length - 1
              onClicked: root.runAction(root.actions[root.actions.length - 1])
              onHovered: function(h) {
                if (h) {
                  root.cursorActive = true
                  root.cursorIndex = root.actions.length - 1
                }
              }
            }
          }
        }
      }
    }
  }
}

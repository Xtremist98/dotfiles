import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "weather"

  property string label: ""
  property var wdata: null
  property bool showInfo: false
  property bool showMenu: false
  property bool showLocation: false
  property var locationSuggestions: []
  property int suggestionIndex: 0

  readonly property color fg: bar ? bar.barForeground : Color.foreground
  readonly property string fontFam: bar ? bar.fontFamily : Style.font.family
  readonly property string scriptPath: Quickshell.env("HOME") + "/.config/omarchy/scripts/weather.sh"
  readonly property color popupText: Color.popups.text
  readonly property color popupMuted: Qt.darker(Color.popups.text, 1.5)

  implicitWidth: labelText.implicitWidth + Style.space(1)
  implicitHeight: barSize

  visible: label !== ""

  readonly property string labelIcon: {
    var i = root.label.indexOf(" ")
    return i > 0 ? root.label.substring(0, i) : root.label
  }
  readonly property string labelTextPart: {
    var i = root.label.indexOf(" ")
    return i > 0 ? root.label.substring(i + 1) : ""
  }

  Row {
    id: labelText
    height: root.barSize
    leftPadding: Style.spaceReal(6)
    rightPadding: Style.spaceReal(6)
    spacing: Style.space(6)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.labelIcon
      color: root.fg
      font.family: root.fontFam
      font.pixelSize: Style.font.body
      renderType: Text.NativeRendering
    }

    Text {
      visible: root.labelTextPart !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: root.labelTextPart
      color: root.fg
      font.family: root.fontFam
      font.pixelSize: Style.font.body
      renderType: Text.NativeRendering
    }
  }

  // ------------------------------------------------------------------ data

  Process {
    id: weatherProc
    command: ["bash", root.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseData(text)
    }
  }

  Timer {
    id: refreshTimer
    interval: 900000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  function refresh() {
    if (!weatherProc.running) weatherProc.running = true
  }

  function setRefreshInterval(ms) {
    if (refreshTimer.interval !== ms) {
      refreshTimer.interval = ms
      refreshTimer.restart()
    }
  }

  function parseData(raw) {
    try {
      var d = JSON.parse(String(raw || "").trim())
      if (d && d.hasOwnProperty("text")) {
        root.label = String(d.text == null ? "" : d.text)
        root.setRefreshInterval(root.label !== "" ? 900000 : 60000)
      } else {
        root.label = ""
        root.setRefreshInterval(60000)
      }
      root.wdata = d
    } catch (e) {
      root.label = ""
      root.setRefreshInterval(60000)
    }
  }

  function close() {
    root.showInfo = false
    root.showMenu = false
    root.showLocation = false
  }

  function padStart(s, len) {
    var str = String(s == null ? "" : s)
    while (str.length < len) str = " " + str
    return str
  }

  function padEnd(s, len) {
    var str = String(s == null ? "" : s)
    while (str.length < len) str += " "
    return str
  }

  function metricsText() {
    var d = root.wdata || {}
    var rows = []
    rows.push("  💧 Humidity : " + root.padEnd(String(d.humidity || "") + "%", 9) + "   🌬️ Wind : " + String(d.wind || "") + " km/h")
    rows.push("  👁️ Vis     : " + root.padEnd(String(d.vis || "") + " km", 9) + "   🏭 AQI  : " + String(d.aqi || "") + " (" + String(d.aqiLabel || "") + ")")
    rows.push("  ☀️ UV Index: " + root.padEnd(String(d.uv || "") + " (" + String(d.uvLabel || "") + ")", 9) + "   🌡️ Pres : " + String(d.pressure || "") + " hPa")
    rows.push("  🌅 Sunrise  : " + root.padEnd(String(d.sunrise || ""), 9) + "   🌇 Sunset: " + String(d.sunset || ""))
    return rows.join("\n")
  }

  function hourlyText() {
    var list = root.wdata && root.wdata.hourly ? root.wdata.hourly : []
    var unit = root.wdata ? root.wdata.unit || "" : ""
    var rows = []
    for (var i = 0; i < list.length; i++) {
      var h = list[i]
      rows.push("  " + root.padEnd(String(h.time || ""), 7) + "  " + String(h.icon || "") + "   " + root.padStart(String(h.temp || ""), 2) + "°" + unit + "   🌧️ " + root.padStart(String(h.rain || ""), 3) + "%")
    }
    return rows.join("\n")
  }

  function dailyText() {
    var list = root.wdata && root.wdata.daily ? root.wdata.daily : []
    var unit = root.wdata ? root.wdata.unit || "" : ""
    var rows = []
    for (var i = 0; i < list.length; i++) {
      var day = list[i]
      rows.push("  " + root.padEnd(String(day.day || ""), 12) + "  " + String(day.icon || "") + "    " + root.padStart(String(day.max || ""), 2) + "°" + unit + " / " + root.padStart(String(day.min || ""), 2) + "°" + unit)
    }
    return rows.join("\n")
  }

  function searchLoc() {
    return root.wdata && root.wdata.loc ? String(root.wdata.loc) : ""
  }

  function wttrUrl() {
    var city = searchLoc().split(",")[0].trim()
    return "https://wttr.in/" + encodeURIComponent(city)
  }

  function googleUrl() {
    return "https://www.google.com/search?q=weather+" + encodeURIComponent(searchLoc()).replace(/%20/g, "+")
  }

  function menuItems() {
    var unit = root.wdata && root.wdata.unit ? String(root.wdata.unit) : ""
    var toggleLabel = unit === "C" ? "Toggle Unit (°F)" : unit === "F" ? "Toggle Unit (°C)" : "Toggle Unit"
    return [
      { icon: "📍", label: "Change Location", action: "location" },
      { icon: "🔄", label: toggleLabel, action: "unit" },
      { icon: "🛰️", label: "Reset to Auto IP", action: "reset" },
      { icon: "⚡", label: "Force Refresh", action: "refresh" },
      { icon: "🌐", label: "Open wttr.in", action: "wttr" },
      { icon: "🌍", label: "Open Google Weather", action: "google" }
    ]
  }

  function menuAction(action) {
    root.showMenu = false
    if (action === "location") {
      root.showLocation = true
    } else if (action === "unit") {
      toggleProc.command = ["bash", root.scriptPath, "--toggle-unit"]
      toggleProc.running = true
    } else if (action === "reset") {
      clearLocProc.running = true
    } else if (action === "refresh") {
      clearCacheProc.running = true
    } else if (action === "wttr") {
      if (root.bar) root.bar.run("xdg-open \"" + root.wttrUrl() + "\"")
    } else if (action === "google") {
      if (root.bar) root.bar.run("xdg-open \"" + root.googleUrl() + "\"")
    }
  }

  // ------------------------------------------------------------ location

  function startGeocode() {
    var query = locationField.text.trim()
    if (query.length < 2) {
      root.locationSuggestions = []
      return
    }
    geocodeProc.command = ["curl", "-fsS", "--max-time", "5",
      "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(query) + "&count=5&language=en&format=json"]
    if (!geocodeProc.running) geocodeProc.running = true
  }

  function parseGeocode(raw) {
    try {
      var json = JSON.parse(String(raw || "").trim())
      var results = json.results || []
      var list = []
      for (var i = 0; i < results.length; i++) {
        var r = results[i]
        var sub = [r.admin1, r.country].filter(function(x) { return x }).join(", ")
        list.push({ name: String(r.name || ""), sub: String(sub || "") })
      }
      root.locationSuggestions = list
      root.suggestionIndex = 0
    } catch (e) {
      root.locationSuggestions = []
    }
  }

  function pickSuggestion(index) {
    var s = root.locationSuggestions[index]
    if (s && s.name) root.applyLocation(s.name)
  }

  function commitLocation() {
    var text = locationField.text.trim()
    if (text.length === 0) return
    if (root.suggestionIndex >= 0 && root.suggestionIndex < root.locationSuggestions.length) {
      root.applyLocation(root.locationSuggestions[root.suggestionIndex].name)
    } else {
      root.applyLocation(text)
    }
  }

  function applyLocation(name) {
    setLocProc.command = ["bash", root.scriptPath, "--set-location", name]
    setLocProc.running = true
    root.showLocation = false
  }

  // -------------------------------------------------------------- actions

  Process {
    id: toggleProc
    onExited: Qt.callLater(root.refresh)
  }

  Process {
    id: clearCacheProc
    command: ["bash", root.scriptPath, "--clear-cache"]
    onExited: Qt.callLater(root.refresh)
  }

  Process {
    id: clearLocProc
    command: ["bash", root.scriptPath, "--clear-location"]
    onExited: Qt.callLater(root.refresh)
  }

  Process {
    id: setLocProc
    onExited: Qt.callLater(root.refresh)
  }

  Process {
    id: geocodeProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseGeocode(text)
    }
  }

  Timer {
    id: geocodeDebounce
    interval: 300
    onTriggered: root.startGeocode()
  }

  // ---------------------------------------------------------------- popup

  PopupCard {
    id: infoPopup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.showInfo
    triggerMode: "click"
    contentWidth: fittedContentWidth(Style.space(400))
    contentHeight: fittedContentHeight(infoColumn.implicitHeight)

    Column {
      id: infoColumn
      anchors.fill: parent
      spacing: Style.space(6)

      Row {
        width: parent.width
        spacing: Style.space(10)

        Text {
          anchors.verticalCenter: parent.verticalCenter
          anchors.verticalCenterOffset: 5
          text: root.wdata && root.wdata.icon ? root.wdata.icon : "—"
          color: root.popupText
          font.family: root.fontFam
          font.pixelSize: Style.font.displayLarge
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 0

          Row {
            spacing: Style.space(1)
            Text {
              text: root.wdata && root.wdata.temp ? root.wdata.temp : "—"
              color: root.popupText
              font.family: root.fontFam
              font.pixelSize: Style.font.display
              font.bold: true
            }
            Text {
              text: root.wdata && root.wdata.unit ? "°" + root.wdata.unit : ""
              color: root.popupText
              font.family: root.fontFam
              font.pixelSize: Style.font.body
            }
          }

          Text {
            text: root.wdata && root.wdata.desc ? root.wdata.desc : ""
            color: root.popupMuted
            font.family: root.fontFam
            font.pixelSize: Style.font.bodySmall
          }
        }
      }

      Text {
        width: parent.width
        visible: root.wdata != null && root.wdata.loc != ""
        text: root.wdata && root.wdata.loc ? (root.wdata.loc + "   •   Feels " + root.wdata.feels + "°" + root.wdata.unit + "   •   H/L " + root.wdata.tmax + "°" + root.wdata.unit + " / " + root.wdata.tmin + "°" + root.wdata.unit) : ""
        color: root.popupMuted
        font.family: root.fontFam
        font.pixelSize: Style.font.bodySmall
      }

      Rectangle {
        width: parent.width
        height: Style.spacing.hairline
        color: root.popupText
        opacity: 0.12
      }

      Text {
        text: "METRICS"
        color: Color.accent
        font.family: root.fontFam
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1
      }
      Text {
        width: parent.width
        text: root.metricsText()
        color: root.popupText
        font.family: root.fontFam
        font.pixelSize: Style.font.bodySmall
        lineHeight: 1.4
      }

      Text {
        text: "HOURLY"
        color: Color.accent
        font.family: root.fontFam
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1
      }
      Text {
        width: parent.width
        text: root.hourlyText()
        color: root.popupText
        font.family: root.fontFam
        font.pixelSize: Style.font.bodySmall
        lineHeight: 1.4
      }

      Text {
        text: "OUTLOOK"
        color: Color.accent
        font.family: root.fontFam
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1
      }
      Text {
        width: parent.width
        text: root.dailyText()
        color: root.popupText
        font.family: root.fontFam
        font.pixelSize: Style.font.bodySmall
        lineHeight: 1.4
      }
    }
  }

  // --------------------------------------------------------------- menu

  PopupCard {
    id: menuPopup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.showMenu
    triggerMode: "click"
    contentWidth: fittedContentWidth(Style.space(230))
    contentHeight: fittedContentHeight(menuColumn.implicitHeight)

    Column {
      id: menuColumn
      anchors.fill: parent
      spacing: Style.space(2)

      Repeater {
        model: root.menuItems()

        Button {
          required property var modelData
          width: parent.width
          text: modelData.label
          iconText: modelData.icon
          leftAlign: true
          foreground: root.popupText
          accent: Color.accent
          fontFamily: root.fontFam
          fontSize: Style.font.body
          horizontalPadding: Style.space(8)
          verticalPadding: Style.space(4)
          onClicked: root.menuAction(modelData.action)
        }
      }
    }
  }

  // ------------------------------------------------------------ location

  // KeyboardPanel (layer-shell, WlrKeyboardFocus.Exclusive prime) instead of
  // PopupCard: xdg-popups only receive keys after a click routes focus through
  // their parent surface, so a programmatically-opened search field would
  // never get keystrokes. focusTarget hands Qt active focus to the TextField.
  KeyboardPanel {
    id: locationPopup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.showLocation
    focusTarget: locationField
    contentWidth: fittedContentWidth(Style.space(280))
    contentHeight: fittedContentHeight(locationColumn.implicitHeight)

    Column {
      id: locationColumn
      anchors.fill: parent
      spacing: Style.space(6)

      Text {
        text: "SEARCH CITY"
        color: root.popupMuted
        font.family: root.fontFam
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
      }

      TextField {
        id: locationField
        width: parent.width
        foreground: root.popupText
        accent: Color.accent
        placeholderText: "Type a city name…"
        onTextChanged: geocodeDebounce.restart()
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.showLocation = false
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            if (root.locationSuggestions.length > 0)
              root.suggestionIndex = Math.min(root.suggestionIndex + 1, root.locationSuggestions.length - 1)
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.suggestionIndex = Math.max(root.suggestionIndex - 1, 0)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.commitLocation()
            event.accepted = true
          }
        }
      }

      Repeater {
        model: root.locationSuggestions

        Rectangle {
          required property var modelData
          required property int index
          width: parent.width
          height: Style.space(24)
          radius: Style.cornerRadius
          color: index === root.suggestionIndex ? Style.hoverFillFor(root.popupText, Color.accent) : "transparent"

          Row {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(6)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(8)

            Text {
              text: modelData.name
              color: root.popupText
              font.family: root.fontFam
              font.pixelSize: Style.font.body
            }
            Text {
              visible: modelData.sub !== ""
              text: modelData.sub
              color: root.popupMuted
              font.family: root.fontFam
              font.pixelSize: Style.font.bodySmall
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: root.suggestionIndex = index
            onClicked: root.pickSuggestion(index)
          }
        }
      }

      Text {
        width: parent.width
        visible: root.locationSuggestions.length === 0
        text: "Suggestions appear as you type…"
        color: root.popupMuted
        font.family: root.fontFam
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
    }
  }

  // -------------------------------------------------------------- clicks

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: function(mouse) {
      if (!root.bar) return
      if (mouse.button === Qt.LeftButton) {
        root.showMenu = false
        root.showLocation = false
        root.showInfo = !root.showInfo
      } else if (mouse.button === Qt.RightButton) {
        root.showInfo = false
        root.showLocation = false
        root.showMenu = !root.showMenu
      } else if (mouse.button === Qt.MiddleButton) {
        root.showInfo = false
        root.showMenu = false
        root.showLocation = false
        clearCacheProc.running = true
      }
    }
  }
}

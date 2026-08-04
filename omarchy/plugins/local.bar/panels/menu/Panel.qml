import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Custom omarchy menu panel. The bar's omarchy button opens this dropdown
// instead of the stock full-screen menu (which SUPER+ESCAPE still summons).
//
// Content is WIRED TO THE LIVE omarchy default menu: the panel reads
//   $OMARCHY_PATH/default/omarchy/omarchy-menu.jsonc
//   ~/.config/omarchy/extensions/omarchy-menu.jsonc
// at runtime (watchChanges), so new items and features omarchy ships show up
// here automatically — no stale copy. Guards (when/checked) are evaluated in
// one bash batch; the apps provider uses shell.appLibrary and the fonts /
// power-profiles providers reuse the stock bash enumerations.
Panel {
  id: root
  moduleName: "omarchy.menu"

  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH") || ""
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string defaultMenuPath: omarchyPath + "/default/omarchy/omarchy-menu.jsonc"
  readonly property string userMenuPath: home + "/.config/omarchy/extensions/omarchy-menu.jsonc"

  // ---------------------------------------------------------- palette

  readonly property color ink: root.bar ? root.bar.barForeground : Color.foreground
  readonly property color dim: Qt.darker(ink, 1.45)
  readonly property color sumi: Qt.darker(ink, 1.55)
  readonly property color accent: Color.accent
  readonly property color rowHover: Qt.alpha(ink, 0.08)
  readonly property color rowCursor: Qt.alpha(ink, 0.16)

  // ---------------------------------------------------------- menu data

  property var defaultMenuItems: []
  property var userMenuItems: []
  property var items: ({})
  property var itemOrder: []
  property var whenResults: ({})
  property var checkedResults: ({})
  property string activeMenu: "root"
  property var navStack: []
  property int cursorIndex: 0
  property bool cursorActive: false
  property var providersLoaded: ({})

  readonly property var appLibrary: root.bar && root.bar.shell ? root.bar.shell.appLibrary : null

  // ---------------------------------------------------------- layout

  readonly property int rowHeight: Style.space(36)
  readonly property int rowSpacing: Style.space(2)

  // ---------------------------------------------------------- omni search

  property string searchFilter: ""

  // ------------------------------------------------------------------
  // JSONC -> normalized item map. Mirrors the stock MenuModel so the
  // on-disk authoring format (documented at the top of omarchy-menu.jsonc)
  // is understood identically.
  // ------------------------------------------------------------------

  function stripJsonc(raw) {
    return String(raw || "")
      .replace(/^\s*\/\/[^\n]*(\n|$)/gm, "")
      .replace(/,(\s*[}\]])/g, "$1")
  }

  function normalizeAliases(value) {
    if (Array.isArray(value)) return value.filter(function(v) { return v })
    if (typeof value === "string" && value) return [value]
    return []
  }

  function normalizeItem(id, raw) {
    var value = raw || {}
    var parent = value.parent
    if (parent === undefined)
      parent = id.indexOf(".") >= 0 ? id.split(".").slice(0, -1).join(".") : "root"
    if (id === "root") parent = ""
    var kind = value.action ? "action" : (value.target ? "link" : "menu")
    return {
      id: id,
      parent: parent,
      kind: kind,
      icon: value.icon || "",
      iconFont: value.iconFont || "",
      label: value.label || id,
      title: value.title || "",
      target: value.target || "",
      description: value.description || "",
      action: value.action || "",
      provider: value.provider || "",
      aliases: normalizeAliases(value.aliases),
      when: value.when || "",
      checked: value.checked || ""
    }
  }

  function parseMenuJsonc(raw) {
    var stripped = stripJsonc(raw)
    if (!stripped.trim()) return []
    var parsed
    try { parsed = JSON.parse(stripped) } catch (e) { return [] }
    if (typeof parsed !== "object" || parsed === null) return []
    var source = (parsed.items && typeof parsed.items === "object" && !Array.isArray(parsed.items))
      ? parsed.items : parsed
    var out = []
    for (var id in source) {
      var entry = source[id]
      if (!entry || typeof entry !== "object" || Array.isArray(entry)) continue
      out.push(normalizeItem(id, entry))
    }
    return out
  }

  function mergeMenuSources(defaultItems, userItems) {
    var nextItems = ({})
    var nextOrder = []
    var sources = [defaultItems || [], userItems || []]
    for (var s = 0; s < sources.length; s++) {
      var src = sources[s]
      for (var i = 0; i < src.length; i++) {
        var entry = src[i]
        if (!entry || !entry.id) continue
        if (!nextItems[entry.id]) nextOrder.push(entry.id)
        var prior = nextItems[entry.id] || {}
        var merged = {}
        for (var k in prior) merged[k] = prior[k]
        for (var k2 in entry) merged[k2] = entry[k2]
        merged.id = entry.id
        nextItems[entry.id] = merged
      }
    }
    if (!nextItems.root) {
      nextItems.root = { id: "root", parent: "", kind: "menu", icon: "", iconFont: "", label: "Go", title: "", target: "", description: "", aliases: [], when: "", checked: "", action: "", provider: "" }
      nextOrder.unshift("root")
    }
    for (var k3 = 0; k3 < nextOrder.length; k3++) nextItems[nextOrder[k3]].order = k3
    return { items: nextItems, itemOrder: nextOrder }
  }

  function item(id) {
    return root.items[id] || null
  }

  function childOf(entry, parentId) {
    if (parentId === "root") return entry.id !== "root"
    var current = entry
    var guard = 0
    while (current && current.parent && guard < 32) {
      if (current.parent === parentId) return true
      current = root.item(current.parent)
      guard += 1
    }
    return false
  }

  function isVisible(entry, depth) {
    if (!entry) return false
    if (entry.when && root.whenResults[entry.id] === false) return false
    if (entry.kind !== "menu" && entry.kind !== "link") return true
    if (entry.provider) return true
    var guard = depth || 0
    if (guard >= 32) return false
    var target = entry.kind === "link" ? entry.target : entry.id
    for (var i = 0; i < root.itemOrder.length; i++) {
      var child = root.item(root.itemOrder[i])
      if (child && child.parent === target && root.isVisible(child, guard + 1)) return true
    }
    return false
  }

  function labelFor(entry) {
    if (entry.checked && root.checkedResults[entry.id]) return entry.label + " ✓"
    return entry.label
  }

  // ------------------------------------------------------------- guards

  function evaluateGuards() {
    var script = ""
    var ids = Object.keys(root.items)
    for (var i = 0; i < ids.length; i++) {
      var entry = root.items[ids[i]]
      if (!entry) continue
      if (entry.when) script += "if { " + entry.when + "; } >/dev/null 2>&1; then echo " + ids[i] + ":w:1; else echo " + ids[i] + ":w:0; fi\n"
      if (entry.checked) script += "if { " + entry.checked + "; } >/dev/null 2>&1; then echo " + ids[i] + ":c:1; else echo " + ids[i] + ":c:0; fi\n"
    }
    if (!script) {
      root.whenResults = ({})
      root.checkedResults = ({})
      if (root.opened) root.rebuildDisplay()
      return
    }
    guardProc.collected = ""
    guardProc.command = ["bash", "-lc", script]
    guardProc.running = true
  }

  Process {
    id: guardProc
    property string collected: ""
    stdout: SplitParser {
      onRead: function(data) { guardProc.collected += data + "\n" }
    }
    onExited: {
      var nextWhen = ({})
      var nextChecked = ({})
      var lines = guardProc.collected.split("\n")
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (!line) continue
        var colon = line.lastIndexOf(":")
        if (colon < 0) continue
        var value = line.substring(colon + 1) === "1"
        var rest = line.substring(0, colon)
        var tagAt = rest.lastIndexOf(":")
        if (tagAt < 0) continue
        var id = rest.substring(0, tagAt)
        var tag = rest.substring(tagAt + 1)
        if (tag === "w") nextWhen[id] = value
        else if (tag === "c") nextChecked[id] = value
      }
      root.whenResults = nextWhen
      root.checkedResults = nextChecked
      if (root.opened) root.rebuildDisplay()
    }
  }

  // ------------------------------------------------------------ providers

  readonly property var providers: ({
    "fonts": {
      script: "current=$(omarchy-font-current 2>/dev/null); omarchy-font-list 2>/dev/null | while read -r f; do [[ -z $f ]] && continue; printf '%s\\t%s\\t%s\\n' \"$f\" \"$f\" \"$current\"; done",
      icon: "",
      actionFor: function(value) { return "omarchy-font-set " + Util.shellQuote(value) }
    },
    "power-profiles": {
      script: "current=$(powerprofilesctl get 2>/dev/null); omarchy-powerprofiles-list 2>/dev/null | while read -r p; do [[ -z $p ]] && continue; printf '%s\\t%s\\t%s\\n' \"$p\" \"$p\" \"$current\"; done",
      icon: "\udb81\udc0b",
      actionFor: function(value) { return "omarchy-powerprofiles-set autodetect " + Util.shellQuote(value) }
    }
  })

  function slugify(value) {
    return String(value || "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "item"
  }

  function mergeAppRows() {
    if (!root.appLibrary) return
    var rows = root.appLibrary.sortedEntries("")
    var appRows = []
    for (var j = 0; j < rows.length; j++) {
      var entry = rows[j].entry
      var appId = String(entry.id || "")
      if (!appId) continue
      var subtext = root.appLibrary.entrySubtext(entry)
      var aliases = subtext ? [subtext] : []
      try {
        if (entry.keywords && typeof entry.keywords.join === "function") aliases = aliases.concat(entry.keywords)
      } catch (e) { }
      appRows.push({
        id: "apps." + appId,
        parent: "apps",
        kind: "app",
        icon: "",
        iconFont: "",
        appIcon: String(entry.icon || ""),
        appId: appId,
        label: root.appLibrary.entryName(entry),
        title: "",
        target: "",
        description: subtext,
        action: "",
        provider: "",
        aliases: aliases,
        when: "",
        checked: "",
        order: 0
      })
    }
    root.swapRows(appRows, "apps")
  }

  function mergeProviderRows(rows, menuId, providerKey) {
    var spec = root.providers[providerKey]
    if (!spec) return
    var lines = String(rows || "").split("\n")
    var providerRows = []
    var takenIds = ({})
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (!line) continue
      var parts = line.split("\t")
      var label = parts[0] || ""
      var value = parts[1] || parts[0] || ""
      var current = parts[2] || ""
      if (!label) continue
      var rowId = menuId + "." + root.slugify(value)
      while (takenIds[rowId]) rowId += "-"
      takenIds[rowId] = true
      providerRows.push({
        id: rowId,
        parent: menuId,
        kind: "action",
        icon: (value === current) ? "✓" : (spec.icon || ""),
        label: label,
        title: "",
        target: "",
        description: "",
        action: spec.actionFor(value),
        provider: "",
        aliases: [],
        when: "",
        checked: "",
        order: 0
      })
    }
    root.swapRows(providerRows, menuId)
  }

  function swapRows(rows, menuId) {
    var nextItems = ({})
    var nextOrder = []
    for (var i = 0; i < root.itemOrder.length; i++) {
      var id = root.itemOrder[i]
      var existing = root.items[id]
      if (!existing || existing.providerMenu === menuId) continue
      nextItems[id] = existing
      nextOrder.push(id)
    }
    for (var j = 0; j < rows.length; j++) {
      var row = rows[j]
      if (!row || !row.id || nextItems[row.id]) continue
      row.providerMenu = menuId
      row.order = nextOrder.length
      nextItems[row.id] = row
      nextOrder.push(row.id)
    }
    root.items = nextItems
    root.itemOrder = nextOrder
    if (root.opened) root.rebuildDisplay()
  }

  function startProviderForMenu(id) {
    var entry = root.item(id)
    if (!entry || !entry.provider || root.providersLoaded[id]) return
    if (entry.provider === "apps") {
      root.providersLoaded[id] = true
      root.mergeAppRows()
      return
    }
    var spec = root.providers[entry.provider]
    if (!spec) return
    root.providersLoaded[id] = true
    providerProc.menuId = id
    providerProc.providerKey = entry.provider
    providerProc.collected = ""
    providerProc.command = ["bash", "-lc", spec.script]
    providerProc.running = true
  }

  function loadProviderForMenu(id) {
    var entry = root.item(id)
    if (!entry || !entry.provider || root.providersLoaded[id]) return
    if (entry.provider === "apps") { root.startProviderForMenu(id); return }
    if (providerProc.running) return
    root.startProviderForMenu(id)
  }

  Process {
    id: providerProc
    property string menuId: ""
    property string providerKey: ""
    property string collected: ""
    stdout: SplitParser {
      onRead: function(data) { providerProc.collected += data + "\n" }
    }
    onExited: {
      root.mergeProviderRows(providerProc.collected, providerProc.menuId, providerProc.providerKey)
    }
  }

  // ---------------------------------------------------------------- model

  ListModel { id: displayModel }

  function currentMenuLabel() {
    var entry = root.item(root.activeMenu)
    if (!entry || root.activeMenu === "root") return "Menu"
    return entry.label
  }

  function currentMenuPath() {
    if (root.activeMenu === "root") return "OMARCHY"
    var labels = []
    var current = root.item(root.activeMenu)
    var guard = 0
    while (current && current.id !== "root" && guard < 32) {
      labels.unshift(current.label)
      current = root.item(current.parent)
      guard += 1
    }
    return labels.join("  ›  ").toUpperCase()
  }

  function rebuildDisplay() {
    displayModel.clear()
    var active = root.item(root.activeMenu) ? root.activeMenu : "root"
    root.activeMenu = active
    var filter = (root.searchFilter || "").toLowerCase()
    for (var i = 0; i < root.itemOrder.length; i++) {
      var entry = root.item(root.itemOrder[i])
      if (!entry || entry.parent !== active) continue
      if (!root.isVisible(entry)) continue
      if (filter && entry.label.toLowerCase().indexOf(filter) < 0 && (entry.description || "").toLowerCase().indexOf(filter) < 0) continue
      displayModel.append({
        itemId: entry.id,
        kind: entry.kind,
        icon: entry.icon,
        iconFont: entry.iconFont || "",
        appIcon: entry.appIcon || "",
        appId: entry.appId || "",
        label: root.labelFor(entry),
        action: entry.action || "",
        target: entry.kind === "link" ? (entry.target || entry.id) : entry.id,
        isSubmenu: entry.kind === "menu" || entry.kind === "link"
      })
    }
    if (displayModel.count === 0) cursorIndex = 0
    else if (cursorIndex >= displayModel.count) cursorIndex = displayModel.count - 1
    else if (cursorIndex < 0) cursorIndex = 0
  }

  function rebuildItemsFromSources() {
    var merged = root.mergeMenuSources(root.defaultMenuItems, root.userMenuItems)
    root.items = merged.items
    root.itemOrder = merged.itemOrder
    root.providersLoaded = ({})
    root.evaluateGuards()
  }

  // ------------------------------------------------------------- actions

  function runAction(command) {
    if (!command) return
    Util.execDetached(command)
    root.close()
  }

  function activateIndex(index) {
    if (index < 0 || index >= displayModel.count) return
    var row = displayModel.get(index)
    if (row.kind === "app") {
      if (root.appLibrary) {
        root.appLibrary.launch(row.appId, row.label)
        root.close()
      }
      return
    }
    if (row.isSubmenu) {
      root.navStack = root.navStack.concat([root.activeMenu])
      root.setActiveMenu(row.target, false)
      return
    }
    root.runAction(row.action)
  }

  function setActiveMenu(id, pushHistory) {
    if (!root.item(id)) id = "root"
    root.activeMenu = id
    root.cursorIndex = 0
    root.cursorActive = true
    root.rebuildDisplay()
    root.loadProviderForMenu(id)
  }

  function goBack() {
    if (root.activeMenu === "root") { root.close(); return }
    if (root.navStack.length > 0) {
      var previous = root.navStack[root.navStack.length - 1]
      root.navStack = root.navStack.slice(0, root.navStack.length - 1)
      root.setActiveMenu(previous, false)
      return
    }
    var active = root.item(root.activeMenu)
    root.setActiveMenu((active && active.parent) ? active.parent : "root", false)
  }

    function moveCursor(dy) {
      if (displayModel.count === 0) return
      if (!root.cursorActive) {
        root.cursorActive = true
        root.cursorIndex = 0
        return
      }
      root.cursorIndex = (root.cursorIndex + dy + displayModel.count) % displayModel.count
    }

  // ----------------------------------------------------------- lifecycle

   onOpenedChanged: {
     if (opened) {
       cursorActive = false
       cursorIndex = 0
       searchFilter = ""
       if (!rowsLoaded) rebuildItemsFromSources()
       activeMenu = "root"
       navStack = []
       rebuildDisplay()
       loadProviderForMenu("root")
       if (root.appLibrary) root.appLibrary.refreshIcons()
     }
   }

  property bool rowsLoaded: false

  FileView {
    id: defaultMenuFile
    path: root.defaultMenuPath
    watchChanges: true
    printErrors: false
    onLoaded: {
      root.defaultMenuItems = root.parseMenuJsonc(text())
      root.rowsLoaded = true
      root.rebuildItemsFromSources()
    }
    onFileChanged: reload()
  }

  FileView {
    id: userMenuFile
    path: root.userMenuPath
    watchChanges: true
    printErrors: false
    onLoaded: { root.userMenuItems = root.parseMenuJsonc(text()); root.rebuildItemsFromSources() }
    onLoadFailed: { root.userMenuItems = []; root.rebuildItemsFromSources() }
    onFileChanged: reload()
  }

  // ------------------------------------------------------------ bar pill

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Item {
    id: button
    anchors.fill: parent
    implicitWidth: Math.max(12, glyph.implicitWidth + Style.spaceReal(6) * 2)
    implicitHeight: root.bar ? root.bar.barSize : Style.bar.sizeHorizontal

    Rectangle {
      anchors.fill: parent
      color: "#ff0000"
    }

    Text {
      id: glyph
      anchors.centerIn: parent
      text: "\uf011"
      font.family: "monospace"
      font.pixelSize: Style.bar.iconFont - 1
      color: "#00ff00"
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
        else root.toggle()
      }
    }

    TextMetrics {
      id: glyphMetrics
      text: glyph.text
      font: glyph.font
    }

    Timer {
      interval: 2000
      running: true
      repeat: false
      onTriggered: {
        console.log("MENUDEBUG glyph.impW=" + glyph.implicitWidth + " impH=" + glyph.implicitHeight +
          " width=" + glyph.width + " height=" + glyph.height +
          " pixelSize=" + glyph.font.pixelSize +
          " tm.width=" + glyphMetrics.width + " tm.height=" + glyphMetrics.height +
          " tm.advance=" + glyphMetrics.advance + " button.h=" + button.height +
          " root.h=" + root.height + " barSize=" + (root.bar ? root.bar.barSize : "none"))
      }
    }
  }

  // ------------------------------------------------------------- dropdown

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    padding: Style.space(12)
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) {
          if (dx < 0) root.goBack()
          else if (root.cursorActive) root.activateIndex(root.cursorIndex)
          return
        }
        root.moveCursor(dy)
      }
      onActivateRequested: if (root.cursorActive) root.activateIndex(root.cursorIndex)
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        // ---------- Hero: omarchy mark · Menu ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(heroMark.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroMark
            text: "\ue900"
            color: root.ink
            font.family: "omarchy"
            font.pixelSize: Style.font.displayLarge
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroMark.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: root.currentMenuLabel()
              color: root.ink
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.heading
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              text: root.currentMenuPath()
              color: root.dim
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        // ---------- Back / home ----------
        Button {
          id: backButton
          visible: root.activeMenu !== "root"
          width: parent.width
          iconText: "󰁍"
          iconSize: Style.font.body
          text: "Back"
          fontSize: Style.font.bodySmall
          foreground: root.dim
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.space(5)
          bordered: false
          leftAlign: true
          onClicked: root.goBack()
        }

        PanelSeparator {
          foreground: root.ink
          strength: 0.12
        }

         // ---------- Search ----------
         Item {
           width: parent.width
           implicitHeight: Style.space(36)

           Text {
             id: searchIcon
             text: "󰄭"
             color: root.dim
             font.family: Style.font.family
             font.pixelSize: Style.font.body
             anchors.left: parent.left
             anchors.verticalCenter: parent.verticalCenter
             width: Style.space(24)
             horizontalAlignment: Text.AlignHCenter
           }

           TextField {
             id: searchField
             anchors.left: searchIcon.right
             anchors.leftMargin: Style.space(6)
             anchors.right: parent.right
             anchors.verticalCenter: parent.verticalCenter
             height: Style.space(28)
             text: root.searchFilter || ""
             onTextChanged: root.searchFilter = text
             placeholderText: "Search..."
             placeholderTextColor: root.dim
             color: root.ink
             font.family: root.bar ? root.bar.fontFamily : Style.font.family
             font.pixelSize: Style.font.body
             font.weight: Font.Medium
             selectByMouse: true
             clearButtonEnabled: true
             leftPadding: Style.space(2)
             rightPadding: Style.space(2)
             background: Rectangle {
               color: root.rowHover
               radius: Style.cornerRadius
               border.width: 1
               border.color: root.dim
             }
           }
         }

         PanelSeparator {
           foreground: root.ink
           strength: 0.12
         }

         // ---------- Rows (clean list) ----------
         ListView {
           id: resultList
           width: parent.width
           height: Math.min(displayModel.count * (root.rowHeight + root.rowSpacing), resultList.maxListHeight)
           model: displayModel
           clip: true
           spacing: Style.space(2)
           boundsBehavior: Flickable.StopAtBounds
           interactive: displayModel.count * (root.rowHeight + root.rowSpacing) > resultList.maxListHeight

           readonly property int maxListHeight: {
             var avail = panel.availableCardHeight - Style.space(130)
             return Math.max(Style.space(120), avail)
           }

           delegate: Rectangle {
             id: row
             required property int index
             required property string itemId
             required property string kind
             required property string icon
             required property string iconFont
             required property string appIcon
             required property string appId
             required property string label
             required property bool isSubmenu

             readonly property bool isApp: kind === "app"
             readonly property bool hasCursor: root.cursorActive && row.index === root.cursorIndex

             width: ListView.view.width
             height: root.rowHeight
             radius: Style.cornerRadius
             color: hasCursor ? root.rowCursor : (mouseArea.containsMouse ? root.rowHover : "transparent")
             Behavior on color { ColorAnimation { duration: 90 } }

             Text {
               id: glyph
               visible: !row.isApp
               text: row.icon
               color: hasCursor ? root.ink : root.dim
               font.family: row.iconFont.length > 0 ? row.iconFont : (root.bar ? root.bar.fontFamily : Style.font.family)
               font.pixelSize: Style.font.body
               width: Style.space(28)
               horizontalAlignment: Text.AlignHCenter
               anchors.left: parent.left
               anchors.leftMargin: Style.space(6)
               anchors.verticalCenter: parent.verticalCenter
             }

             Image {
               id: appImage
               visible: row.isApp
               width: Style.font.body
               height: Style.font.body
               fillMode: Image.PreserveAspectFit
               sourceSize.width: width * Screen.devicePixelRatio
               sourceSize.height: height * Screen.devicePixelRatio
               source: row.isApp && root.appLibrary ? root.appLibrary.iconSource(row.appIcon) : ""
               asynchronous: true
               anchors.left: parent.left
               anchors.leftMargin: Style.space(6)
               anchors.verticalCenter: parent.verticalCenter
             }

             Text {
               id: labelText
               anchors.left: row.isApp ? appImage.right : glyph.right
               anchors.leftMargin: Style.space(6)
               anchors.right: chevron.left
               anchors.rightMargin: Style.space(6)
               anchors.verticalCenter: parent.verticalCenter
               text: row.label
               color: hasCursor ? root.ink : root.dim
               font.family: root.bar ? root.bar.fontFamily : Style.font.family
               font.pixelSize: Style.font.body
               font.weight: Font.Medium
               elide: Text.ElideRight
             }

             Text {
               id: chevron
               text: row.isSubmenu ? "›" : ""
               color: hasCursor ? root.ink : root.dim
               opacity: row.isSubmenu ? 0.5 : 0
               font.family: root.bar ? root.bar.fontFamily : Style.font.family
               font.pixelSize: Style.font.heading
               font.weight: Font.Normal
               anchors.right: parent.right
               anchors.rightMargin: Style.space(6)
               anchors.verticalCenter: parent.verticalCenter
             }

             MouseArea {
               id: mouseArea
               anchors.fill: parent
               hoverEnabled: true
               cursorShape: Qt.PointingHandCursor
               onEntered: { root.cursorActive = true; root.cursorIndex = row.index }
               onClicked: root.activateIndex(row.index)
             }
           }
         }

         // ---------- empty state ----------
         Item {
           width: parent.width
           height: Style.space(64)
           visible: displayModel.count === 0

          Column {
            anchors.centerIn: parent
            spacing: Style.space(6)

            Text {
              text: "󰈉"
              color: root.dim
              opacity: 0.6
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.display
              horizontalAlignment: Text.AlignHCenter
              width: Style.space(240)
            }

            Text {
              text: "Nothing here"
              color: root.dim
              opacity: 0.6
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
              width: Style.space(240)
            }
          }
        }
      }
    }
  }
}

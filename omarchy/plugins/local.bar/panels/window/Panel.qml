import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Bar active-window pill that opens a panel with the focused window's full
// information: a big app icon + big name hero, and the window/app/workspace/
// size/state readout. No quotes — just the open window's info.
Panel {
  id: root
  moduleName: "window-info"
  ipcTarget: "window-info"

  readonly property var toplevel: Hyprland.activeToplevel

  readonly property int barSize: root.bar ? root.bar.barSize : Style.bar.sizeHorizontal

  // Reactive snapshot of the active toplevel's IPC data (class/title/pid/...).
  // lastIpcObject is only populated by refreshToplevels(), so we re-query it on
  // every focus change — otherwise windows opened after shell start show Desktop.
  // Fallback: quickshell's Hyprland module only fires the activewindow event on
  // a focus *change*, so after a shell restart activeToplevel stays null until
  // the user switches windows. fallbackInfo is seeded from `hyprctl activewindow`
  // at startup (see seedProc) so the pill resolves correctly right away.
  property var fallbackInfo: null
  readonly property var activeInfo: (root.toplevel && root.toplevel.lastIpcObject)
    ? root.toplevel.lastIpcObject
    : root.fallbackInfo

  // Foreground process running inside a terminal window (foot, alacritty, ...),
  // resolved asynchronously by winProc.sh from the window's pid.
  property string termForeground: ""
  property int termSeq: 0
  property int lastWinProcSeq: 0
  readonly property string procScript: Quickshell.env("HOME") + "/.config/omarchy/scripts/winproc.sh"

  function isTerminalApp(id) {
    var terms = ["foot", "alacritty", "kitty", "ghostty", "wezterm", "konsole",
                 "gnome-terminal", "gnome-console", "org.gnome.terminal",
                 "org.gnome.console", "org.omarchy.terminal", "org.omarchy.bash"]
    for (var t of terms) {
      if (id.includes(t)) return true
    }
    return false
  }

  function toplevelPid() {
    var info = root.activeInfo || {}
    var pid = (info && info.pid) ? Number(info.pid) : 0
    return pid
  }

  function matchProcess(proc) {
    var lower = proc.toLowerCase()
    if (!lower) return null
    for (var key in appMap) {
      if (key.toLowerCase() === lower) return appMap[key]
    }
    return null
  }

  function refreshToplevelData() {
    if (root.toplevel) Hyprland.refreshToplevels()
  }

  function resolveTermForeground() {
    root.termSeq++
    var seq = root.termSeq
    var info = root.activeInfo || {}
    var id = info["class"] ? String(info["class"]).toLowerCase() : ""
    if (!root.isTerminalApp(id)) {
      root.termForeground = ""
      return
    }
    var pid = root.toplevelPid()
    if (!pid) {
      root.termForeground = ""
      return
    }
    root.lastWinProcSeq = seq
    winProc.command = ["bash", root.procScript, String(pid)]
    winProc.running = true
  }

  onToplevelChanged: {
    root.refreshToplevelData()
    root.resolveTermForeground()
  }
  onActiveInfoChanged: root.resolveTermForeground()
  Component.onCompleted: {
    root.refreshToplevelData()
    root.resolveTermForeground()
    seedProc.running = true
  }

  Process {
    id: winProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var out = text.trim()
        if (root.lastWinProcSeq !== root.termSeq) return
        root.termForeground = out === "" ? "" : out.toLowerCase()
      }
    }
  }

  // Seeds fallbackInfo with the currently active window so the pill resolves
  // right after a shell restart (see activeInfo above).
  Process {
    id: seedProc
    command: ["hyprctl", "-j", "activewindow"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var out = text.trim()
        if (!out || out === "[]") {
          root.fallbackInfo = null
          return
        }
        try {
          var obj = JSON.parse(out)
          root.fallbackInfo = (obj && obj.class) ? obj : null
        } catch (e) {
          root.fallbackInfo = null
        }
      }
    }
  }



  // ---------------------------------------------------------------- app map

  readonly property var appMap: ({
    // Development & Version Control
    "vscode": ["󰨞", "VS Code"],
    "code": ["󰨞", "VS Code"],
    "neovim": ["", "Neovim"],
    "nvim": ["", "Neovim"],
    "github": ["󰊤", "GitHub"],
    "git": ["󰊢", "Git"],
    "docker": ["", "Docker"],
    "postman": ["󱓎", "Postman"],
    "bitbucket": ["󰊭", "Bitbucket"],

    // Terminal Emulators
    "alacritty": ["", "Alacritty"],
    "kitty": ["󰄛", "Kitty"],
    "foot": ["󰞷", "Foot"],
    "wezterm": ["󰞷", "WezTerm"],
    "konsole": ["󰞷", "Konsole"],
    "st": ["", "Simple Terminal"],

    // Linux Distributions
    "tux": ["", "Kernel"],
    "nixos": ["", "NixOS"],
    "ubuntu": ["", "Ubuntu"],
    "fedora": ["", "Fedora"],
    "debian": ["", "Debian"],
    "gentoo": ["", "Gentoo"],

    // GNOME (full appId)
    "org.gnome.nautilus": ["󰉋", "Files"],
    "org.gnome.console": ["󰞷", "Console"],
    "org.gnome.terminal": ["", "Terminal"],
    "org.gnome.settings": ["󰒓", "Settings"],
    "org.gnome.calculator": ["󰪚", "Calculator"],
    "org.gnome.software": ["󰀻", "Software"],
    "org.gnome.systemmonitor": ["󰓅", "System Monitor"],
    "org.gnome.baobab": ["󰓅", "Disk Usage"],
    "org.gnome.characters": ["󰬈", "Characters"],
    "org.gnome.font-viewer": ["󰬈", "Fonts"],
    "org.gnome.logs": ["󰘙", "Logs"],
    "org.gnome.gedit": ["󰷈", "Text Editor"],

    // GNOME apps
    "nautilus": ["󰉋", "Files"],
    "gnome-console": ["󰞷", "Console"],
    "gnome-settings": ["󰒓", "Settings"],
    "gnome-tweaks": ["󰒓", "Tweaks"],
    "gnome-software": ["󰀻", "Software"],
    "gnome-system-monitor": ["󰓅", "System Monitor"],
    "gnome-disks": ["󰋊", "Disks"],
    "gnome-calculator": ["󰪚", "Calculator"],
    "gnome-calendar": ["󰸗", "Calendar"],
    "gnome-clocks": ["󰥔", "Clocks"],
    "gnome-weather": ["󰖕", "Weather"],
    "gnome-maps": ["󰉙", "Maps"],
    "gnome-text-editor": ["󰷈", "Text Editor"],
    "gnome-music": ["󰝚", "Music"],
    "gnome-photos": ["󰄄", "Photos"],
    "gnome-videos": ["󰿎", "Videos"],
    "gnome-contacts": ["󰻙", "Contacts"],
    "gnome-builder": ["󰨞", "Builder"],
    "gnome-boxes": ["󰢹", "Boxes"],
    "gnome-logs": ["󰘙", "Logs"],
    "epiphany": ["󰖟", "Web (Epiphany)"],
    "geary": ["󰇮", "Geary Mail"],
    "polari": ["󰒱", "Polari IRC"],
    "fragments": ["󰇚", "Fragments"],

    // Omarchy & Modern Linux
    "org.omarchy.bash": ["󰣇", "System-info"],
    "org.omarchy.btop": ["󰓅", "Btop-Monitor"],
    "hyprland": ["", "Hyprland"],
    "ghostty": ["󰊠", "Ghostty Terminal"],
    "lazygit": ["󰊢", "LazyGit"],
    "lazydocker": ["", "LazyDocker"],
    "btop": ["󰓅", "Btop-Monitor"],
    "nvtop": ["", "GPU Monitor"],
    "basecamp": ["󰭹", "Basecamp"],
    "hey": ["󰇮", "HEY Mail"],
    "aether": ["󰨚", "Aether"],
    "org.omarchy.terminal": ["󰣇", "Omarchy"],

    // Productivity & Creative
    "notion": ["󰇈", "Notion"],
    "obsidian": ["󱓧", "Obsidian"],
    "trello": ["󰓓", "Trello"],
    "todoist": ["󰄱", "Todoist"],
    "slack": ["󰒱", "Slack"],
    "teams": ["󰊻", "MS Teams"],
    "zoom": ["󰕧", "Zoom"],
    "figma": ["", "Figma"],
    "typora": ["󰷈", "Typora"],
    "libreoffice": ["󰈙", "LibreOffice"],
    "kdenlive": ["", "Kdenlive"],
    "inkscape": ["", "Inkscape"],
    "obs": ["", "OBS Studio"],

    // Gaming & Multimedia
    "steam": ["󰓓", "Steam"],
    "lutris": ["", "Lutris"],
    "heroic": ["󰊗", "Heroic Games"],
    "bottles": ["󰏖", "Bottles"],
    "itchio": ["󰪚", "Itch.io"],
    "gog": ["󰓓", "GOG Galaxy"],
    "retroarch": ["󰓓", "RetroArch"],
    "minigalaxy": ["󰀻", "Minigalaxy"],
    "spotify": ["", "Spotify"],
    "mangohud": ["󰓅", "MangoHud"],
    "goverlay": ["󰒓", "GOverlay"],
    "corectrl": ["󰢮", "CoreCtrl"],
    "piper": ["󰍽", "Piper Mouse"],
    "gamemode": ["󰓅", "Feral GameMode"],
    "geforce-now": ["󰊗", "GeForce Now"],
    "xbox-cloud": ["󰓓", "Xbox Cloud"],
    "moonlight": ["󰖟", "Moonlight Stream"],

    // Google Ecosystem
    "google": ["", "Google"],
    "chrome": ["", "Chrome"],
    "google-chrome": ["", "Chrome"],
    "gmail": ["󰊫", "Gmail"],
    "calendar": ["󰸗", "Google Calendar"],
    "sheets": ["󰈛", "Google Sheets"],
    "docs": ["󰈙", "Google Docs"],
    "slides": ["󰈧", "Google Slides"],
    "meet": ["󰕧", "Google Meet"],
    "keep": ["󰠮", "Google Keep"],
    "photos": ["󰄄", "Google Photos"],
    "maps": ["󰉙", "Google Maps"],
    "youtube": ["󰗃", "YouTube"],

    // AI & LLM
    "chatgpt": ["󰭻", "ChatGPT (OpenAI)"],
    "OpenCode": ["󰚩", "OpenCode"],
    "gemini": ["󰚩", "Google Gemini"],
    "perplexity": ["󰖟", "Perplexity AI"],
    "deepseek": ["󰚩", "DeepSeek"],
    "grok": ["󰚩", "Grok (xAI)"],
    "mistral": ["󰚩", "Mistral AI"],
    "ollama": ["󱓞", "Ollama (Local)"],
    "lm-studio": ["󰚩", "LM Studio"],
    "cursor": ["󰨞", "Cursor IDE"],
    "copilot": ["󰊤", "GitHub Copilot"],
    "windsurf": ["󰖟", "Windsurf"],
    "aider": ["", "Aider CLI"],
    "lovable": ["󱓎", "Lovable AI"],

    // Browsers & Privacy Tools
    "firefox": ["", "Firefox"],
    "brave": ["", "Brave"],
    "chromium": ["", "Chromium"],
    "librewolf": ["󰈹", "LibreWolf"],
    "codium": ["󰨞", "VSCodium"],
    "mullvad-browser": ["󰖟", "Mullvad Browser"],
    "vivaldi": ["󰖟", "Vivaldi"],
    "thorium": ["󰖟", "Thorium"],
    "ladybird": ["󰖟", "Ladybird"],
    "signal": ["󰭹", "Signal"],
    "simplex": ["󰭻", "SimpleX Chat"],
    "session": ["󰚩", "Session"],
    "threema": ["󰒱", "Threema"],
    "element": ["󰒱", "Element (Matrix)"],
    "discord-canary": ["󰙯", "Discord Canary"],
    "bitwarden": ["󰞀", "Bitwarden"],
    "keepassxc": ["󰞀", "KeePassXC"],
    "1password": ["󰢁", "1Password"],
    "proton-mail": ["󰇮", "Proton Mail"],
    "tuta": ["󰇮", "Tuta Mail"],
    "duckduckgo": ["󰇥", "DuckDuckGo"],
    "veracrypt": ["󰞁", "VeraCrypt"],
    "mullvad": ["󰖂", "Mullvad VPN"],
    "proton-vpn": ["󰖂", "Proton VPN"],
    "ivpn": ["󰖂", "IVPN"],
    "tailscale": ["󰖂", "Tailscale"],
    "dropbox": ["󰇖", "Dropbox"],

    // Social
    "ayugram-desktop": ["", "AyuGram"],
    "telegram-desktop": ["", "Telegram"],
    "telegram": ["", "Telegram"],
    "discord": ["", "Discord"],
    "vesktop": ["", "Vesktop"],
    "whatsapp": ["", "WhatsApp"],
    "reddit": ["", "Reddit"],
    "twitter": ["", "Twitter"],
    "x.com": ["", "X"],
    "facebook": ["", "Facebook"],
    "instagram": ["", "Instagram"],
    "linkedin": ["", "LinkedIn"],
    "pinterest": ["", "Pinterest"],
    "tumblr": ["", "Tumblr"],
    "tiktok": ["", "TikTok"],
    "org.signal.Signal": ["󰭹", "Signal"],
    "signal-desktop": ["󰭹", "Signal"],

    // Graphics & Media
    "flameshot": ["󰄀", "Flameshot"],
    "gimp": ["", "GIMP"],
    "canva": ["", "Canva"],
    "mpv": ["", "Media-Player"],
    "vlc": ["󰕼", "VLC"],
    "Stremio.stremio": ["󱖏", "Stremio"],
    "com.stremio.Stremio": ["󱖏", "Stremio"],
    "stremio": ["󱖏", "Stremio"],
    "com.stremio": ["󱖏", "Stremio"],
    "com.stremio.Service": ["󱑫", "Stremio Service"],

    // System & Utilities
    "pavucontrol": ["󰓃", "Volume Control"],
    "org.kde.dolphin": ["", "Dolphin"],
    "dolphin": ["", "Dolphin"],
    "thunar": ["󰉋", "Thunar"],
    "pcmanfm": ["󰉋", "PCManFM"],
    "calculator": ["", "Calculator"],
    "nwg-look": ["󰏘", "Nwg-look"],
    "imv": ["", "Imv"],
    "localsend": ["", "LocalSend"],
    "xed": ["󰷈", "Text-Editor"],
    "fdm": ["", "FDM"],
    "qbittorrent": ["", "Torrent"],
    "windscribe": ["", "Windscribe"],
    "org.rncbc.qpwgraph": ["󰺢", "Qpwgraph"]
  })

  readonly property var siteMap: ({
    "youtube":    ["󰗃", "YouTube"],
    "stremio":    ["󱖏", "Stremio"],
    "netflix":    ["󰝆", "Netflix"],
    "prime video":["󰐋", "Prime Video"],
    "disney+":    ["󰇵", "Disney+"],
    "crunchyroll":["󰴌", "Crunchyroll"],
    "twitch":     ["", "Twitch"],
    "github":     ["󰊤", "GitHub"],
    "gitlab":     ["󰊢", "GitLab"],
    "reddit":     ["", "Reddit"],
    "chatgpt":    ["󰭻", "ChatGPT"],
    "OpenCode":   ["󰚩", "Opencode"],
    "perplexity": ["󰖟", "Perplexity"],
    "x.com":      ["", "X"],
    "twitter":    ["", "X"],
    "whatsapp":   ["", "WhatsApp"],
    "telegram":   ["", "Telegram"],
    "discord":    ["", "Discord"],
    "spotify":    ["", "Spotify"],
    "notion":     ["󰇈", "Notion"],
    "figma":      ["", "Figma"],
    "slack":      ["󰒱", "Slack"],
    "gmail":      ["󰊫", "Gmail"],
    "meet":       ["󰕧", "Google Meet"],
    "maps":       ["󰉙", "Google Maps"],
    "drive":      ["󰋊", "Google Drive"]
  })

  function getBrowserIcon(id) {
    if (id.includes("firefox")) return ""
    if (id.includes("brave")) return ""
    if (id.includes("chromium")) return ""
    if (id.includes("chrome")) return ""
    if (id.includes("librewolf")) return "󰈹"
    if (id.includes("vivaldi")) return "󰖟"
    if (id.includes("thorium")) return "󰖟"
    return null
  }

  function getBrowserName(id) {
    if (id.includes("firefox")) return "Firefox"
    if (id.includes("brave")) return "Brave"
    if (id.includes("chromium")) return "Chromium"
    if (id.includes("chrome")) return "Chrome"
    if (id.includes("librewolf")) return "LibreWolf"
    if (id.includes("vivaldi")) return "Vivaldi"
    if (id.includes("thorium")) return "Thorium"
    return null
  }

  function isBrowser(id) {
    let browsers = ["firefox", "chrome", "chromium", "brave", "librewolf", "vivaldi", "thorium"]
    for (let b of browsers) {
      if (id.includes(b)) return true
    }
    return false
  }

  function matchSite(lowerTitle) {
    for (let key in siteMap) {
      if (lowerTitle.includes(key)) return siteMap[key]
    }
    return null
  }

  function cleanBrowserTitle(rawTitle, browserName) {
    let suffixes = [" - Firefox", " - Brave", " - Google Chrome", " - Chromium", " - LibreWolf", " - Vivaldi", " - Thorium"]
    let result = rawTitle
    for (let s of suffixes) {
      let idx = result.lastIndexOf(s)
      if (idx > 0) { result = result.substring(0, idx).trim(); break }
    }
    result = result.replace(/^\(\d+\)\s*/, "")
    return result
  }

  function getInfo(info, termProc, rawTitle) {
    if (!info) return ["󱂬", "Desktop"]

    let appId = info["class"] ? String(info["class"]) : ""
    if (!appId) return ["󱂬", "Desktop"]

    let id = appId.toLowerCase()
    rawTitle = rawTitle || ""
    let lowerTitle = rawTitle.toLowerCase()

    // Browser tab detection
    if (isBrowser(id)) {
      let brIcon = getBrowserIcon(id)
      let brName = getBrowserName(id)
      let site = matchSite(lowerTitle)
      let cleaned = cleanBrowserTitle(rawTitle, brName)

      if (site) {
        let siteName = site[1]
        let title = rawTitle
        let browserSuffixes = [" - Firefox", " - Brave", " - Google Chrome", " - Chromium", " - LibreWolf", " - Vivaldi", " - Thorium"]
        for (let s of browserSuffixes) {
          let idx = title.lastIndexOf(s)
          if (idx > 0) { title = title.substring(0, idx).trim(); break }
        }
        title = title.replace(/^\(\d+\)\s*/, "")

        let siteSuffixes = [" - " + siteName, " · " + siteName, " | " + siteName, " — " + siteName]
        for (let suffix of siteSuffixes) {
          if (title.endsWith(suffix)) {
            title = title.substring(0, title.length - suffix.length).trim()
            break
          }
        }

        if (!title || title.toLowerCase() === siteName.toLowerCase())
          return [site[0], siteName]

        return [site[0], siteName + " | " + title]
      }

      if (cleaned && cleaned.length > 0 && cleaned.length < 50) {
        return [brIcon, brName + ": " + cleaned]
      }

      return [brIcon, brName]
    }

    // Stremio standalone (not in browser)
    if (id.includes("stremio")) {
      return ["󱖏", "Stremio"]
    }

    // Terminal: show the app running inside (opencode, nvim, btop, ...)
    if (root.isTerminalApp(id)) {
      let inner = root.matchProcess(termProc)
      if (inner) return inner
    }

    // App map lookup
    for (let key in appMap) {
      if (id.includes(key))
        return appMap[key]
    }

    let parts = id.split(".")
    let name = parts[parts.length - 1]
    name = name.charAt(0).toUpperCase() + name.slice(1)
    return ["󰍹", name]
  }

  // ------------------------------------------------------- window readout

  readonly property var win: {
    var info = root.activeInfo
    if (!info) return null
    var ws = root.toplevel ? root.toplevel.workspace
      : (info.workspace ? { name: info.workspace.name, id: info.workspace.id } : null)
    var size = (info.size && info.size.w && info.size.h)
      ? String(info.size.w) + " × " + String(info.size.h) : ""
    var states = []
    if (info.fullscreen) states.push("Fullscreen")
    if (info.floating !== undefined) states.push(info.floating ? "Floating" : "Tiled")
    if (states.length === 0) states.push("Normal")
    return {
      appId: String(info["class"] || "—"),
      title: String(root.toplevel ? root.toplevel.title : (info["title"] || "")),
      workspace: ws ? (String(ws.name) || ("Workspace " + ws.id)) : "",
      size: size,
      state: states.join(" · "),
      pid: info.pid ? String(info.pid) : ""
    }
  }

  readonly property var details: [
    { key: "APP", value: root.win ? root.win.appId : "" },
    { key: "PROCESS", value: root.win ? root.win.pid : "" },
    { key: "SIZE", value: root.win ? root.win.size : "" },
    { key: "WORKSPACE", value: root.win ? root.win.workspace : "" },
    { key: "STATE", value: root.win ? root.win.state : "" }
  ]

  // ------------------------------------------------------------- visibility

  readonly property var focusedWs: Hyprland.focusedWorkspace

  function mpvAppIdOf(t) {
    if (!t) return ""
    var appId = t.wayland ? String(t.wayland.appId || "") : ""
    if (!appId && t.lastIpcObject) appId = String(t.lastIpcObject["class"] || "")
    return appId.toLowerCase()
  }

  function isMpvToplevel(t) {
    return root.mpvAppIdOf(t).indexOf("mpv") !== -1
  }

  function wsToplevels() {
    return root.focusedWs && root.focusedWs.toplevels
      ? root.focusedWs.toplevels.values
      : []
  }

  function workspaceAllMpv() {
    var vals = root.wsToplevels()
    if (vals.length === 0) return false
    for (var i = 0; i < vals.length; i++) {
      if (!root.isMpvToplevel(vals[i])) return false
    }
    return true
  }

  readonly property bool workspaceEmpty: root.wsToplevels().length === 0
  readonly property bool hideOnMpv: root.isMpvToplevel(Hyprland.activeToplevel) || root.workspaceAllMpv()

  visible: !root.workspaceEmpty && !root.hideOnMpv

  // ---------------------------------------------------- bar pill (eliding)

  function sceneX(item) {
    var x = item.x
    var p = item.parent
    while (p) {
      x += p.x
      p = p.parent
    }
    return x
  }

  function centerLeftEdge() {
    var bar = root.bar
    if (!bar || !bar.moduleSlots) return -1
    var slots = bar.moduleSlots
    var left = -1
    for (var i = 0; i < slots.length; i++) {
      var s = slots[i]
      if (s && s.region === "center" && s.visible === true && s.width > 0) {
        var x = root.sceneX(s)
        if (left < 0 || x < left) left = x
      }
    }
    return left
  }

  function mySlotX() {
    var bar = root.bar
    if (!bar || !bar.moduleSlots) return 0
    var slots = bar.moduleSlots
    for (var i = 0; i < slots.length; i++) {
      var s = slots[i]
      if (s && s.activeItem === root) return root.sceneX(s)
    }
    return 0
  }

  readonly property int maxWidth: {
    var left = root.centerLeftEdge()
    var slotX = root.mySlotX()
    if (left > 0) {
      var avail = Math.floor(left - slotX) - Style.space(16)
      return Math.max(160, Math.min(600, avail))
    }
    return 600
  }

  readonly property var buttonInfo: root.getInfo(
    root.activeInfo, root.termForeground,
    root.toplevel ? root.toplevel.title
      : (root.activeInfo ? (root.activeInfo["title"] || "") : ""))

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // ------------------------------------------------------------- bar pill

    Item {
      id: button
      anchors.fill: parent
      implicitWidth: Math.min(label.implicitWidth, root.maxWidth)
      implicitHeight: root.barSize

      Row {
      id: label
      height: parent.height
      width: parent.width
      leftPadding: Style.spaceReal(6)
      rightPadding: Style.spaceReal(6)
      spacing: Style.space(6)
      clip: true

      Text {
      id: glyphLabel
      anchors.verticalCenter: parent.verticalCenter
      text: root.buttonInfo[0]
      color: root.bar ? root.bar.barForeground : Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      renderType: Text.NativeRendering
    }

      Text {
      id: titleLabel
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, Math.min(root.maxWidth - glyphLabel.implicitWidth - label.leftPadding - label.rightPadding - label.spacing, implicitWidth))
      clip: true
      elide: Text.ElideRight
      text: root.buttonInfo[1]
      color: root.bar ? root.bar.barForeground : Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      renderType: Text.NativeRendering
    }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggle()
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
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        // ---------- Hero: big icon · name · window title ----------
        Item {
          id: heroGroup
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
            text: root.buttonInfo[0]
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: 42
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(16)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(3)

            Text {
              text: root.buttonInfo[1]
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.heading
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              visible: root.win && root.win.title !== "" && root.win.title !== root.buttonInfo[1]
              text: root.win ? root.win.title : ""
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        // ---------- Window details ----------
        PanelSeparator {
          foreground: root.bar.foreground
        }

        Column {
          width: parent.width
          spacing: Style.space(10)

          PanelSectionHeader {
            text: "WINDOW"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Column {
            width: parent.width
            spacing: Style.space(8)

            Repeater {
              model: root.details

              Row {
                required property var modelData
                visible: modelData.value !== ""
                width: parent.width
                spacing: Style.space(12)

                Text {
                  text: modelData.key
                  color: Qt.darker(root.bar.foreground, 1.45)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  width: Style.space(76)
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: modelData.value
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.body
                  elide: Text.ElideRight
                  width: parent.width - Style.space(76) - Style.space(12)
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }
          }
        }
      }
    }
  }
}

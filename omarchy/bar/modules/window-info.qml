import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "activewindow"

  readonly property var toplevel: ToplevelManager.activeToplevel

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
    "fdm": ["󰇚", "FDM"],
    "qbittorrent": ["", "Torrent"]
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

  function getInfo() {
    if (!toplevel || !toplevel.appId)
      return ["󱂬", "Desktop"]

    let id = toplevel.appId.toLowerCase()
    let rawTitle = toplevel.title || ""
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

  implicitWidth: Math.min(label.implicitWidth, maxWidth) + Style.space(2)
  implicitHeight: barSize


  Row {
    id: label

    height: parent.height
    width: parent.width
    leftPadding: Style.spaceReal(6)
    rightPadding: Style.spaceReal(6)
    spacing: Style.space(6)
    clip: true

    readonly property var info: root.getInfo()
    readonly property string glyphText: info && info.length > 0 ? info[0] : ""
    readonly property string titleText: info && info.length > 1 ? info[1] : ""

    Text {
      id: glyphLabel
      anchors.verticalCenter: parent.verticalCenter
      text: parent.glyphText
      color: root.bar
        ? root.bar.barForeground
        : Color.foreground
      font.family: root.bar
        ? root.bar.fontFamily
        : Style.font.family
      font.pixelSize: Style.font.body
      renderType: Text.NativeRendering
    }

    Text {
      id: titleLabel
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, Math.min(root.maxWidth - glyphLabel.implicitWidth - label.leftPadding - label.rightPadding - label.spacing, implicitWidth))
      clip: true
      elide: Text.ElideRight
      text: parent.titleText
      color: root.bar
        ? root.bar.barForeground
        : Color.foreground
      font.family: root.bar
        ? root.bar.fontFamily
        : Style.font.family
      font.pixelSize: Style.font.body
      renderType: Text.NativeRendering
    }
  }
}

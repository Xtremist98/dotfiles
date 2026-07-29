import Quickshell
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
    "terminal": ["", "Terminal"],
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
    "gnome-terminal": ["", "GNOME Terminal"],
    "xfce4-terminal": ["󰞷", "XFCE Terminal"],
    "st": ["", "Simple Terminal"],

    // Linux Distributions
    "tux": ["", "Kernel"],
    "arch": ["", "Arch Linux"],
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
    "omarchy": ["󱓞", "Omarchy Menu"],
    "org.omarchy.bash": ["󰣇", "System-info"],
    "org.omarchy.btop": ["󰇄", "Btop-Monitor"],
    "hyprland": ["", "Hyprland"],
    "ghostty": ["󰊠", "Ghostty Terminal"],
    "lazygit": ["󰊢", "LazyGit"],
    "lazydocker": ["", "LazyDocker"],
    "btop": ["󰓅", "Btop-Monitor"],
    "nvtop": ["", "GPU Monitor"],
    "basecamp": ["󰭹", "Basecamp"],
    "hey": ["󰇮", "HEY Mail"],
    "aether": ["󰨚", "Aether"],
    "org.omarchy.nvtop": ["", "Graphics-Engine"],

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
    "claude": ["󰚩", "Claude (Anthropic)"],
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
    "mpv": ["", "Media Player"],
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
    "xed": ["󰷈", "Text Editor"],
    "fdm": ["󰇚", "FDM"],
    "qbittorrent": ["", "Torrent"]
  })


  function getInfo() {
    if (!toplevel || !toplevel.appId)
      return ["󰍹", "Desktop"]

    let id = toplevel.appId.toLowerCase()

    for (let key in appMap) {
      if (id.includes(key))
        return appMap[key]
    }

    let parts = id.split(".")
    let name = parts[parts.length - 1]
    name = name.charAt(0).toUpperCase() + name.slice(1)
    return ["󰍹", name]
  }


  visible: true

  implicitWidth: label.implicitWidth + Style.space(2)
  implicitHeight: barSize


  Text {
    id: label

    anchors.verticalCenter: parent.verticalCenter

    property var info: root.getInfo()

    text: info[0] + " " + info[1]

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

#!/usr/bin/env python3 -u
import subprocess
import json
import re
import time
import sys

# --- CONFIGURATION ---
TITLE_LIMIT = 25
MARQUEE_WIDTH = 35
ANIMATION_FRAMES = ["󰎊", "󰎋", "󰎌"]

def marquee_text(text, width):
    """Slides only the text continuously from right to left if it exceeds width."""
    if not text or len(text) <= width:
        return text
    padded = text + "     "
    shift = int(time.time() * 3) % len(padded)
    scrolling = (padded + padded)[shift:shift + width]
    return scrolling

def get_active_window():
    """Fetches the title and class of the currently focused window via hyprctl."""
    try:
        out = subprocess.check_output(["hyprctl", "activewindow", "-j"]).decode("utf-8")
        win_data = json.loads(out)
        return str(win_data.get("title", "")), str(win_data.get("class", ""))
    except Exception:
        return "Desktop", ""

def get_music_animation():
    """Returns a cycling animation frame if music is playing on supported apps."""
    try:
        status = subprocess.check_output(["playerctl", "status"], stderr=subprocess.DEVNULL).decode("utf-8").strip()
        player = subprocess.check_output(["playerctl", "-f", "{{playerName}}", "metadata"], stderr=subprocess.DEVNULL).decode("utf-8").strip().lower()
        
        music_apps = ["spotify", "applemusic", "youtubemusic", "gaana", "jiosaavn", "chromium", "firefox", "brave", "mpv"]
        
        if status == "Playing" and any(app in player for app in music_apps):
            frame_index = int(time.time()) % len(ANIMATION_FRAMES)
            return f"{ANIMATION_FRAMES[frame_index]} "
        return ""
    except Exception:
        return ""

def truncate(text, limit):
    """Limits text length to keep the bar clean."""
    if not text: return ""
    return text if len(text) <= limit else text[:limit-3] + "..."

def get_brand_info(title, app_class):
    """Returns icon, label, and color based on the window details."""
    brands = {
        # --- Development & Version Control ---
        "vscode": ("󰨞", "VS Code", "#89B4FA"),
        "code": ("󰨞", "VS Code", "#89B4FA"),
        "neovim": ("", "Neovim", "#A6E3A1"),
        "terminal": ("", "Terminal", "#9399B2"),
        "github": ("󰊤", "GitHub", "#B4BEFE"),
        "git": ("󰊢", "Git", "#F38BA8"),
        "docker": ("", "Docker", "#74C7EC"),
        "postman": ("󱓎", "Postman", "#FAB387"),
        "bitbucket": ("󰊭", "Bitbucket", "#89B4FA"),

        # --- Terminal Emulators & Shells ---
        "alacritty": ("", "Alacritty", "#F9E2AF"),
        "kitty": ("󰄛", "Kitty", "#EBCB8B"),
        "foot": ("󰞷", "Foot", "#89DCEB"),
        "wezterm": ("󰞷", "WezTerm", "#94E2D5"),
        "konsole": ("󰞷", "Konsole", "#89B4FA"),
        "gnome-terminal": ("", "GNOME Terminal", "#6E6C7E"),
        "xfce4-terminal": ("󰞷", "XFCE Terminal", "#9399B2"),
        "st": ("", "Simple Terminal", "#BAC2DE"),

        # --- Linux Distributions & Kernel ---
        "tux": ("", "Kernel", "#F9E2AF"),
        "arch": ("", "Arch Linux", "#89DCEB"),
        "nixos": ("", "NixOS", "#B4BEFE"),
        "ubuntu": ("", "Ubuntu", "#F8BD96"),
        "fedora": ("", "Fedora", "#89B4FA"),
        "debian": ("", "Debian", "#F28FAD"),
        "gentoo": ("", "Gentoo", "#CBA6F7"),
        
        "org.gnome.nautilus": ("󰉋", "Files", "#89B4FA"),
        "org.gnome.console": ("󰞷", "Console", "#6E6C7E"),
        "org.gnome.terminal": ("", "Terminal", "#6E6C7E"),
        "org.gnome.settings": ("󰒓", "Settings", "#A6ADC8"),
        "org.gnome.calculator": ("󰪚", "Calculator", "#A6E3A1"),
        "org.gnome.software": ("󰀻", "Software", "#89B4FA"),
        "org.gnome.systemmonitor": ("󰓅", "System Monitor", "#94E2D5"),
        "org.gnome.baobab": ("󰓅", "Disk Usage", "#F9E2AF"),
        "org.gnome.characters": ("󰬈", "Characters", "#FAB387"),
        "org.gnome.font-viewer": ("󰬈", "Fonts", "#89B4FA"),
        "org.gnome.logs": ("󰘙", "Logs", "#F38BA8"),
        "org.gnome.gedit": ("󰷈", "Text Editor", "#FAB387"),

        # --- GNOME Ecosystem ---
        "nautilus": ("󰉋", "Files", "#89B4FA"),
        "gnome-console": ("󰞷", "Console", "#6E6C7E"),
        "gnome-settings": ("󰒓", "Settings", "#A6ADC8"),
        "gnome-tweaks": ("󰒓", "Tweaks", "#9399B2"),
        "gnome-software": ("󰀻", "Software", "#89B4FA"),
        "gnome-system-monitor": ("󰓅", "System Monitor", "#94E2D5"),
        "gnome-disks": ("󰋊", "Disks", "#BAC2DE"),
        "gnome-calculator": ("󰪚", "Calculator", "#A6E3A1"),
        "gnome-calendar": ("󰸗", "Calendar", "#F38BA8"),
        "gnome-clocks": ("󰥔", "Clocks", "#CBA6F7"),
        "gnome-weather": ("󰖕", "Weather", "#89DCEB"),
        "gnome-maps": ("󰉙", "Maps", "#A6E3A1"),
        "gnome-text-editor": ("󰷈", "Text Editor", "#FAB387"),
        "gnome-music": ("󰝚", "Music", "#FAB387"),
        "gnome-photos": ("󰄄", "Photos", "#CBA6F7"),
        "gnome-videos": ("󰿎", "Videos", "#89B4FA"),
        "gnome-contacts": ("󰻙", "Contacts", "#FAB387"),
        "gnome-builder": ("󰨞", "Builder", "#89B4FA"),
        "gnome-boxes": ("󰢹", "Boxes", "#CBA6F7"),
        "gnome-logs": ("󰘙", "Logs", "#F38BA8"),
        "epiphany": ("󰖟", "Web (Epiphany)", "#89B4FA"),
        "geary": ("󰇮", "Geary Mail", "#89DCEB"),
        "polari": ("󰒱", "Polari IRC", "#F5C2E7"),
        "fragments": ("󰇚", "Fragments", "#89B4FA"),

        # --- Omarchy & Modern Linux Stack ---
        "omarchy": ("󱓞", "Omarchy Menu", "#9ece6a"),
        "org.omarchy.bash": ("󰣇", "System-info", "#F8BD96"),
        "org.omarchy.btop": ("󰇄", "Btop-Monitor", "#74C7EC"),
        "org.omarchy.terminal": ("<span font='omarchy 7.5'>\ue900</span>", "Omarchy", "#9ece6a"),
        "hyprland": ("", "Hyprland", "#94E2D5"),
        "ghostty": ("󰊠", "Ghostty Terminal", "#FFFFFF"),
        "lazygit": ("󰊢", "LazyGit", "#F38BA8"),
        "lazydocker": ("", "LazyDocker", "#89B4FA"),
        "btop": ("󰓅", "Btop-Monitor", "#74C7EC"),
        "basecamp": ("󰭹", "Basecamp", "#A6E3A1"),
        "hey": ("󰇮", "HEY Mail", "#F9E2AF"),
        "aether": ("󰨚", "Aether", "#F28FAD"),

        # --- Productivity & Creative ---
        "notion": ("󰇈", "Notion", "#A6ADC8"),
        "obsidian": ("󱓧", "Obsidian", "#CBA6F7"),
        "trello": ("󰓓", "Trello", "#89B4FA"),
        "todoist": ("󰄱", "Todoist", "#F38BA8"),
        "slack": ("󰒱", "Slack", "#CBA6F7"),
        "teams": ("󰊻", "MS Teams", "#B4BEFE"),
        "zoom": ("󰕧", "Zoom", "#89B4FA"),
        "figma": ("󰈔", "Figma", "#F8BD96"),
        "typora": ("󰷈", "Typora", "#9399B2"),
        "libreoffice": ("󰈙", "LibreOffice", "#A6E3A1"),
        "kdenlive": ("", "Kdenlive", "#89DCEB"),
        "inkscape": ("", "Inkscape", "#A6ADC8"),
        "obs": ("󰕧", "OBS Studio", "#6E6C7E"),

        # --- Gaming & Multimedia ---
        "steam": ("󰓓", "Steam", "#B4BEFE"),
        "lutris": ("", "Lutris", "#F8BD96"),
        "heroic": ("󰊗", "Heroic Games", "#D9E0EE"),
        "bottles": ("󰏖", "Bottles", "#89B4FA"),
        "itchio": ("󰪚", "Itch.io", "#F38BA8"),
        "gog": ("󰓓", "GOG Galaxy", "#CBA6F7"),
        "retroarch": ("󰓓", "RetroArch", "#BAC2DE"),
        "minigalaxy": ("󰀻", "Minigalaxy", "#89DCEB"),
        "spotify": ("󰓇", "Spotify", "#A6E3A1"),
        "mangohud": ("󰓅", "MangoHud", "#A6E3A1"),
        "goverlay": ("󰒓", "GOverlay", "#FAB387"),
        "corectrl": ("󰢮", "CoreCtrl", "#F38BA8"),
        "piper": ("󰍽", "Piper Mouse", "#94E2D5"),
        "gamemode": ("󰓅", "Feral GameMode", "#89DCEB"),
        "geforce-now": ("󰊗", "GeForce Now", "#A6E3A1"),
        "xbox-cloud": ("󰓓", "Xbox Cloud", "#A6E3A1"),
        "moonlight": ("󰖟", "Moonlight Stream", "#CBA6F7"),

        # --- Google Ecosystem ---
        "google": ("", "Google", "#89B4FA"),
        "chrome": ("", "Chrome", "#89B4FA"),
        "gmail": ("󰊫", "Gmail", "#F38BA8"),
        "calendar": ("󰸗", "Google Calendar", "#89B4FA"),
        "sheets": ("󰈛", "Google Sheets", "#A6E3A1"),
        "docs": ("󰈙", "Google Docs", "#89B4FA"),
        "slides": ("󰈧", "Google Slides", "#F9E2AF"),
        "meet": ("󰕧", "Google Meet", "#94E2D5"),
        "keep": ("󰠮", "Google Keep", "#F9E2AF"),
        "photos": ("󰄄", "Google Photos", "#89B4FA"),
        "maps": ("󰉙", "Google Maps", "#A6E3A1"),
        "youtube": ("󰗃", "YouTube", "#F38BA8"),

        # --- AI & LLM Tools ---
        "chatgpt": ("󰭻", "ChatGPT (OpenAI)", "#94E2D5"),
        "claude": ("󰚩", "Claude (Anthropic)", "#F8BD96"),
        "gemini": ("󰚩", "Google Gemini", "#B4BEFE"),
        "perplexity": ("󰖟", "Perplexity AI", "#89DCEB"),
        "deepseek": ("󰚩", "DeepSeek", "#89B4FA"),
        "grok": ("󰚩", "Grok (xAI)", "#D9E0EE"),
        "mistral": ("󰚩", "Mistral AI", "#FAB387"),
        "ollama": ("󱓞", "Ollama (Local)", "#BAC2DE"),
        "lm-studio": ("󰚩", "LM Studio", "#D9E0EE"),
        "cursor": ("󰨞", "Cursor IDE", "#94E2D5"),
        "copilot": ("󰊤", "GitHub Copilot", "#CBA6F7"),
        "windsurf": ("󰖟", "Windsurf", "#94E2D5"),
        "aider": ("", "Aider CLI", "#F9E2AF"),
        "antigravity": ("󰚩", "Google Antigravity", "#89B4FA"),
        "lovable": ("󱓎", "Lovable AI", "#F5C2E7"),

        # --- Browsers & Privacy Tools ---
        "firefox": ("", "Firefox", "#FAB387"),
        "brave": ("", "Brave", "#F8BD96"),
        "chromium": ("", "Chromium", "#89B4FA"),
        "librewolf": ("󰈹", "LibreWolf", "#74C7EC"),
        "mullvad-browser": ("󰖟", "Mullvad Browser", "#FAB387"),
        "vivaldi": ("󰖟", "Vivaldi", "#F38BA8"),
        "thorium": ("󰖟", "Thorium", "#9399B2"),
        "ladybird": ("󰖟", "Ladybird", "#F5C2E7"),
        "signal": ("󰈰", "Signal Messenger", "#89B4FA"),
        "simplex": ("󰭻", "SimpleX Chat", "#D9E0EE"),
        "session": ("󰚩", "Session", "#A6E3A1"),
        "threema": ("󰒱", "Threema", "#A6E3A1"),
        "element": ("󰒱", "Element (Matrix)", "#94E2D5"),
        "discord-canary": ("󰙯", "Discord Canary", "#B4BEFE"),
        "bitwarden": ("󰞀", "Bitwarden", "#89B4FA"),
        "keepassxc": ("󰞀", "KeePassXC", "#A6E3A1"),
        "1password": ("󰢁", "1Password", "#89B4FA"),
        "proton-mail": ("󰇮", "Proton Mail", "#CBA6F7"),
        "tuta": ("󰇮", "Tuta Mail", "#F38BA8"),
        "duckduckgo": ("󰇥", "DuckDuckGo", "#F8BD96"),
        "veracrypt": ("󰞁", "VeraCrypt", "#89B4FA"),
        "mullvad": ("󰖂", "Mullvad VPN", "#A6E3A1"),
        "proton-vpn": ("󰖂", "Proton VPN", "#CBA6F7"),
        "ivpn": ("󰖂", "IVPN", "#74C7EC"),
        "tailscale": ("󰖂", "Tailscale", "#B4BEFE"),
        "dropbox": ("󰇖", "Dropbox", "#89B4FA"),

        # --- Social ---
        "ayugram-desktop": ("", "AyuGram", "#3399ff"),
        "telegram-desktop": ("", "Telegram", "#24A1DE"),
        "telegram": ("", "Telegram", "#24a1de"),
        "discord": ("", "Discord", "#5865f2"),
        "whatsapp": ("", "WhatsApp", "#25d366"),
        "reddit": ("", "Reddit", "#ff4500"),
        "twitter": ("", "Twitter", "#1da1f2"),
        "x.com": ("", "X", "#000000"), 
        "facebook": ("", "Facebook", "#1877f2"),
        "instagram": ("", "Instagram", "#c13584"),
        "linkedin": ("", "LinkedIn", "#0077b5"),
        "pinterest": ("", "Pinterest", "#bd081c"),
        "tumblr": ("", "Tumblr", "#35465c"),
        "tiktok": ("", "TikTok", "#ff0050"),
        "org.signal.Signal": ("󰭹", "Signal", "#3a76f0"),
        "signal-desktop": ("󰭹", "Signal", "#3a76f0"),

        # --- Graphics & Media ---
        "flameshot": ("󰄀", "Flameshot", "#ff4081"),
        "gimp": ("", "GIMP", "#5c5543"),
        "inkscape": ("", "Inkscape", "#ffffff"),
        "figma": ("", "Figma", "#f24e1e"),
        "canva": ("", "Canva", "#00c4cc"),
        "mpv": ("", "media-player", "#F38BA8"),
        "vlc": ("󰕼", "VLC", "#ff9900"),
        "obs": ("", "OBS Studio", "#262626"),
        "spotify": ("", "Spotify", "#1db954"),
        "Stremio.stremio": ("󱖏", "Stremio", "#F38BA8"),
        "com.stremio.Stremio": ("󱖏", "Stremio", "#F38BA8"),
        "stremio": ("󱖏", "Stremio", "#F38BA8"),
        "com.stremio": ("󱖏", "Stremio", "#F38BA8"),
        "com.stremio.Service": ("󱑫", "Stremio Service", "#F38BA8"),

        # --- System & Utilities ---
        "bitwarden": ("󰞀", "Bitwarden", "#175DDC"),
        "Bitwarden": ("󰞀", "Bitwarden", "#175DDC"),
        "pavucontrol": ("󰓃", "Volume Control", "#67808d"),
        "org.kde.dolphin": ("", "Dolphin", "#3daee9"),
        "dolphin": ("", "Dolphin", "#3daee9"),
        "calculator": ("", "Calculator", "#4193f4"),
        "aether": ("󰑭", "Aether", "#a29bfe"),
        "nwg-look": ("󰏘", "Nwg-look", "#0db9d7"),
        "imv": ("", "Imv", "#06b6d4"),
        "localsend": ("", "LocalSend", "#3db2ff"),
        "xed": ("󰷈", "Text Editor", "#FAB387"),
        "fdm": ("󰇚", "FDM", "#00aaff"),
    }

    low_title = title.lower() if title else ""
    low_class = app_class.lower() if app_class else ""

    browsers = ["chromium", "firefox", "brave", "chrome"]
    is_browser = any(b in low_class for b in browsers)

    if is_browser:
        clean_title = re.sub(r' - (Chromium|Firefox|Brave|Google Chrome)$', '', title, flags=re.I)
        
        if "youtube" in low_title:
            yt_icon, yt_name, yt_color = brands.get("youtube", ("󰗃", "YouTube", "#F38BA8"))
            clean_title = re.sub(r'^\(\d+\)\s*', '', clean_title)
            clean_title = re.sub(r' - YouTube$', '', clean_title, flags=re.I)
            scrolling_title = marquee_text(clean_title, MARQUEE_WIDTH)
            bar_text = f"{yt_name}: {scrolling_title}"
            return yt_icon, bar_text, yt_color
         
        if "stremio" in low_title:
            st_icon, st_name, st_color = brands.get("stremio", ("󰐊", "Stremio", "#ff9900"))
            media_title = ""
            try:
                res = subprocess.run(
                    ["playerctl", "metadata", "--format", "{{ artist }} - {{ title }}"],
                    capture_output=True, text=True, timeout=0.2
                )
                if res.returncode == 0 and res.stdout.strip():
                    media_title = res.stdout.strip()
            except Exception:
                pass

            if not media_title or media_title == " - ":
                media_title = "freedem-to-stream"

            scrolling_title = marquee_text(media_title, MARQUEE_WIDTH)
            bar_text = f"{st_name}: {scrolling_title}"
            return st_icon, bar_text, st_color

        for key, (w_icon, w_name, w_color) in brands.items():
            if key in low_title and key not in browsers:
                return w_icon, truncate(clean_title, TITLE_LIMIT), w_color
        return "󰖟", truncate(clean_title, TITLE_LIMIT), "#4285F4"

    media_players = ["mpv", "stremio"]
    if any(m in low_class for m in media_players):
        if "mpv" in low_class:
            w_icon = ""
            w_name = "Media-Player"
            w_color = "#F38BA8"
            scrolling_title = marquee_text(title, MARQUEE_WIDTH)
            bar_text = f" {w_name}: {scrolling_title}"
            return w_icon, bar_text, w_color
        else:
            w_icon = "󱖏"
            w_name, w_color = "Stremio", "#ff9900"
            scrolling_title = marquee_text(title, MARQUEE_WIDTH)
            bar_text = f" {w_name}: {scrolling_title}"
            return w_icon, bar_text, w_color
    
    sorted_brands = sorted(brands.items(), key=lambda x: len(x[0]), reverse=True)

    for key, (icon, name, color) in sorted_brands:
        if key in low_class:
            return icon, name, color

    for key, (icon, name, color) in sorted_brands:
        if key in low_title:
            return icon, name, color

    fallback_name = app_class.split('.')[-1].capitalize() if app_class else "Desktop"
    return "󰍹", truncate(fallback_name, TITLE_LIMIT), "#CBA6F7"

def main():
    try:
        window_data = get_active_window()
        if not window_data:
            title, app_class = "Desktop", ""
        else:
            title, app_class = window_data

        if not title or title in ["null", "Desktop", ""] or not app_class:
            print(json.dumps({
                "text": "<span color='#9ece6a'>󰣇  Arch-Linux</span>", 
                "tooltip": "Workspace"
            }))
            sys.stdout.flush()
            return

        icon, display_text, brand_color = get_brand_info(title, app_class)
        animation = get_music_animation()

        bar_output = f"{animation}<span color='{brand_color}'>{icon} {display_text}</span>"

        tooltip_content = (
            f"<span size='large' weight='bold'>{icon} {display_text}</span>\n"
            f"<span color='#585B70'>──────────────────────────</span>\n"
            f"<span color='#89B4FA'>󰣆 Class:</span> <span color='#CDD6F4'>{app_class}</span>\n"
            f"<span color='#FAB387'>󰖟 Full Title:</span> <span color='#CDD6F4'>{title}</span>"
        )

        print(json.dumps({
            "text": bar_output,
            "tooltip": tooltip_content,
            "class": app_class
        }))
        sys.stdout.flush()

    except Exception:
        print(json.dumps({
            "text": "<span color='#9ece6a'>󰣇  Arch Linux</span>", 
            "tooltip": "Workspace"
        }))
        sys.stdout.flush()

if __name__ == "__main__":
    main()

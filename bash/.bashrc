# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
# /etc/omarchy.conf is written by omarchy-dev-link. When absent, force the
# package default instead of preserving a stale inherited dev-link value before
# we decide which rc file to source.
if [[ -f /etc/omarchy.conf ]]; then
  source /etc/omarchy.conf
  export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
else
  export OMARCHY_PATH=/usr/share/omarchy
fi
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
alias p='python'
eval "$(starship init bash)"

yt () {
  local mode="$1"
  shift

  case "$mode" in
    720)
      yt-dlp --config-location "$HOME/.config/yt-dlp/video-720.conf" "$@"
      ;;
    1080)
      yt-dlp --config-location "$HOME/.config/yt-dlp/video-1080.conf" "$@"
      ;;
    mp4)
      yt-dlp --config-location "$HOME/.config/yt-dlp/video-mp4.conf" "$@"
      ;;
    opus)
      yt-dlp --config-location "$HOME/.config/yt-dlp/audio-opus.conf" "$@"
      ;;
    mp3)
      yt-dlp --config-location "$HOME/.config/yt-dlp/mp3.conf" "$@"
      ;;
    *)
      echo "Usage:"
      echo "  yt 720 <url>"
      echo "  yt 1080 <url>"
      echo "  yt mp4 <url>"
      echo "  yt opus <url>"
      echo "  yt mp3 <url>"
      ;;
  esac
}

# Map mise global node/npm binaries to system path for toolchains & mpv hooks
export PATH="$HOME/.local/share/mise/shims:$PATH"
export PATH="$HOME/.local/share/mise/installs/node/22.23.0/bin:$PATH"
# Optimize Node V8 engine thread management and garbage collection for streaming hooks
export NODE_OPTIONS="--max-semi-space-size=64 --v8-pool-size=4"

alias backup-dots='cd "/mnt/media/Dots" && git add . && git commit -m "Automated backup" && git pull origin main --rebase && git push origin main && cd - > /dev/null'

# Native Go TorrServer stream function (With 100+ Video Grid UI)
function stream {
    if [ -z "$1" ]; then
        echo "Error: No magnet link provided."
        echo "Usage: stream '<magnet_link>' [folder/list] [track_number]"
        return 1
    fi

    echo "Disguising magnet string and routing to TorrServer..."
    
    # Safely URL-encode the magnet link so the local mpv hooks are blinded
    local encoded_magnet=$(python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$1")

    # MODE 1: Web Interface Viewer (Perfect for 100+ Videos)
    if [ "$2" == "list" ]; then
        echo "Massive directory detected. Opening TorrServer interactive control panel..."
        # Add torrent to TorrServer database silently via background request
        curl -s "http://localhost:8090/stream/api/playlist.m3u?link=${encoded_magnet}" > /dev/null
        # Open your web browser straight to the local interactive dashboard grid
        python3 -m webbrowser "http://localhost:8090/"
    
    # MODE 2: Multi-file Manual Selector (Good for 2-5 files)
    elif [ "$2" == "folder" ]; then
        local track_index=${3:-1}
        echo "Multi-file folder mode active. Loading file index=${track_index}..."
        /usr/bin/mpv "http://localhost:8090/stream?play&index=${track_index}&link=${encoded_magnet}"
    
    # MODE 3: Standard Single Video (Your working baseline)
    else
        echo "Standard single-file mode active..."
        /usr/bin/mpv "http://localhost:8090/stream?play&index=0&link=${encoded_magnet}"
    fi
}

# Bar toggle Switch between Custom bar & Omarchy default bar 
alias switch-bar='$HOME/.config/omarchy/scripts/toggle-bar.sh'

# NordVpn connectivity
vpnup() {
    local CONFIG_FILE="$HOME/nordvpn/$1.ovpn"
    local CREDS_FILE="$HOME/.nordvpn-creds"

    if [ -f "$CONFIG_FILE" ]; then
        # --auth-user-pass tells OpenVPN exactly where to look for your login details
        sudo openvpn --config "$CONFIG_FILE" --auth-user-pass "$CREDS_FILE" --daemon && echo "VPN started in the background using: $1"
    else
        echo "Error: Profile '$1' not found in ~/vpn-configs/"
        echo "Available files in your folder:"
        ls -1 "$HOME/nordvpn/" | grep ".ovpn" | sed 's/\.ovpn//'
    fi
}
# To Disconnect NordVpn
alias vpndown="sudo killall openvpn && echo 'VPN Disconnected.'"



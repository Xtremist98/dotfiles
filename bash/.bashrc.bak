# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

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
      yt-dlp --config-location "$HOME/.config/yt-dlp/audio-mp3.conf" "$@"
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

alias backup-dots='cd "/mnt/media/Dot files" && git add . && git commit -m "Automated backup" && git pull origin main --rebase && git push origin main && cd - > /dev/null'

# Native Go TorrServer stream function (Dynamic Track Selector)
function stream {
    if [ -z "$1" ]; then
        echo "Error: No magnet link provided."
        echo "Usage: stream '<magnet_link>' [folder] [track_number]"
        return 1
    fi

    echo "Disguising magnet string and routing to TorrServer..."
    
    # Safely URL-encode the magnet link so the local mpv hooks are blinded
    local encoded_magnet=$(python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$1")

    # MODE 1: Multi-file Folder Mode
    if [ "$2" == "folder" ]; then
        # Default to index=1 if no track number is provided, otherwise use what you typed
        local track_index=${3:-1}
        echo "Multi-file folder mode active. Loading file index=${track_index}..."
        /usr/bin/mpv "http://localhost:8090/stream?play&index=${track_index}&link=${encoded_magnet}"
    
    # MODE 2: Standard Single Video (Your working baseline)
    else
        echo "Standard single-file mode active..."
        /usr/bin/mpv "http://localhost:8090/stream?play&index=0&link=${encoded_magnet}"
    fi
}

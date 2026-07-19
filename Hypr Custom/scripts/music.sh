#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 --title | --player-icon | --artist | --position | --length | --album | --source | --status"
    exit 1
fi

# Function to get the best active player (prioritize playing over paused)
get_active_player() {
    # First, try to find a playing player
    playing_player=$(playerctl --list-all 2>/dev/null | while read player; do
        status=$(playerctl -p "$player" status 2>/dev/null)
        if [ "$status" = "Playing" ]; then
            echo "$player"
            exit 0
        fi
    done)
    
    if [ -n "$playing_player" ]; then
        echo "$playing_player"
        return
    fi
    
    # If no playing player, get the first paused player
    paused_player=$(playerctl --list-all 2>/dev/null | head -1)
    if [ -n "$paused_player" ]; then
        echo "$paused_player"
        return
    fi
    
    # If no players at all, return empty
    echo ""
}

# Function to get metadata using playerctl
get_metadata() {
    key=$1
    local player=$(get_active_player)
    if [ -n "$player" ]; then
        playerctl -p "$player" metadata --format "{{ $key }}" 2>/dev/null
    else
        echo ""
    fi
}

# Function to get player status
get_player_status() {
    local player=$(get_active_player)
    if [ -n "$player" ]; then
        playerctl -p "$player" status 2>/dev/null
    else
        echo "NoPlayer"
    fi
}

# Function to get player icon (text)
get_player_icon() {
    local player=$(get_active_player)
    if [ -z "$player" ]; then
        echo ""
    else
        if [[ "$player" == *"spotify"* ]] || [[ "$player" == *"Spotify"* ]]; then
            echo ""
        elif [[ "$player" == *"firefox"* ]] || [[ "$player" == *"Firefox"* ]]; then
            echo "󰈹"
        elif [[ "$player" == *"chromium"* ]] || [[ "$player" == *"chrome"* ]] || [[ "$player" == *"Google Chrome"* ]]; then
            echo ""
        elif [[ "$player" == *"youtube"* ]] || [[ "$player" == *"Youtube"* ]] || [[ "$player" == *"YouTube"* ]]; then
            echo ""
        elif [[ "$player" == *"vlc"* ]]; then
            echo "󰕼"
        elif [[ "$player" == *"mpv"* ]]; then
            echo ""
        else
            echo "󰎄"
        fi
    fi
}

# Function to determine the source and return clean text
get_source_info() {
    local player=$(get_active_player)
    if [ -z "$player" ]; then
        echo ""
        return
    fi
    
    if [[ "$player" == *"firefox"* ]] || [[ "$player" == *"Firefox"* ]]; then
        echo "Firefox"
    elif [[ "$player" == *"spotify"* ]] || [[ "$player" == *"Spotify"* ]]; then
        echo "Spotify"
    elif [[ "$player" == *"chromium"* ]] || [[ "$player" == *"chrome"* ]]; then
        echo "Chrome"
    elif [[ "$player" == *"youtube"* ]] || [[ "$player" == *"Youtube"* ]]; then
        echo "YouTube"
    elif [[ "$player" == *"zen"* ]] || [[ "$player" == *"Zen"* ]]; then
        echo "Zen Browser"
    else
        player_name=$(playerctl metadata --format "{{ playerName }}" 2>/dev/null)
        if [ -n "$player_name" ]; then
            echo "$player_name"
        else
            echo "Music"
        fi
    fi
}

# Function to get position using playerctl
get_position() {
    local player=$(get_active_player)
    if [ -n "$player" ]; then
        playerctl -p "$player" position 2>/dev/null
    else
        echo ""
    fi
}

# Function to convert microseconds to minutes and seconds
convert_length() {
    local length=$1
    local seconds=$((length / 1000000))
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))
    printf "%d:%02d" $minutes $remaining_seconds
}

# Function to convert seconds to minutes and seconds
convert_position() {
    local position=$1
    local seconds=${position%.*}
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))
    printf "%d:%02d" $minutes $remaining_seconds
}

# Parse the argument
case "$1" in
--title)
    title=$(get_metadata "xesam:title")
    if [ -z "$title" ] || [ "$title" = "" ]; then
        echo ""
    else
        echo "${title:0:30}"
    fi
    ;;
--player-icon)
    get_player_icon
    ;;
--artist)
    artist=$(get_metadata "xesam:artist")
    if [ -z "$artist" ] || [ "$artist" = "" ]; then
        echo ""
    else
        echo "${artist:0:30}"
    fi
    ;;
--position)
    position=$(get_position)
    length=$(get_metadata "mpris:length")
    if [ -z "$position" ] || [ -z "$length" ]; then
        echo ""
    else
        position_formatted=$(convert_position "$position")
        length_formatted=$(convert_length "$length")
        echo "$position_formatted/$length_formatted"
    fi
    ;;
--length)
    length=$(get_metadata "mpris:length")
    if [ -z "$length" ]; then
        echo ""
    else
        convert_length "$length"
    fi
    ;;
--status)
    status=$(get_player_status)
    if [[ $status == "Playing" ]]; then
        echo "󰐊"
    elif [[ $status == "Paused" ]]; then
        echo "󰏤"
    else
        echo ""
    fi
    ;;
--album)
    album=$(get_metadata "xesam:album")
    if [ -z "$album" ]; then
        echo ""
    else
        echo "$album"
    fi
    ;;
--source)
    get_source_info
    ;;
*)
    echo "Invalid option: $1"
    echo "Usage: $0 --title | --player-icon | --artist | --position | --length | --album | --source | --status"
    exit 1
    ;;
esac

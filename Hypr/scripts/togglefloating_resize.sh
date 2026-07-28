#!/bin/bash

# Toggle floating mode
hyprctl dispatch togglefloating

# Wait a moment for the state to update
sleep 0.1

# Get active window info
ACTIVE_WINDOW_INFO=$(hyprctl activewindow)
WINDOW_CLASS=$(echo "$ACTIVE_WINDOW_INFO" | grep 'class:' | awk '{print $2}')
IS_FLOATING=$(echo "$ACTIVE_WINDOW_INFO" | grep 'floating:' | awk '{print $2}')

# Check if the window is mpv and is now floating
if [ "$WINDOW_CLASS" = "mpv" ] && [ "$IS_FLOATING" = "1" ]; then
    # Resize the window to 700x700 pixels (using 'exact' parameter is crucial)
    hyprctl dispatch resizeactive exact 1000 650
    # Center the window on the monitor
    hyprctl dispatch centerwindow
fi


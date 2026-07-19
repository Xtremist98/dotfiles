#!/bin/bash

# Execute wttrbar and capture its JSON output
WEATHER_JSON=$(wttrbar --nerd --location Shabqadar)

# Check if the command was successful
if [ $? -ne 0 ]; then
    notify-send "Weather Error" "Could not fetch weather data."
    exit 1
fi

# Extract detailed information using jq for the notification body
# Adjust the jq path according to the actual output structure of your specific wttrbar version
# This example uses a likely structure based on common waybar weather scripts
TEMP=$(echo "$WEATHER_JSON" | jq -r '.text')
TOOLTIP=$(echo "$WEATHER_JSON" | jq -r '.tooltip') # Assuming 'tooltip' field has detailed info

# Send a Mako notification with the detailed information
notify-send -a "Waybar Weather" "$TEMP" "$TOOLTIP"


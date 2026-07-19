#!/bin/bash

# Fetch weather data from wttr.in for your location (e.g., London, muc for Munich Airport, or ~Eiffel+Tower)
WEATHER_INFO=$(curl -s wttr.in/Shabqadar?format="%l:+%c+%t+feels+like+%f\n")

# Check if the curl request was successful
if [ $? -eq 0 ] && [ -n "$WEATHER_INFO" ]; then
    # Use notify-send to display the information in a Mako notification
    # The first argument is the title (optional), and the second is the message body.
    # -t sets the timeout in milliseconds (e.g., 10000ms = 10 seconds)
    # -a sets the application name (e.g., Weather)
    notify-send -t 10000 -a "Weather" "$WEATHER_INFO"
else
    notify-send -t 5000 -a "Weather" "Failed to retrieve weather information."
fi


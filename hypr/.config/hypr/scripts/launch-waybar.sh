#!/usr/bin/env bash

# Kill any existing waybar instances
pkill waybar

# Launch waybar
waybar &

# Watch for config changes and reload
while true; do
    inotifywait -e modify ~/.config/waybar/config ~/.config/waybar/style.css
    pkill -SIGUSR2 waybar
done

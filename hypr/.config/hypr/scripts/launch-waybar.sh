#!/usr/bin/env bash
pkill -x waybar
waybar &

while true; do
    inotifywait -e modify ~/.config/waybar/config ~/.config/waybar/style.css
    pkill -SIGUSR2 waybar
done

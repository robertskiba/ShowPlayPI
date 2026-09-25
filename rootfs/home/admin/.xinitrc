#!/bin/bash

xset s off
xset -dpms
xset s noblank

/usr/local/bin/showplaypi-display

openbox-session &

unclutter-xfixes \
    --timeout 1 \
    --hide-on-touch &

# Video mode: showplaypi-video.service shows mpv full-screen in this session; X only has to stay up
if [ -e /run/showplaypi/mode-video ]; then
    xsetroot -solid black
    exec sleep infinity
fi

while true; do
    /usr/local/bin/showplaypi-browser
    sleep 2
done

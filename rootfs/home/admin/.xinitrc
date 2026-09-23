#!/bin/bash

xset s off
xset -dpms
xset s noblank

/usr/local/bin/showplaypi-display

openbox-session &

unclutter-xfixes \
    --timeout 1 \
    --hide-on-touch &

while true; do
    /usr/local/bin/showplaypi-browser
    sleep 2
done

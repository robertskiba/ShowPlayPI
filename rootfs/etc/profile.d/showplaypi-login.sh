#!/bin/sh

# Display only for interactive SSH sessions.
case "$-" in
    *i*) ;;
    *) return 0 ;;
esac

[ -n "${SSH_CONNECTION:-}" ] || return 0


RELEASE_FILE="/etc/showplaypi-release"
showplaypi_mode="$(/usr/local/bin/showplaypi-mode 2>/dev/null || echo browser)"
showplaypi_host="$(hostname).local"

if [ -r "$RELEASE_FILE" ]; then
    # shellcheck disable=SC1090
    . "$RELEASE_FILE"

    printf 'ShowPlayPI v%s (Build Date: %s) - mode: %s\n' \
        "${SHOWPLAYPI_VERSION:-unknown}" \
        "${SHOWPLAYPI_BUILD_DATE:-${SHOWPLAYPI_RELEASE_DATE:-unknown}}" \
        "$showplaypi_mode"
fi

printf '\n'
printf 'ShowPlayPI configuration\n'
printf '  Edit showplaypi.ini:     showplaypi-config\n'
printf '  Apply changes:           showplaypi-refresh\n'
printf '  Apply network:           showplaypi-refresh --network\n'
printf '  Full restart:            sudo reboot\n'

# The commands of the active mode and of the audio player
case "$showplaypi_mode" in
    companion)
        printf '\n'
        printf 'Companion (web interface: http://%s:%s)\n' "$showplaypi_host" \
            "$(/usr/local/bin/showplaypi-companion-port 2>/dev/null || echo 8000)"
        printf '  Update Companion:        sudo companion-update\n'
        printf '  Previous version:        sudo companion-update previous\n'
        printf '  Launch options:          sudo companion-config\n'
        printf '  Reset configuration:     sudo companion-reset\n'
        printf '  Restart Companion:       sudo systemctl restart showplaypi-companion\n'
        printf '  Log:                     journalctl -u showplaypi-companion -f\n'
        printf '  All Companion commands:  companion-help\n'
        ;;
    ontime)
        printf '\n'
        printf 'Ontime (web interface: http://%s:4001)\n' "$showplaypi_host"
        printf '  Restart Ontime:          sudo systemctl restart showplaypi-ontime\n'
        printf '  Log:                     journalctl -u showplaypi-ontime -f\n'
        ;;
    video)
        printf '\n'
        printf 'Video player (files: folder VIDEO on the drive SHOWPLAYPI)\n'
        printf '  Restart the player:      sudo systemctl restart showplaypi-video\n'
        printf '  Log:                     journalctl -u showplaypi-video -f\n'
        ;;
esac

if [ -e /run/showplaypi/audio-player ]; then
    printf '\n'
    printf 'Audio player (files: folder AUDIO on the drive SHOWPLAYPI)\n'
    printf '  Restart the player:      sudo systemctl restart showplaypi-audio\n'
    printf '  Log:                     journalctl -u showplaypi-audio -f\n'
fi

printf '\n'
printf 'OSC log (UDP port 23878):  journalctl -u showplaypi-osc -f\n'
printf '\n'

unset showplaypi_mode showplaypi_host

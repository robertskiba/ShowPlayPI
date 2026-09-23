#!/bin/sh

# Display only for interactive SSH sessions.
case "$-" in
    *i*) ;;
    *) return 0 ;;
esac

[ -n "${SSH_CONNECTION:-}" ] || return 0


RELEASE_FILE="/etc/showplaypi-release"

if [ -r "$RELEASE_FILE" ]; then
    # shellcheck disable=SC1090
    . "$RELEASE_FILE"

    printf 'ShowPlayPI v%s (Build Date: %s)\n\n' \
        "${SHOWPLAYPI_VERSION:-unknown}" \
        "${SHOWPLAYPI_BUILD_DATE:-${SHOWPLAYPI_RELEASE_DATE:-unknown}}"
fi

printf '\n'
printf 'ShowPlayPI configuration\n'
printf '  Edit showplaypi.ini:     showplaypi-config\n'
printf '  Apply changes:           showplaypi-refresh\n'
printf '  Apply network:           showplaypi-refresh --network\n'
printf '  Full restart:            sudo reboot\n'
printf '\n'
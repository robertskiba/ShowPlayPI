#!/usr/bin/env bash
# Pushes the current state of this repository to a running ShowPlayPI over SSH.
# Works in Git Bash (Windows), WSL or on Linux/macOS. There is a single password prompt.
#
#   ./deploy.sh showplaypi-e84042.local   -> admin@showplaypi-e84042.local (device name from the setup page)
#   ./deploy.sh 192.168.20.50            -> admin@192.168.20.50
#   ./deploy.sh -n <target>              dry run: only show what would change
#   ./deploy.sh --boot <target>          also config.txt, cmdline.txt, README.txt (without showplaypi.ini)
#   ./deploy.sh --boot --ini         additionally overwrite showplaypi.ini
#   ./deploy.sh --no-restart         do not restart services
#
# Default target via environment variable: SHOWPLAYPI_HOST=admin@10.0.0.5 ./deploy.sh
#
# Uses the SSH key ~/.ssh/showplaypi_ed25519 (or SHOWPLAYPI_SSH_KEY) if it exists – no password prompt.
set -Eeuo pipefail

cd "$(dirname "$0")"

host=${SHOWPLAYPI_HOST:-}
flags=()
with_boot=""
with_ini=""

for arg in "$@"; do
    case $arg in
        -n|--dry-run) flags+=(--dry-run) ;;
        --no-restart) flags+=(--no-restart) ;;
        --boot) with_boot=yes ;;
        --ini) with_ini=yes ;;
        -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        -*) echo "Unknown option: $arg" >&2; exit 2 ;;
        *@*) host=$arg ;;
        *) host=admin@$arg ;;
    esac
done

if [[ -z $host ]]; then
    echo "Which Pi? ./deploy.sh <device name or IP>, e.g. ./deploy.sh showplaypi-e84042.local" >&2
    exit 2
fi

if [[ -n $with_ini && -z $with_boot ]]; then
    echo "--ini only works together with --boot" >&2
    exit 2
fi

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

cp -r rootfs meta scripts deploy services.txt "$stage/"
# The template of showplaypi.ini is also the delivery state used by the factory reset
install -D -m 644 bootfs/showplaypi.ini "$stage/rootfs/usr/share/showplaypi/showplaypi.ini.default"
if [[ -n $with_boot ]]; then
    cp -r bootfs "$stage/bootfs"
    [[ -n $with_ini ]] || rm -f "$stage/bootfs/showplaypi.ini"
fi
git describe --tags --always --dirty > "$stage/GIT_VERSION" 2>/dev/null || echo unknown > "$stage/GIT_VERSION"

echo "Deploying $(cat "$stage/GIT_VERSION") -> $host"

# Every flashed image gets new host keys under the same name – so no host key check.
ssh_opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)
# Optional development key (no password prompt): SHOWPLAYPI_SSH_KEY or ~/.ssh/showplaypi_ed25519
key=${SHOWPLAYPI_SSH_KEY:-$HOME/.ssh/showplaypi_ed25519}
[[ -f $key ]] && ssh_opts+=(-i "$key")

tar -czf - -C "$stage" . |
    ssh "${ssh_opts[@]}" "$host" \
        "d=\$(mktemp -d) && tar -xzf - -C \"\$d\" 2>/dev/null && sudo bash \"\$d/deploy/remote-apply.sh\" \"\$d\" ${flags[*]:-}; rc=\$?; rm -rf \"\$d\"; exit \$rc"

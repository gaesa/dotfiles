#!/usr/bin/env bash
set -euo pipefail

( # `--new-session` doesn't work
    exec bwrap \
        --ro-bind /usr/bin /usr/bin \
        --ro-bind /usr/share/ /usr/share/ \
        --ro-bind /usr/lib /usr/lib \
        --ro-bind /usr/lib64 /usr/lib64 \
        --symlink /usr/bin /bin \
        --symlink /usr/lib64 /lib64 \
        --proc /proc \
        --ro-bind ~/.config ~/.config \
        --ro-bind "$PWD" "$PWD" \
        --dev-bind /dev/tty /dev/tty \
        --dev-bind /dev/null /dev/null \
        --dev-bind /tmp /tmp \
        --bind ~/.cache/lf_thumb ~/.cache/lf_thumb \
        --bind ~/.config/lf/__pycache__ ~/.config/lf/__pycache__ \
        --unshare-all \
        --die-with-parent \
        ~/.config/lf/preview.py "$@"
)

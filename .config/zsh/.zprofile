# vim:foldmethod=marker:foldlevel=0
umask 077

# XDG {{{
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR="/run/user/$UID"
#}}}

# Podman {{{
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
export DOCKER_BUILDKIT=0
#}}}

# Make the user instance of systemd and dbus daemon inherit above environment variables {{{
dbus-update-activation-environment --systemd --all
#}}}

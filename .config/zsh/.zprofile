# vim:foldmethod=marker:foldlevel=0
umask 077

# XDG {{{
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR="/run/user/$UID"
#}}}

# Gui programs {{{
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export TEXMACS_HOME_PATH="$XDG_STATE_HOME/texmacs"
#}}}

# Wayland {{{
export CLUTTER_BACKEND='wayland'
export GDK_BACKEND='wayland,x11'
export QT_QPA_PLATFORM='wayland;xcb'
export MOZ_ENABLE_WAYLAND=1
export GTK_USE_PORTAL=1
export QT_WAYLAND_FORCE_DPI=120
#}}}

# Input method {{{
export GTK_IM_MODULE='fcitx'
export QT_IM_MODULE='fcitx'
export XMODIFIERS='@im=fcitx'
export SDL_IM_MODULE='fcitx'
export GLFW_IM_MODULE='ibus'
export FCITX_SOCKET="$XDG_RUNTIME_DIR"
#}}}

# Hardware {{{
export LIBVA_DRIVER_NAME='iHD'
# #}}}

# Podman {{{
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
export DOCKER_BUILDKIT=0
#}}}

# Make the user instance of systemd and dbus daemon inherit above environment variables {{{
dbus-update-activation-environment --systemd --all
#}}}

# Start KDE from TTY {{{
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startplasma-wayland &>"$XDG_CACHE_HOME/startup.log"
fi
#}}}

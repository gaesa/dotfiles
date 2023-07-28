# vim:foldmethod=marker:foldlevel=0
umask 077

#env >/tmp/env-pre.log
# Clean env {{{
typeset -A preserve=(
    "HOME" 1
    "USER" 1
    "SHELL" 1
    "TERM" 1
    "PATH" 1
    "MAIL" 1
    "LOGNAME" 1
    "MOTD_SHOWN" 1
    "XDG_SESSION_ID" 1
    "XDG_RUNTIME_DIR" 1
    "DBUS_SESSION_BUS_ADDRESS" 1
    "XDG_SESSION_TYPE" 1
    "XDG_SESSION_CLASS" 1
    "XDG_SEAT" 1
    "XDG_VTNR" 1
    "SHLVL" 1
    "PWD" 1
    "OLDPWD" 1
    "XDG_CONFIG_HOME" 1
    "ZDOTDIR" 1 #affects ttys other than `/dev/tty1`
    "XDG_CACHE_HOME" 1
    "XDG_DATA_HOME" 1
    "XDG_STATE_HOME" 1
    "DEBUGINFOD_URLS" 1
    "XDG_DATA_DIRS" 1
    "LANG" 1
    "LANGUAGE" 1
    "LC_PAPER" 1
    "NIX_PROFILES" 1
    "NIX_SSL_CERT_FILE" 1
)

array=("${(f)$(/usr/bin/env)}")
for elem in "${(@)array}"; do
    elem="${elem%%=*}"
    if [[ ! -v preserve["${elem}"] ]]; then
        unset "${elem}"
    fi
done
unset preserve array elem
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
#}}}

# Podman {{{
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
export DOCKER_BUILDKIT=0
#}}}

# Make the user instance of systemd and dbus daemon inherit above environment variables {{{
dbus-update-activation-environment --systemd --all
#}}}
#env >/tmp/env-post.log

# Start KDE from TTY {{{
if [[ -z "$WAYLAND_DISPLAY" ]] && [[ "$(tty)" = "/dev/tty1" ]]; then
    exec startplasma-wayland &>"$XDG_CACHE_HOME/startup.log"
fi
#}}}

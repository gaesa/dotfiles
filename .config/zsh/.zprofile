# vim:foldmethod=marker:foldlevel=1
umask 077

#env >/tmp/env-pre.log
# Clean env {{{
# preserved env {{{
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
    "XDG_CONFIG_HOME" 1
    "ZDOTDIR" 1 #affects ttys other than `/dev/tty1`
    "XDG_CACHE_HOME" 1
    "XDG_DATA_HOME" 1
    "XDG_STATE_HOME" 1
    "TMPDIR" 1
    "DEBUGINFOD_URLS" 1
    "XDG_DATA_DIRS" 1
    "LANG" 1
    "LANGUAGE" 1
    "LC_PAPER" 1
    "NIX_PROFILES" 1
    "NIX_SSL_CERT_FILE" 1
)
# }}}

array=("${(f)$(/usr/bin/env)}")
for elem in "${(@)array}"; do
    elem="${elem%%=*}"
    if [[ ! -v preserve["${elem}"] ]]; then
        unset "${elem}"
    fi
done
unset preserve array elem
# }}}

# set path {{{
path=()
if [[ -d "$HOME/.nix-profile/bin" ]]; then
    path+=("$HOME/.nix-profile/bin")
fi
if [[ -d '/nix/var/nix/profiles/default/bin' ]]; then
    path+=('/nix/var/nix/profiles/default/bin')
fi
path+=('/usr/local/bin' '/usr/bin' "$HOME/.local/bin")
# }}}

# Set env in batch {{{
typeset -A my_env=(
    # Gui programs {{{
    'GTK2_RC_FILES' "$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
    # }}}

    # Wayland {{{
    'CLUTTER_BACKEND' 'wayland'
    'GDK_BACKEND' 'wayland,x11'
    'QT_QPA_PLATFORM' 'wayland;xcb'
    'MOZ_ENABLE_WAYLAND' 1
    'GTK_USE_PORTAL' 1
    'QT_WAYLAND_FORCE_DPI' 120
    # }}}

    # Input method {{{
    'GTK_IM_MODULE' 'fcitx'
    'QT_IM_MODULE' 'fcitx'
    'XMODIFIERS' '@im=fcitx'
    'SDL_IM_MODULE' 'fcitx'
    'GLFW_IM_MODULE' 'ibus'
    'FCITX_SOCKET' "$TMPDIR"
    # }}}

    # Hardware {{{
    'LIBVA_DRIVER_NAME' 'iHD'
    # }}}
)

for key val in "${(@kv)my_env}"; do
    export "$key"="$val"
done
unset my_env key val
# }}}

# Make the user instance of systemd and dbus daemon inherit above environment variables {{{
dbus-update-activation-environment --systemd --all
# }}}
#env >/tmp/env-post.log

# Start KDE from TTY {{{
if [[ -z "$WAYLAND_DISPLAY" ]] && [[ "$(tty)" = "/dev/tty1" ]]; then
    chmod u+w "$HOME"
    # See also:
    # https://bugs.kde.org/show_bug.cgi?id=415770
    # https://bugs.kde.org/show_bug.cgi?id=417534
    exec startplasma-wayland &>"$XDG_CACHE_HOME/startup.log"
fi
# }}}

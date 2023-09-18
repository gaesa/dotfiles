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
    "SHLVL" 1
    "PWD" 1
    "OLDPWD" 1
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
unset array elem
# }}}

# Podman {{{
export DOCKER_HOST="unix://$TMPDIR/podman/podman.sock"
export DOCKER_BUILDKIT=0
# }}}

# Make the user instance of systemd inherit above environment variables {{{
[[ -v DBUS_SESSION_BUS_ADDRESS ]] && systemctl --user import-environment "${(@k)preserve}" DOCKER_HOST DOCKER_BUILDKIT 2>/dev/null
unset preserve
# }}}
#env >/tmp/env-post.log

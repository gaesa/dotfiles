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
unset array elem
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

# Make the user instance of systemd inherit above environment variables {{{
[[ -v DBUS_SESSION_BUS_ADDRESS ]] && systemctl --user import-environment "${(@k)preserve}" 2>/dev/null
unset preserve
# }}}
#env >/tmp/env-post.log

# Source .zshenv after `sudo -i` or `ssh` {{{
detect_ssh() {
    output="$(loginctl session-status)"
    session_id=${output%% *} # first word is the session_id
    if [[ "$(loginctl show-session -P Service $session_id)" == "sshd" ]]; then
        return 0
    else
        return 1
    fi
}

if [[ $USER == "root" ]]; then
    source "$ZDOTDIR/.zshenv"
    unset -f detect_ssh
    echo
elif detect_ssh; then
    source "$ZDOTDIR/.zshenv"
    unset -f detect_ssh
else
    unset -f detect_ssh
fi
# }}}

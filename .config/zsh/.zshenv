# vim:foldmethod=marker:foldlevel=1

# Set env in batch {{{
# Evaluation dependencies {{{
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_RUNTIME_DIR="/run/user/$UID"
# }}}
typeset -A my_env=(
    # XDG & ZDOT & TMPDIR {{{
    'ZDOTDIR' "$XDG_CONFIG_HOME/zsh"
    'XDG_CACHE_HOME' "$HOME/.cache"
    'XDG_DATA_HOME' "$HOME/.local/share"
    'XDG_STATE_HOME' "$HOME/.local/state"
    'TMPDIR' "$XDG_RUNTIME_DIR"
    # }}}

    # Clean up my home {{{
    'TERMINFO' "$XDG_DATA_HOME/terminfo"
    'TERMINFO_DIRS' "$XDG_DATA_HOME/terminfo:/usr/share/terminfo"
    'GOPATH' "$XDG_DATA_HOME/go"
    'CARGO_HOME' "$XDG_DATA_HOME/cargo"
    'RUSTUP_HOME' "$XDG_DATA_HOME/rustup"
    'NPM_CONFIG_USERCONFIG' "$XDG_CONFIG_HOME/npm/npmrc"
    'NODE_REPL_HISTORY' "$XDG_STATE_HOME/node/repl_history"
    'TS_NODE_HISTORY' "$XDG_STATE_HOME/ts-node/repl_history"
    '_JAVA_OPTIONS' "-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"
    'GNUPGHOME' "$XDG_DATA_HOME/gnupg"
    'ncmpcpp_directory' "$XDG_CONFIG_HOME/ncmpcpp"
    'W3M_DIR' "$XDG_STATE_HOME/w3m"
    'CUDA_CACHE_PATH' "$XDG_CACHE_HOME/nv"
    'ANDROID_HOME' "$XDG_DATA_HOME/android"
    'WGETRC' "$XDG_CONFIG_HOME/wget/wgetrc"
    'RIPGREP_CONFIG_PATH' "$XDG_CONFIG_HOME/ripgrep/ripgreprc"
    # }}}

    # Terminal {{{
    'EDITOR' 'nvim'
    'PAGER' 'less'
    # Note: The `SYSTEMD_LESS` cannot override the options
    # passed to 'less' if the `LESS` is set by the `lesskey` file.
    'MANPAGER' 'nvim +Man!'
    # }}}

    # Start ssh-agent with systemd user {{{
    'SSH_AUTH_SOCK' "$XDG_RUNTIME_DIR/ssh-agent.socket"
    # }}}

    # Python {{{
    'PYTHONPATH' "$XDG_DATA_HOME/python/lib"
    'PYTHONSTARTUP' "$XDG_CONFIG_HOME/python/startup.py"
    'PYTHONPYCACHEPREFIX' "$XDG_CACHE_HOME/python"
    'PYTHONUSERBASE' "$XDG_DATA_HOME/python"
    'PYTHON_KEYRING_BACKEND' 'keyring.backends.null.Keyring'
    # }}}
)
for key val in "${(@kv)my_env}"; do
    export "$key"="$val"
done
unset my_env key val
# }}}

# Clean up home by alias {{{
alias chez="chez --eehistory $XDG_STATE_HOME/chez/history"
# }}}

# path+ {{{
typeset -U path PATH # make entries unique

# initialize {{{
path=()
if [[ -d "$HOME/.nix-profile/bin" ]]; then
    path+=("$HOME/.nix-profile/bin")
fi
if [[ -d '/nix/var/nix/profiles/default/bin' ]]; then
    path+=('/nix/var/nix/profiles/default/bin')
fi
path+=("$HOME/.local/bin" '/usr/local/bin' '/usr/bin')
# }}}

add_paths (){
    local -r paths=$1 # fuck shell
    for added_path in "${(@P)paths}"; do
        if [[ -d "$added_path" ]] && (( ${paths[(i)$added_path]} > ${#paths} )); then
            path+=("$added_path")
        fi
    done
    unset added_path
}
local added_paths=(
    '.' #current directory
    '/opt/bin' #add-on application software packages path
    "$XDG_DATA_HOME/cargo/bin"
)
add_paths added_paths
unset -f add_paths && unset added_paths
# }}}

# vim:fileencoding=utf-8:foldmethod=marker

# XDG & ZDOT {{{
export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR="/run/user/$UID"

# Clean up my home {{{
export TERMINFO="$XDG_DATA_HOME/terminfo"
export TERMINFO_DIRS="$XDG_DATA_HOME/terminfo:/usr/share/terminfo"
export GOPATH="$XDG_DATA_HOME/go"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
alias chez="chez --eehistory $XDG_STATE_HOME/chez/history"
export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export ncmpcpp_directory="$XDG_CONFIG_HOME/ncmpcpp"
export W3M_DIR="$XDG_STATE_HOME/w3m"
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
export ANDROID_HOME="$XDG_DATA_HOME/android"
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgreprc"
#}}}

# Terminal {{{
export EDITOR='nvim'
export BROWSER='librewolf'
export PAGER='less'
# Note: The `SYSTEMD_LESS` cannot override the options
# passed to 'less' if the `LESS` is set by the `lesskey` file.
export MANPAGER='nvim +Man!'
#}}}

# Start ssh-agent with systemd user {{{
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
#}}}

# Fix MAIL when using 'sudo su' {{{
export MAIL="/var/spool/mail/${USER}"
#}}}
#}}}

# path+ {{{
typeset -U path PATH # make entries unique
add_paths (){
    local -r paths=$1 # fuck shell
    for added_path in "${(@P)paths}"; do
        if [[ -d "$added_path" ]] && (( ${paths[(i)$added_path]} > ${#paths} )); then
            path+=("$added_path")
        fi
    done
}
local added_paths=(
    "$HOME/.local/bin" #scripts path
    '.' #current directory
    '/opt/bin' #add-on application software packages path
    "$XDG_CONFIG_HOME/emacs/bin" #doom emacs
    "$XDG_DATA_HOME/cargo/bin"
)
add_paths added_paths
unset -f add_paths && unset added_paths
#}}}

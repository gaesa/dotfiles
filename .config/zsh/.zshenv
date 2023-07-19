# vim:fileencoding=utf-8:foldmethod=marker

# Export {{{
export ZDOTDIR="$HOME/.config/zsh"

# Clean up my home {{{
export TERMINFO="$XDG_DATA_HOME/terminfo"
export TERMINFO_DIRS="$XDG_DATA_HOME/terminfo:/usr/share/terminfo"
export GOPATH="$XDG_DATA_HOME/go"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
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
export PAGER='less -R'
export LESS='-R'
export MANPAGER='nvim +Man!'
export SYSTEMD_LESS='FRXMK'
#}}}

# Start ssh-agent with systemd user {{{
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
#}}}

# Fix MAIL when using 'sudo su' {{{
export MAIL="/var/spool/mail/${USER}"
#}}}
#}}}

# path+ {{{
add_paths (){
    local -r paths=("$@") # fucking shell
    for added_path in $paths; do # fucking shell
        if [[ -d "$added_path" && ":$PATH:" != *":$added_path:"* ]]; then
            path+=("$added_path")
        fi
    done
}
local added_paths=(
    "$HOME/.local/bin" #scripts path
    '.' #current directory
    '/opt/bin' #add-on application software packages path
    "$XDG_DATA_HOME/cargo/bin"
)
add_paths $added_paths # fucking shell
unset -f add_paths && unset added_paths
#}}}

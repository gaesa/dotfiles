# vim:fileencoding=utf-8:foldmethod=marker
# Export {{{
export ZDOTDIR="$HOME/.config/zsh"

# Clean up my home
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR="/run/user/$UID"

export TERMINFO="$XDG_DATA_HOME/terminfo"
export TERMINFO_DIRS="$XDG_DATA_HOME/terminfo:/usr/share/terminfo"
export GOPATH="$XDG_DATA_HOME/go"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export ncmpcpp_directory="$XDG_CONFIG_HOME/ncmpcpp"
export LYNX_CFG_PATH="$XDG_CONFIG_HOME/lynx.cfg"
export W3M_DIR="$XDG_STATE_HOME/w3m"
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"
export ANDROID_HOME="$XDG_DATA_HOME/android"
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgreprc"
export TEXMACS_HOME_PATH="$XDG_STATE_HOME/texmacs"

# Terminal
export EDITOR='nvim'
export BROWSER='librewolf'
export PAGER='less -R'
export LESS='-R'
export MANPAGER='nvim +Man!'
export SYSTEMD_LESS='FRXMK'

# Start ssh-agent with systemd user
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Podman
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
export DOCKER_BUILDKIT=0

# Fix MAIL when using 'sudo su'
export MAIL="/var/spool/mail/${USER}"
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
    "$HOME/.config/emacs/bin" #doom emacs
    "$HOME/.local/share/cargo/bin"
)
add_paths $added_paths # fucking shell
unset -f add_paths && unset added_paths
#}}}

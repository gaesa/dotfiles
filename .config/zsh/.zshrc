# vim:foldmethod=marker:foldlevel=1

# Initialization {{{
umask 077

# Disable Ctrl-S in interactive shells
setopt NOFLOWCONTROL
stty -ixon

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Create directories if necessary
[[ ! -d "$XDG_STATE_HOME/zsh" ]] && mkdir -p "$XDG_STATE_HOME/zsh"
[[ ! -d "$XDG_CACHE_HOME/zsh" ]] && mkdir -p "$XDG_CACHE_HOME/zsh"
[[ ! -d "$ZDOTDIR" ]] && mkdir -p "$ZDOTDIR"
# }}}

# History {{{
# Remove older command from the history if a duplicate is to be added.
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# Share history in multiple shells
setopt SHARE_HISTORY
setopt CORRECT
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=10000
SAVEHIST=$HISTSIZE
# }}}

# Completion {{{
setopt AUTOCD       # Automatically cd into typed directory.
setopt INTERACTIVE_COMMENTS
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
# Allow different columns of completion menu to have different widths
setopt LIST_PACKED
setopt MENU_COMPLETE # not flexible but there is no need for clearing zsh completion after typing a character
# Prevents aliases on the command line from being internally substituted before completion is attempted
# See also: https://unix.stackexchange.com/questions/250314/whats-the-intended-use-case-for-complete-aliases-in-zsh
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%K{#939F91} %d %k'
zstyle ':completion:*' list-dirs-first true
#zstyle ':completion:*' file-sort modification
zstyle ':completion:*' group-order local-directories
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*:processes' command 'ps -U $(whoami)|sed "/ps/d"'
zstyle ':completion:*:processes' insert-ids menu yes select
zstyle ':completion:*:processes-names' command 'ps xho command|sed "s/://g"'
zstyle ':completion:*:processes' sort false
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME"/zsh/zcompcache
zmodload zsh/complist
setopt GLOBDOTS # Include hidden files
# Use Shift-Tab to access previous completion entries
bindkey -M menuselect '^[[Z' reverse-menu-complete
# Use Esc to cancel completion
bindkey -M menuselect '^[' undo

# Fix completion for some programs
compdef "_files _directories" trash

# Get files completion from specific path
compdef "_files -W $HOME/.local/bin" srp

# Git
compdef g=git
# }}}

# Input {{{
# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -v

# 10 ms for key sequences
KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
# Default vi mode causes backspace in zsh stuck
bindkey -v '^?' backward-delete-char
# Default '^H' (vi-backward-delete-char) is stuck
# after accepting suggestions
bindkey -v '^H' backward-delete-char
# Default '^W' is stuck after accepting suggestions
bindkey -v '^W' backward-kill-word
bindkey -v '^[d' kill-word
bindkey -v '^U' backward-kill-line
bindkey -v '^K' kill-line
bindkey -v '^A' beginning-of-line
bindkey -v '^E' end-of-line
bindkey -v '^B' backward-char
bindkey -v '^F' forward-char
bindkey -v '^[b' backward-word
bindkey -v '^[f' forward-word

# Change cursor shape for different vi modes.
function zle-keymap-select() {
    case $KEYMAP in
        vicmd) echo -ne '\e[2 q' ;;      # block
        viins|main) echo -ne '\e[6 q' ;; # beam
    esac
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne '\e[6 q'
}
zle -N zle-line-init
echo -ne '\e[6 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[6 q'; } # Use beam shape cursor for each new prompt.

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^[e' edit-command-line
bindkey -M vicmd '^[e' edit-command-line

# Default wordchars is bad as it contains `/`, `_`, `-`, `.`
WORDCHARS='*?[]~=&;!#$%^(){}<>'

# Shortcut to exit shell on partial command line
# See https://github.com/kovidgoyal/kitty/issues/378
# https://github.com/romkatv/powerlevel10k/issues/274
# Chage the option 'close_on_child_death no' in kitty.conf to mitigate
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh
# }}}

# Plugins {{{
# Fzf {{{

export FZF_DEFAULT_OPTS=''
# Change theme related configurations depending on time
source "$HOME/.local/bin/switch-theme"
# See why '/proc' need to be excluded:
# https://github.com/sharkdp/fd/issues/288
export FZF_DEFAULT_COMMAND="fd --type f -H --strip-cwd-prefix --exclude='/proc' --exclude='/mnt' --exclude='.git' --exclude='.snapshots' --exclude='.stversions' --exclude='.stfolder' --exclude='.var' --exclude='.local/share/Trash' --exclude='.cache' --exclude='Cache' --exclude='cache' --exclude='RecentDocuments' --exclude='.local/share/okular/docdata'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d -H --exclude='.git' --exclude='.snapshots' --exclude='.stversions' --exclude='.stfolder' --exclude='.var' --exclude='.local/share/Trash' --exclude='.cache' --exclude='Cache' --exclude='cache' --exclude='RecentDocuments' --exclude='.local/share/okular/docdata'"

_fzf_compgen_dir() {
    fd --type d -H --exclude='.git' --exclude='.snapshots' --exclude='.stversions' --exclude='.stfolder' --exclude='.var' --exclude='.local/share/Trash' --exclude='.cache' --exclude='Cache' --exclude='cache' . "$1"
}
_fzf_compgen_path() {
    fd -H --exclude='.git' --exclude='.snapshots' --exclude='.stversions' --exclude='.stfolder' --exclude='.var' --exclude='.local/share/Trash' --exclude='.cache' --exclude='Cache' --exclude='cache' . "$1"
}

# The default key binding ctrl-r is bad because it is occupied by redo in zsh's vi mode
# source /usr/share/fzf/key-bindings.zsh
source "$ZDOTDIR/plugins/fzf/key-bindings.zsh"
source '/usr/share/fzf/completion.zsh'
# }}}

# "command not found" handler
source '/usr/share/doc/pkgfile/command-not-found.zsh'

# zoxide
eval "$(zoxide init zsh)"

# direnv
eval "$(direnv hook zsh)"

# zsh-syntax-highlighting
# It must be sourced after all custom widgets have been created
# (i.e., after all zle -N calls and after running compinit)
# in order to be able to wrap all of them.
# It must be sourced (and register its hook) after anything else
# that adds hooks that modify the command-line buffer.
source '/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'

# zsh-history-substring-search
# See why this plugin is placed after zsh-syntax-highlighting:
# https://github.com/zsh-users/zsh-history-substring-search
source '/usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh'
bindkey '^[[A' history-substring-search-up
bindkey '^P' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^N' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# zsh-autosuggestions
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#7A8478'
source '/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh'

# zsh-theme-powerlevel10k
source '/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme'
# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
if [[ "$TERM" != 'linux' ]]; then
    [[ -f "$ZDOTDIR/p10k.zsh" ]] && source "$ZDOTDIR/p10k.zsh"
else
    [[ -f "$ZDOTDIR/p10k_tty.zsh" ]] && source "$ZDOTDIR/p10k_tty.zsh"
fi
# }}}

# User files {{{
[[ -f "$ZDOTDIR/privaterc" ]] && source "$ZDOTDIR/privaterc"
[[ -f "$ZDOTDIR/hookrc" ]] && source "$ZDOTDIR/hookrc"
[[ -f "$ZDOTDIR/aliasrc" ]] && source "$ZDOTDIR/aliasrc"
[[ -f "$ZDOTDIR/functionrc" ]] && source "$ZDOTDIR/functionrc"
# }}}

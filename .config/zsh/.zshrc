umask 077

if [[ -t 0 && $- = *i* ]]
then
    stty -ixon
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Create directories if necessary
[[ ! -d "$XDG_STATE_HOME/zsh" ]] && mkdir -p "$XDG_STATE_HOME/zsh"
[[ ! -d "$XDG_CACHE_HOME/zsh" ]] && mkdir -p "$XDG_CACHE_HOME/zsh"
[[ ! -d "$XDG_CONFIG_HOME/zsh" ]] && mkdir -p "$XDG_CONFIG_HOME/zsh"


# History
#
# Remove older command from the history if a duplicate is to be added.
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY 
# Share history in multiple shells
setopt share_history
setopt correct
export HISTFILE="$XDG_STATE_HOME"/zsh/history
export HISTSIZE=5000
export SAVEHIST="$HISTSIZE"

# Basic auto/tab complete:
setopt autocd		# Automatically cd into typed directory.
setopt interactive_comments
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump-"$ZSH_VERSION"
#setopt glob_complete
setopt menu_complete # not flexible but there is no need for clearing zsh completion after typing a character
setopt complete_aliases # enable completion for aliases e.g. the path completion in "g add PATH"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME"/zsh
# smarter cd: zoxide
eval "$(zoxide init zsh)"
zmodload zsh/complist
setopt globdots # Include hidden files.
# use shift-tab to access previous completion entries
bindkey -M menuselect '^[[Z' reverse-menu-complete
# use Esc to cancel completion
bindkey -M menuselect '^[' undo

# On-demand rehash
zshcache_time="$(date +%s%N)"
autoload -Uz add-zsh-hook
rehash_precmd() {
  if [[ -a /var/cache/zsh/pacman ]]; then
    local paccache_time="$(date -r /var/cache/zsh/pacman +%s%N)"
    if (( zshcache_time < paccache_time )); then
      rehash
      zshcache_time="$paccache_time"
    fi
  fi
}
add-zsh-hook -Uz precmd rehash_precmd

# Input/output
#
# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -v

# 10 ms for key sequences
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
# default vi mode causes backspace in zsh stuck
bindkey -v '^?' backward-delete-char

# default wordchars is bad as it contains slash
WORDCHARS=$WORDCHARS:s:/:
# bind ctrl+backspace to delete the previous word
bindkey '^H' backward-kill-word

# Change cursor shape for different vi modes.
function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[2 q';;      # block
        viins|main) echo -ne '\e[6 q';; # beam
    esac
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[6 q"
}
zle -N zle-line-init
echo -ne '\e[6 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[6 q' ;} # Use beam shape cursor for each new prompt.

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey -M vicmd '^[[P' vi-delete-char
bindkey -M vicmd '^e' edit-command-line
bindkey -M visual '^[[P' vi-delete

# Shortcut to exit shell on partial command line
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh

# Search with fzf
# The default key binding ctrl-r is bad because it is occupied by redo in zsh's vi mode
# source /usr/share/fzf/key-bindings.zsh
source "$ZDOTDIR"/plugins/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_OPTS=''
if [[ "$(date +%H:%M)" > "05:30" ]] && [[ "$(date +%H:%M)" < "18:00" ]]; then
	export FZF_DEFAULT_OPTS='--bind=alt-j:down,alt-k:up --color=light --height 40% --reverse --multi'
	export FZF_CTRL_R_OPTS='--color=light'
	export FZF_ALT_C_OPTS='--color=light --preview "tree -C {} | head -200"'
	theme light
else
	export FZF_DEFAULT_OPTS='--bind=alt-j:down,alt-k:up --color=dark --height 40% --reverse --multi'
	export FZF_CTRL_R_OPTS='--color=dark'
	export FZF_ALT_C_OPTS='--color=dark --preview "tree -C {} | head -200"'
	theme dark
fi
export FZF_DEFAULT_COMMAND='fd --type f -H --strip-cwd-prefix --exclude ".git" --exclude ".snapshots" --exclude ".stversions" --exclude ".stfolder" --exclude "tim-sounds"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d -H --exclude ".git" --exclude ".snapshots" --exclude ".stversions" --exclude ".stfolder" --exclude "tim-sounds"'
_fzf_compgen_dir() {
  fd --type d -H --exclude ".git" --exclude ".snapshots" --exclude ".stversions" --exclude ".stfolder" --exclude "tim-sounds" . "$1"
}

_fzf_compgen_path() {
  fd -H --exclude ".git" --exclude ".snapshots" --exclude ".stversions" --exclude ".stfolder" --exclude "tim-sounds" . "$1"
}

# Load aliases and functions if existent.
[ -f "$HOME/.config/zsh/functionrc" ] && source "$HOME/.config/zsh/functionrc"
[ -f "$HOME/.config/zsh/aliasrc" ] && source "$HOME/.config/zsh/aliasrc"
[ -f "$HOME/.config/zsh/privaterc" ] && source "$HOME/.config/zsh/privaterc"

source /usr/share/doc/pkgfile/command-not-found.zsh

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
#if [[ "$(date +%H:%M)" < "05:30" ]] || [[ "$(date +%H:%M)" > "18:00" ]]; then
	export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#7A8478"
#fi

source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh

# It must be sourced after all custom widgets have been created
# (i.e., after all zle -N calls and after running compinit)
# in order to be able to wrap all of them.
# It must be sourced (and register its hook) after anything else
# that adds hooks that modify the command-line buffer.
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# See why this plugin is placed after zsh-syntax-highlighting:
# https://github.com/zsh-users/zsh-history-substring-search
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

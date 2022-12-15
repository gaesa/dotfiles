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
export HISTFILE="$XDG_STATE_HOME"/zsh/history
export HISTSIZE=5000
export SAVEHIST=$HISTSIZE

# Basic auto/tab complete:
setopt autocd		# Automatically cd into typed directory.
setopt interactive_comments
autoload -Uz compinit
compinit -d $XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' cache-path $XDG_CACHE_HOME/zsh/zcompcache
zmodload zsh/complist
_comp_options+=(globdots)		# Include hidden files.
# use shift-tab to access previous completion entries
bindkey -M menuselect '^[[Z' reverse-menu-complete

# Disabling suggestion for large buffers
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

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
# bindkey -M menuselect 'j' vi-down-line-or-history
# bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -v '^?' backward-delete-char


# bind ctrl+backspace to delete the previous word
bindkey '^H' backward-kill-word

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.


# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

# Shortcut to exit shell on partial command line
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh

# Search with fzf
source /usr/share/fzf/key-bindings.zsh 
source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_OPTS='--height 40% --reverse --multi'
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --exclude .git --exclude sound-windows --exclude .snapshots --exclude .bak'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

_fzf_compgen_dir() {
  fd --type d --exclude ".git" --exclude "sound-windows" . "$1"
}

_fzf_compgen_path() {
  fd --exclude ".git" --exclude "sound-windows" . "$1"
}


# Load aliases and functions if existent.
[ -f "$HOME/.config/zsh/functionrc" ] && source "$HOME/.config/zsh/functionrc"
[ -f "$HOME/.config/zsh/aliasrc" ] && source "$HOME/.config/zsh/aliasrc"
[ -f "$HOME/.config/zsh/privaterc" ] && source "$HOME/.config/zsh/privaterc"

source /usr/share/doc/pkgfile/command-not-found.zsh
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# Should be at the end
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
#source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# History substring search
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh

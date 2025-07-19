#!/usr/bin/env bash
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# Rust
if [[ ":$PATH:" != *":$XDG_DATA_HOME/cargo/bin:"* ]]; then
    export PATH="$PATH:$XDG_DATA_HOME/cargo/bin"
fi

# Python
export PYTHONPATH="$XDG_DATA_HOME/python/lib"
export PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME/python"
export PYTHONUSERBASE="$XDG_DATA_HOME/python"

# GUI
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"

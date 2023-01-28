umask 077

# Clean up my home
export XDG_CONFIG_HOME="$HOME"/.config
export XDG_CACHE_HOME="$HOME"/.cache
export XDG_DATA_HOME="$HOME"/.local/share
export XDG_STATE_HOME="$HOME"/.local/state
export XDG_RUNTIME_DIR=/run/user/$UID

export TERMINFO="$XDG_DATA_HOME"/terminfo
export TERMINFO_DIRS="$XDG_DATA_HOME"/terminfo:/usr/share/terminfo
export GOPATH="$XDG_DATA_HOME"/go
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export ncmpcpp_directory="$XDG_CONFIG_HOME"/ncmpcpp
export LYNX_CFG_PATH="$XDG_CONFIG_HOME"/lynx.cfg
export CUDA_CACHE_PATH="$XDG_CACHE_HOME"/nv
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
export ANDROID_HOME="$XDG_DATA_HOME"/android
export WGETRC="$XDG_CONFIG_HOME"/wget/wgetrc
export PYENV_ROOT="$XDG_DATA_HOME"/pyenv

# Add scripts path
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    path+=("$HOME/.local/bin")
fi

# Add add-on application software packages path
if [[ ":$PATH:" != *":/opt/bin:"* ]]; then
    path+=("/opt/bin")
fi

# Terminal
export EDITOR=nvim
export BROWSER=librewolf
export PAGER=less
export SYSTEMD_LESS=FRXMK

# Start ssh-agent with systemd user
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Podman
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
export DOCKER_BUILDKIT=0

# Fcitx5
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus
export FCITX_SOCKET=/tmp

# Wayland
export CLUTTER_BACKEND=wayland
export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORM="wayland;xcb"
export MOZ_ENABLE_WAYLAND=1

export GTK_USE_PORTAL=1
export QT_WAYLAND_FORCE_DPI=120

# Nvidia on wayland
# many compositors (including Mutter and KWin) started using GBM by default for NVIDIA ≥ 495
# GBM_BACKEND=nvidia-drm
# __GLX_VENDOR_LIBRARY_NAME=nvidia

# Make the user instance of systemd and dbus daemon inherit above environment variables
dbus-update-activation-environment --systemd --all

# Start KDE from TTY
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startplasma-wayland
fi

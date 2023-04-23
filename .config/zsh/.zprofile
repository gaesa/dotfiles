umask 077

source "$ZDOTDIR/.zshenv"

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
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startplasma-wayland &>"${HOME}"/.cache/startup.log
fi

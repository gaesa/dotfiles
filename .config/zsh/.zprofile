umask 077

source "$ZDOTDIR/.zshenv"

# Make the user instance of systemd and dbus daemon inherit above environment variables
dbus-update-activation-environment --systemd --all

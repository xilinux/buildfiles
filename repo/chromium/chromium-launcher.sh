#!/bin/sh

export DBUS_SESSION_BUS_ADDRES=unix:path=/run/dbus/system_bus_socket

# Allow the user to override command-line flags, bug #357629.
# This is based on Debian's chromium-browser package, and is intended
# to be consistent with Debian.
for f in /etc/chromium/*.conf; do
    [ -f ${f} ] && . "${f}"
done

# Prefer user defined CHROMIUM_USER_FLAGS (from env) over system
# default CHROMIUM_FLAGS (from /etc/chromium/default).
CHROMIUM_FLAGS=${CHROMIUM_USER_FLAGS:-"$CHROMIUM_FLAGS"}

# Let the wrapped binary know that it has been run through the wrapper
export CHROME_WRAPPER=$(readlink -f "$0")

PROGDIR=${CHROME_WRAPPER%/*}

case ":$PATH:" in
  *:$PROGDIR:*)
    # $PATH already contains $PROGDIR
    ;;
  *)
    # Append $PROGDIR to $PATH
    export PATH="$PATH:$PROGDIR"
    ;;
esac

if [ $(id -u) -eq 0 ] && [ $(stat -t -L ${XDG_CONFIG_HOME:-${HOME}} | cut -d' ' -f5) -eq 0 ]; then
	# Running as root with HOME owned by root.
	# Pass --user-data-dir to work around upstream failsafe.
	CHROMIUM_FLAGS="--user-data-dir=${XDG_CONFIG_HOME:-${HOME}/.config}/chromium
		${CHROMIUM_FLAGS}"
fi

# Set the .desktop file name
export CHROME_DESKTOP="chromium.desktop"

exec "$PROGDIR/chromium" --extra-plugin-dir=/usr/lib/nsbrowser/plugins ${CHROMIUM_FLAGS} "$@"

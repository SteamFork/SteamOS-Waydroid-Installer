#!/bin/bash

export SHORTCUT=${1}

killall -9 cage >/dev/null 2>&1

sudo /usr/bin/waydroid-container-stop
sudo /usr/bin/waydroid-container-start

export MY_RESOLUTION="$(xrandr | awk '/*/ {a=$1} END{print a}')"
echo "Resolution: ${MY_RESOLUTION}"

# Check if non Steam SHORTCUT has the game / app as the launch option
if [ -z "$1" ]
then
	# launch option not provided. launch Waydroid via cage and show the full ui right away
	cage -- bash -c 'wlr-randr --output X11-1 --custom-mode ${MY_RESOLUTION}@60Hz ; \
			/usr/bin/waydroid show-full-ui $@ & \
			sleep 15 ; \
			sudo /usr/bin/waydroid-fix-controllers '
else
	# launch option provided. launch Waydroid via cage but do not show full ui yet
	cage -- bash -c 'wlr-randr --output X11-1 --custom-mode ${MY_RESOLUTION}@60Hz ; \
			/usr/bin/waydroid session start $@ & \
			sleep 15; \
			sudo /usr/bin/waydroid-fix-controllers ; \
			/usr/bin/waydroid app launch ${SHORTCUT}  &'
fi

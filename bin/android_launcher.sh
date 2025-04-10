#!/bin/bash

export SHORTCUT=${1}

function kill_cage() {
  while pgrep cage &> /dev/null; do
      timeout 5s killall -15 cage -w &> /dev/null
      if [ $? -eq 124 ]; then
          timeout 5s killall -2 cage -w &> /dev/null
          if [ $? -eq 124 ]; then
              timeout 5s killall -9 cage -w &> /dev/null
          fi
          break
      fi
  done
}

kill_cage
sudo /usr/bin/waydroid-container-stop
sudo /usr/bin/waydroid-container-start

export MY_RESOLUTION="$(xrandr | awk '/*/ {a=$1} END{print a}')"
echo "Resolution: ${MY_RESOLUTION}"

# Check if non Steam shortcut has the game / app as the launch option
if [ -z "$1" ]
then
	# launch option not provided. launch Waydroid via cage and show the full ui right away
	cage -- bash -c 'wlr-randr --output X11-1 --custom-mode $${MY_RESOLUTION}@60Hz ; \
		/usr/bin/waydroid show-full-ui $@ & \
		sleep 2 ; \
		sudo /usr/bin/waydroid-startup-scripts'
else
	# launch option provided. launch Waydroid via cage but do not show full ui, launch the app from the arguments, then launch the full ui so it doesnt crash when exiting the app provided
	cage -- env PACKAGE="$1" bash -c 'wlr-randr --output X11-1 --custom-mode ${MY_RESOLUTION}@60Hz ; \
		/usr/bin/waydroid session start $@ & \
		sudo /usr/bin/waydroid-startup-scripts ; \
		sleep 2 ; \
		/usr/bin/waydroid app launch $PACKAGE & \
		sleep 2 ; \
		/usr/bin/waydroid show-full-ui $@ &'
fi


# Get rid of stale processes.
sudo kill $(ps -ef | grep [w]aydroid | awk '{print $2}')
kill_cage
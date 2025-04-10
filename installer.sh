#!/bin/bash

clear

cat <<EOF
SteamOS Waydroid Installer Script by ryanrudolf (modified by SteamFork)
https://github.com/SteamFork/SteamOS-Waydroid-Installer

EOF

ANDROID_HOME="${HOME}/.waydroid"
AUR_CASUALSNEK=https://github.com/casualsnek/waydroid_script.git
AUR_CASUALSNEK2=https://github.com/ryanrudolfoba/waydroid_script.git
DIR_CASUALSNEK=${HOME}/AUR/waydroid/waydroid_script
STEAMOS_VERSION=$(grep VERSION_ID /etc/os-release | cut -d "=" -f 2)


# define functions here
cleanup_exit () {
	# call this function to perform cleanup when a sanity check fails
	# remove binder kernel module
	echo Something went wrong! Performing cleanup. Run the script again to install waydroid.
	# remove installed packages
	sudo pacman -R --noconfirm libglibutil libgbinder python-gbinder waydroid wlroots dnsmasq lxc &> /dev/null
	# delete the waydroid directories
	sudo rm -rf ${HOME}/waydroid /var/lib/waydroid ${HOME}/AUR &> /dev/null
	# delete waydroid config and scripts
	sudo rm /etc/sudoers.d/zzzzzzzz-waydroid /etc/modules-load.d/waydroid.conf /usr/bin/waydroid* &> /dev/null
	# delete cage binaries
	sudo rm /usr/bin/cage /usr/bin/wlr-randr &> /dev/null
	sudo rm -rf ${ANDROID_HOME} &> /dev/null
	sudo steamos-readonly enable &> /dev/null
	echo Cleanup completed.
	exit
}

# sanity check - are you running this in Desktop Mode or ssh / virtual tty session?
xdpyinfo &> /dev/null
if [ $? -eq 0 ]
then
	echo Script is running in Desktop Mode.
else
 	echo Script is NOT running in Desktop Mode.
  	echo Please run the script in Desktop Mode as mentioned in the README. Goodbye!
	exit
fi

for DIR in "${ANDROID_HOME}" "${HOME}/AUR/waydroid" "${HOME}/Applications"
do
	if [ ! -d "${DIR}" ]
	then
		mkdir -p "${DIR}"
	fi
done

# perform git clone but lets cleanup first in case the directory is not empty
sudo rm -rf ${HOME}/AUR/waydroid*  &> /dev/null && git clone $AUR_CASUALSNEK $DIR_CASUALSNEK &> /dev/null

if [ $? -eq 0 ]
then
	echo Casualsnek repo has been successfully cloned!
else
	echo Error cloning Casualsnek repo! Trying to clone again using backup repo.
	sudo rm -rf ${HOME}/AUR/waydroid*  &> /dev/null && git clone $AUR_CASUALSNEK2 $DIR_CASUALSNEK &> /dev/null

	if [ $? -eq 0 ]
	then
		echo Casualsnek repo has been successfully cloned!
	else
		echo Error cloning Casualsnek repo! This failed twice already! Maybe your internet connection is the problem?
		cleanup_exit
	fi
fi

# disable the SteamOS readonly
sudo steamos-readonly disable

# initialize the keyring
sudo pacman-key --init && sudo pacman-key --populate

if [ $? -eq 0 ]
then
	echo pacman keyring has been initialized!
else
	echo Error initializing keyring! Run the script again to install waydroid.
	cleanup_exit
fi

sudo pacman -Sy --noconfirm --overwrite '*' fbset wlroots weston wlr-randr cage waydroid

if [ $? -eq 0 ]
then
	echo waydroid and cage has been installed!
	sudo systemctl disable waydroid-container.service
else
	echo Error installing waydroid and cage. Run the script again to install waydroid.
	cleanup_exit
fi

# waydroid start service
sudo tee /usr/bin/waydroid-container-start > /dev/null <<'EOF'
#!/bin/bash
systemctl start waydroid-container.service
ln -s /dev/binderfs/binder /dev/anbox-binder &> /dev/null
chmod o=rw /dev/anbox-binder
EOF
sudo chmod +x /usr/bin/waydroid-container-start

# waydroid stop service
sudo tee /usr/bin/waydroid-container-stop > /dev/null <<'EOF'
#!/bin/bash
systemctl stop waydroid-container.service
EOF
sudo chmod +x /usr/bin/waydroid-container-stop

# waydroid fix controllers
sudo tee /usr/bin/waydroid-fix-controllers > /dev/null <<'EOF'
#!/bin/bash
echo add > /sys/devices/virtual/input/input*/event*/uevent

# fix for scoped storage permission issue
waydroid shell sh /system/etc/nodataperm.sh
EOF
sudo chmod +x /usr/bin/waydroid-fix-controllers

cp bin/android_launcher.sh ${ANDROID_HOME}

# custom configs done. lets move them to the correct location
cp $PWD/bin/waydroid_toolbox.sh ${ANDROID_HOME}
chmod 0755 ${ANDROID_HOME}/*.sh
cat <<EOF >${HOME}/Desktop/"Waydroid Toolbox.desktop"
[Desktop Entry]
Type=Application
Name=Waydroid Toolbox
Exec=${ANDROID_HOME}/waydroid_toolbox.sh
Icon=waydroid
Categories=X-WayDroid-App;
X-Purism-FormFactor=Workstation;Mobile;

EOF
chmod 0755 ${HOME}/Desktop/"Waydroid Toolbox.desktop"

# place custom overlay files here - key layout, hosts, audio.rc etc etc
# copy fixed key layout for Steam Controller
sudo mkdir -p /var/lib/waydroid/overlay/system/usr/keylayout
sudo cp extras/Vendor_28de_Product_11ff.kl /var/lib/waydroid/overlay/system/usr/keylayout/

if [ ! -d "/etc/post-update.d" ]
then
	sudo mkdir -p "/etc/post-update.d"
fi
sudo cp extras/waydroid-post-update.sh /etc/post-update.d
sudo chmod 0755 /etc/post-update.d/waydroid-post-update.sh

# copy custom audio.rc patch to lower the audio latency
sudo mkdir -p /var/lib/waydroid/overlay/system/etc/init
sudo cp extras/audio.rc /var/lib/waydroid/overlay/system/etc/init/

# copy custom hosts file from StevenBlack to block ads (adware + malware + fakenews + gambling + pr0n)
sudo mkdir -p /var/lib/waydroid/overlay/system/etc
sudo cp extras/hosts /var/lib/waydroid/overlay/system/etc

# copy libndk_fixer.so - this is needed to play roblox
sudo mkdir -p /var/lib/waydroid/overlay/system/lib64
sudo cp extras/libndk_fixer.so /var/lib/waydroid/overlay/system/lib64

# copy nodataperm.sh - this is to fix the scoped storage issue in Android 11
chmod +x extras/nodataperm.sh
sudo cp extras/nodataperm.sh /var/lib/waydroid/overlay/system/etc

# lets check if this is a reinstall
grep redfin /var/lib/waydroid/waydroid_base.prop &> /dev/null
if [ $? -eq 0 ]
then
	echo This seems to be a reinstall. No further config needed.

	# all done lets re-enable the readonly
	sudo steamos-readonly enable
	echo Waydroid has been successfully installed!
else
	echo Config file missing. Lets configure waydroid.

	# lets initialize waydroid
	mkdir -p ${HOME}/waydroid/{images,cache_http}
	sudo mkdir /var/lib/waydroid &> /dev/null
	sudo ln -s ${HOME}/waydroid/images /var/lib/waydroid/images &> /dev/null
	sudo ln -s ${HOME}/waydroid/cache_http /var/lib/waydroid/cache_http &> /dev/null
	sudo waydroid init -s GAPPS

 	# check if waydroid initialization completed without errors
	if [ $? -eq 0 ]
	then
		echo Waydroid initialization completed without errors!

	else
		echo Waydroid did not initialize correctly
		echo Most probably this is due to python issue. Attach this screenshot when filing a bug report!
		echo Output of whereis python - $(whereis python)
		echo Output of which python - $(which python)
		echo Output of python version - $(python -V)
		cleanup_exit
	fi

	# firewall config for waydroid0 interface to forward packets for internet to work
	sudo firewall-cmd --zone=trusted --add-interface=waydroid0 &> /dev/null
	sudo firewall-cmd --zone=trusted --add-port=53/udp &> /dev/null
	sudo firewall-cmd --zone=trusted --add-port=67/udp &> /dev/null
	sudo firewall-cmd --zone=trusted --add-forward &> /dev/null
	sudo firewall-cmd --runtime-to-permanent &> /dev/null

	# casualsnek script
	cd ${DIR_CASUALSNEK}
	python3 -m venv venv
	venv/bin/pip install -r requirements.txt &> /dev/null
	sudo venv/bin/python3 main.py install {libndk,widevine}
	if [ $? -eq 0 ]
	then
		echo Casualsnek script done.
		sudo rm -rf ${HOME}/AUR
	else
		echo Error with casualsnek script. Run the script again.
		cleanup_exit
	fi

	# lets change the fingerprint so waydroid shows up as a Pixel 5 - Redfin
	sudo tee -a /var/lib/waydroid/waydroid_base.prop > /dev/null <<'EOF'

##########################################################################
# controller config for udev events
persist.waydroid.udev=true
persist.waydroid.uevent=true

##########################################################################
### start of custom build prop - you can safely delete if this causes issue

ro.product.brand=google
ro.product.manufacturer=Google
ro.system.build.product=redfin
ro.product.name=redfin
ro.product.device=redfin
ro.product.model=Pixel 5
ro.system.build.flavor=redfin-user
ro.build.fingerprint=google/redfin/redfin:11/RQ3A.211001.001/eng.electr.20230318.111310:user/release-keys
ro.system.build.description=redfin-user 11 RQ3A.211001.001 eng.electr.20230318.111310 release-keys
ro.bootimage.build.fingerprint=google/redfin/redfin:11/RQ3A.211001.001/eng.electr.20230318.111310:user/release-keys
ro.build.display.id=google/redfin/redfin:11/RQ3A.211001.001/eng.electr.20230318.111310:user/release-keys
ro.build.tags=release-keys
ro.build.description=redfin-user 11 RQ3A.211001.001 eng.electr.20230318.111310 release-keys
ro.vendor.build.fingerprint=google/redfin/redfin:11/RQ3A.211001.001/eng.electr.20230318.111310:user/release-keys
ro.vendor.build.id=RQ3A.211001.001
ro.vendor.build.tags=release-keys
ro.vendor.build.type=user
ro.odm.build.tags=release-keys

### end of custom build prop - you can safely delete if this causes issue
##########################################################################
EOF

	cat <<EOF >${HOME}/Applications/Waydroid.desktop
[Desktop Entry]
Type=Application
Name=Waydroid
Exec=${ANDROID_HOME}/android_launcher.sh
Icon=waydroid
Categories=X-WayDroid-App;
X-Purism-FormFactor=Workstation;Mobile;

EOF
	chmod 0755 ${HOME}/Applications/Waydroid.desktop
	echo Adding shortcuts to game mode. Please wait.
	steamos-add-to-steam ${HOME}/Applications/Waydroid.desktop
	echo steamos-nested-desktop shortcut has been added to game mode.

	# all done lets re-enable the readonly
	sudo steamos-readonly enable
	echo Waydroid has been successfully installed!
fi

# change GPU rendering to use minigbm_gbm_mesa
sudo sed -i "s/ro.hardware.gralloc=.*/ro.hardware.gralloc=minigbm_gbm_mesa/g" /var/lib/waydroid/waydroid_base.prop


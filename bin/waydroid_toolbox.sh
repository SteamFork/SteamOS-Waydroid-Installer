#!/bin/bash
ANDROID_HOME="${HOME}/.waydroid"

while true
do
Choice=$(zenity --list --radiolist --multiple --title "Waydroid Toolbox"\
    --height=640 --width=800 \
    --column "Select One" \
    --column "Option" \
    --column="Description - Read this carefully!"\
    FALSE ADBLOCK "Disable or update the custom adblock hosts file."\
    FALSE AUDIO "Enable or disable the custom audio fixes."\
    FALSE SERVICE "Start or Stop the Waydroid container service."\
    FALSE GPU "Change the GPU config - GBM or MINIGBM."\
    FALSE LIBNDK "Configure the ARM translation layer to use - LIBNDK or LIBNDK-FIXER."\
    FALSE LAUNCHER "Add Waydroid launcher to Game Mode."\
    FALSE UNINSTALL "Choose this to uninstall Waydroid and revert any changes made."\
    TRUE EXIT "***** Exit the Waydroid Toolbox *****")

if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]
then
    echo User pressed CANCEL / EXIT.
    exit

elif [ "$Choice" == "ADBLOCK" ]
then
ADBLOCK_Choice=$(zenity --list --radiolist --multiple --title "Waydroid Toolbox" --column "Select One" \
    --column "Option" --column="Description - Read this carefully!"\
    FALSE DISABLE "Disable the custom adblock hosts file."\
    FALSE UPDATE "Update and enable the custom adblock hosts file."\
    TRUE MENU "***** Go back to Waydroid Toolbox Main Menu *****")

    if [ $? -eq 1 ] || [ "$ADBLOCK_Choice" == "MENU" ]
    then
        echo User pressed CANCEL. Going back to main menu.

    elif [ "$ADBLOCK_Choice" == "DISABLE" ]
    then
        # Disable the custom adblock hosts file
        sudo -S mv /var/lib/waydroid/overlay/system/etc/hosts /var/lib/waydroid/overlay/system/etc/hosts.disable &> /dev/null

        zenity --warning --title "Waydroid Toolbox" --text "Custom adblock hosts file has been disabled!" --width 350 --height 75

    elif [ "$ADBLOCK_Choice" == "UPDATE" ]
    then
        # Get the latest custom adblock hosts file from Steven Black's GitHub
        sudo -S rm /var/lib/waydroid/overlay/system/etc/hosts.disable &> /dev/null
        sudo -S wget https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts \
               -O /var/lib/waydroid/overlay/system/etc/hosts	

        zenity --warning --title "Waydroid Toolbox" --text "Custom adblock hosts file has been updated!" --width 350 --height 75
    fi

elif [ "$Choice" == "LIBNDK" ]
then
LIBNDK_Choice=$(zenity --list --radiolist --multiple --title "Waydroid Toolbox" --column "Select One" --column "Option" --column="Description - Read this carefully!"\
    FALSE LIBNDK "Use the original LIBNDK."\
    FALSE LIBNDK-FIXER "Use LIBNDK-FIXER for Roblox."\
    TRUE MENU "***** Go back to Waydroid Toolbox Main Menu *****")
    if [ $? -eq 1 ] || [ "$LIBNDK_Choice" == "MENU" ]
    then
        echo User pressed CANCEL. Going back to main menu.

    elif [ "$LIBNDK_Choice" == "LIBNDK" ]
    then
        # Edit waydroid prop file to use the original libndk_translation.so
        sudo -S sed -i "s/ro.dalvik.vm.native.bridge=.*/ro.dalvik.vm.native.bridge=libndk_translation.so/g" \
            /var/lib/waydroid/waydroid_base.prop 

        zenity --warning --title "Waydroid Toolbox" --text "libndk_translation.so is now in use!" --width 350 --height 75

    elif [ "$LIBNDK_Choice" == "LIBNDK-FIXER" ]
    then
        # Edit waydroid prop file to use the libndk_fixer.so
        sudo -S sed -i "s/ro.dalvik.vm.native.bridge=.*/ro.dalvik.vm.native.bridge=libndk_fixer.so/g" \
            /var/lib/waydroid/waydroid_base.prop

        zenity --warning --title "Waydroid Toolbox" --text "libndk_fixer.so is now in use! \nYou can now play Roblox!" --width 350 --height 75
    fi

elif [ "$Choice" == "GPU" ]
then
GPU_Choice=$(zenity --list --radiolist --multiple --title "Waydroid Toolbox" --column "Select One" --column "Option" --column="Description - Read this carefully!"\
    FALSE GBM "Use gbm config for GPU."\
    FALSE MINIGBM "Use minigbm_gbm_mesa for GPU (default)."\
    TRUE MENU "***** Go back to Waydroid Toolbox Main Menu *****")
    if [ $? -eq 1 ] || [ "$GPU_Choice" == "MENU" ]
    then
        echo User pressed CANCEL. Going back to main menu.

    elif [ "$GPU_Choice" == "GBM" ]
    then
        # Edit waydroid prop file to use gbm
        sudo -S sed -i "s/ro.hardware.gralloc=.*/ro.hardware.gralloc=gbm/g" \
            /var/lib/waydroid/waydroid_base.prop 

        zenity --warning --title "Waydroid Toolbox" --text "gbm is now in use!" --width 350 --height 75

    elif [ "$GPU_Choice" == "MINIGBM" ]
    then
        # Edit waydroid prop file to use minigbm_gbm_mesa
        sudo -S sed -i "s/ro.hardware.gralloc=.*/ro.hardware.gralloc=minigbm_gbm_mesa/g" \
            /var/lib/waydroid/waydroid_base.prop

        zenity --warning --title "Waydroid Toolbox" --text "minigbm_gbm_mesa is now in use!" --width 350 --height 75
    fi

elif [ "$Choice" == "AUDIO" ]
then
AUDIO_Choice=$(zenity --list --radiolist --multiple 	--title "Waydroid Toolbox" --column "Select One" --column "Option" --column="Description - Read this carefully!"\
    FALSE DISABLE "Disable the custom audio config."\
    FALSE ENABLE "Enable the custom audio config to lower audio latency."\
    TRUE MENU "***** Go back to Waydroid Toolbox Main Menu *****")
    if [ $? -eq 1 ] || [ "$AUDIO_Choice" == "MENU" ]
    then
        echo User pressed CANCEL. Going back to main menu.

    elif [ "$AUDIO_Choice" == "DISABLE" ]
    then
        # Disable the custom audio config
        sudo -S mv /var/lib/waydroid/overlay/system/etc/init/audio.rc \
                /var/lib/waydroid/overlay/system/etc/init/audio.rc.disable &> /dev/null

        zenity --warning --title "Waydroid Toolbox" --text "Custom audio config has been disabled!" --width 350 --height 75

    elif [ "$AUDIO_Choice" == "ENABLE" ]
    then
        # Enable the custom audio config
        sudo -S mv /var/lib/waydroid/overlay/system/etc/init/audio.rc.disable \
                /var/lib/waydroid/overlay/system/etc/init/audio.rc &> /dev/null

        zenity --warning --title "Waydroid Toolbox" --text "Custom audio config has been enabled!" --width 350 --height 75
    fi

elif [ "$Choice" == "SERVICE" ]
then
SERVICE_Choice=$(zenity --list --radiolist --multiple --title "Waydroid Toolbox" --column "Select One" --column "Option" --column="Description - Read this carefully!"\
    FALSE START "Start the Waydroid container service."\
    FALSE STOP "Stop the Waydroid container service."\
    TRUE MENU "***** Go back to Waydroid Toolbox Main Menu *****")
    if [ $? -eq 1 ] || [ "$SERVICE_Choice" == "MENU" ]
    then
        echo User pressed CANCEL. Going back to main menu.

    elif [ "$SERVICE_Choice" == "START" ]
    then
        # start the waydroid container service
        sudo -S waydroid-container-start
        waydroid session start &
        sleep 5

        zenity --warning --title "Waydroid Toolbox" --text "Waydroid container service has been started!" --width 350 --height 75

    elif [ "$SERVICE_Choice" == "STOP" ]
    then
        # stop the waydroid container service
        waydroid session stop
        sudo -S waydroid-container-stop
        pkill kwallet

        zenity --warning --title "Waydroid Toolbox" --text "Waydroid container service has been stopped!" --width 350 --height 75
    fi

elif [ "$Choice" == "LAUNCHER" ]
then
    steamos-add-to-steam ${HOME}/Applications/Waydroid.desktop
    zenity --warning --title "Waydroid Toolbox" --text "Waydroid launcher has been added to Game Mode!" --width 450 --height 75

elif [ "$Choice" == "UNINSTALL" ]
then
    # Disable SteamOS readonly mode
    sudo -S steamos-readonly disable
    
    # Stop Waydroid services and remove kernel modules
    sudo -S systemctl stop waydroid-container
    sudo -S rm /lib/modules/$(uname -r)/binder_linux.ko.zst
    sudo -S pacman -R --noconfirm libglibutil libgbinder python-gbinder waydroid wlroots dnsmasq lxc
    
    # Delete Waydroid directories and config, excluding downloaded files
    echo "INFO: Preserving downloaded files in ${HOME}/waydroid/custom."
    sudo -S find "${HOME}/waydroid" -mindepth 1 -maxdepth 1 ! -name "custom" -exec rm -rf {} +
    sudo -S rm -rf /var/lib/waydroid ${HOME}/.local/share/waydroid ${HOME}/.local/share/applications/waydroid* ${HOME}/AUR
    
    # Delete Waydroid config and scripts
    sudo -S rm /etc/sudoers.d/zzzzzzzz-waydroid /etc/modules-load.d/waydroid.conf /usr/bin/waydroid-fix-controllers \
        /usr/bin/waydroid-container-stop /usr/bin/waydroid-container-start
    
    # Uninstall the packages
    sudo pacman -R --noconfirm cage lxc waydroid

    # Delete Waydroid Toolbox launcher
    rm ${HOME}/Desktop/"Waydroid Toolbox.desktop"
    rm ${HOME}/Applications/Waydroid.desktop
    
    # Delete contents of ${ANDROID_HOME}
    rm -rf ${ANDROID_HOME}/

    # Delete post-update hook
    sudo rm -f /etc/post-update.d/waydroid-post-update.sh

    # Re-enable SteamOS readonly mode
    sudo -S steamos-readonly enable
    
    zenity --warning --title "Waydroid Toolbox" --text "Waydroid has been uninstalled! Goodbye!" --width 600 --height 75
    exit
fi
done

#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# SteamOS Waydroid Installer
#
# Copyright (c) 2024 SteamFork
# Copyright (c) 2023 ryanrudolf
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

DEBUG=0  # Debug mode is off by default

# Function to print debug messages
debug() {
    if [[ ${DEBUG} -eq 1 ]]; then
        echo "[DEBUG] $1"
    fi
}

clear

cat <<EOF
SteamOS Waydroid Installer Script by ryanrudolf (modified by SteamFork)
https://github.com/SteamFork/SteamOS-Waydroid-Installer

EOF

ANDROID_HOME="${HOME}/.waydroid"
AUR_CASUALSNEK="https://github.com/casualsnek/waydroid_script.git"
AUR_CASUALSNEK2="https://github.com/ryanrudolfoba/waydroid_script.git"
DIR_CASUALSNEK="${HOME}/AUR/waydroid/waydroid_script"
STEAMOS_VERSION="$(grep VERSION_ID /etc/os-release | cut -d "=" -f 2)"

# Android TV and Android 13 image variables
ANDROID13_TV_IMG="https://github.com/ryanrudolfoba/SteamOS-Waydroid-Installer/releases/download/Android13TV/lineage-20-20250117-UNOFFICIAL-10MinuteSteamDeckGamer-WaydroidATV.zip"
ANDROID13_TV_IMG_HASH="2ac5d660c3e32b8298f5c12c93b1821bc7ccefbd7cfbf5fee862e169aa744f4c"
ANDROID13_IMG="https://github.com/ryanrudolfoba/SteamOS-Waydroid-Installer/releases/download/Android13/lineage-20-20250121-UNOFFICIAL-10MinuteSteamDeckGamer-Waydroid.zip"
ANDROID13_IMG_HASH="833be8279a605285cc2b9c85425511a100320102c7ff8897f254fcfdf3929bb1"

# Debug output for variables
debug "ANDROID_HOME=${ANDROID_HOME}"
debug "AUR_CASUALSNEK=${AUR_CASUALSNEK}"
debug "AUR_CASUALSNEK2=${AUR_CASUALSNEK2}"
debug "DIR_CASUALSNEK=${DIR_CASUALSNEK}"
debug "STEAMOS_VERSION=${STEAMOS_VERSION}"
debug "ANDROID13_TV_IMG=${ANDROID13_TV_IMG}"
debug "ANDROID13_TV_IMG_HASH=${ANDROID13_TV_IMG_HASH}"
debug "ANDROID13_IMG=${ANDROID13_IMG}"
debug "ANDROID13_IMG_HASH=${ANDROID13_IMG_HASH}"

# Helper function to handle errors
check_error () {
    if [ $? -ne 0 ]; then
        echo "$1"
        debug "Error encountered: $1"
        cleanup_exit
    fi
}

# Cleanup function
cleanup_exit () {
    echo "ERROR: Something went wrong! Performing cleanup. Run the script again to install Waydroid."
    debug "Performing cleanup..."

    # Remove installed packages
    sudo pacman -R --noconfirm libglibutil libgbinder python-gbinder waydroid wlroots lxc cage &> /dev/null

    # Remove Waydroid-related directories, excluding downloaded files
    echo "INFO: Cleaning up Waydroid-related directories..."
    debug "Removing /var/lib/waydroid and ${HOME}/AUR."
    sudo rm -rf /var/lib/waydroid "${HOME}/AUR" &> /dev/null

    # Remove configuration and binaries
    echo "INFO: Removing Waydroid configuration and binaries..."
    debug "Removing configuration files and binaries."
    sudo rm -f /etc/sudoers.d/zzzzzzzz-waydroid /etc/modules-load.d/waydroid.conf /usr/bin/waydroid* &> /dev/null
    sudo rm -f /usr/bin/cage /usr/bin/wlr-randr &> /dev/null

    # Preserve downloaded files in ${HOME}/waydroid/custom
    echo "INFO: Preserving downloaded files in ${HOME}/waydroid/custom."
    debug "Preserving ${HOME}/waydroid/custom."
    find "${HOME}/waydroid" -mindepth 1 -maxdepth 1 ! -name "custom" -exec rm -rf {} +

    # Re-enable SteamOS readonly mode
    echo "INFO: Re-enabling SteamOS readonly mode..."
    debug "Re-enabling SteamOS readonly mode."
    sudo steamos-readonly enable &> /dev/null

    echo "INFO: Cleanup completed."
    debug "Cleanup completed."
    exit 1
}

# Function to create directories
create_directories () {
    for DIR in "$@"; do
        debug "Creating directory: ${DIR}"
        if [ ! -d "${DIR}" ]; then
            mkdir -p "${DIR}"
        fi
    done
}

# Function to download and verify images
download_image () {
    local SRC="$1"
    local SRC_HASH="$2"
    local DEST="$3"
    local DEST_ZIP="${DEST}.zip"
    local NAME="$4"
    local DOWNLOAD_DIR="${HOME}/waydroid/downloads"

    # Ensure the destination and download directories exist
    local DEST_DIR
    DEST_DIR=$(dirname "${DEST}")
    debug "Ensuring destination directory exists: ${DEST_DIR}"
    if [ ! -d "${DEST_DIR}" ]; then
        debug "Creating directory: ${DEST_DIR}"
        mkdir -p "${DEST_DIR}"
    fi

    debug "Ensuring download directory exists: ${DOWNLOAD_DIR}"
    if [ ! -d "${DOWNLOAD_DIR}" ]; then
        debug "Creating directory: ${DOWNLOAD_DIR}"
        mkdir -p "${DOWNLOAD_DIR}"
    fi

    # Check if the file already exists in the download directory
    if [ -f "${DOWNLOAD_DIR}/$(basename "${DEST_ZIP}")" ]; then
        debug "File ${DOWNLOAD_DIR}/$(basename "${DEST_ZIP}") already exists. Verifying its hash..."
        local HASH
        HASH=$(sha256sum "${DOWNLOAD_DIR}/$(basename "${DEST_ZIP}")" | awk '{print $1}')
        debug "Computed hash for ${NAME}: ${HASH}"
        if [[ "${HASH}" == "${SRC_HASH}" ]]; then
            echo "INFO: ${NAME} image already exists and is valid. Skipping download."
            debug "${NAME} image already exists and is valid. Skipping download."
            cp "${DOWNLOAD_DIR}/$(basename "${DEST_ZIP}")" "${DEST_ZIP}"
        else
            echo "WARNING: ${NAME} image exists but hash mismatch detected. Re-downloading..."
            debug "${NAME} image exists but hash mismatch detected. Re-downloading..."
            rm -f "${DOWNLOAD_DIR}/$(basename "${DEST_ZIP}")"
            curl -Lo "${DOWNLOAD_DIR}/$(basename "${DEST_ZIP}")" "${SRC}"
            cp "${DOWNLOAD_DIR}/$(basename "${DEST_ZIP}")" "${DEST_ZIP}"
        fi
    else
        echo "INFO: Downloading ${NAME} image..."
        debug "Downloading ${NAME} image from ${SRC}."
        curl -Lo "${DOWNLOAD_DIR}/$(basename "${DEST_ZIP}")" "${SRC}"
        cp "${DOWNLOAD_DIR}/$(basename "${DEST_ZIP}")" "${DEST_ZIP}"
    fi

    # Verify the downloaded file's hash
    local HASH
    HASH=$(sha256sum "${DEST_ZIP}" | awk '{print $1}')
    debug "Computed hash for ${NAME}: ${HASH}"
    if [[ "${HASH}" != "${SRC_HASH}" ]]; then
        echo "ERROR: Hash mismatch for ${NAME} image. Exiting."
        debug "Hash mismatch for ${NAME} image. Expected: ${SRC_HASH}, Got: ${HASH}"
        cleanup_exit
    fi

    echo "INFO: Extracting ${NAME} image..."
    debug "Extracting ${NAME} image to ${HOME}/waydroid/custom."
    unzip -o "${DEST_ZIP}" -d "${HOME}/waydroid/custom"
}

# Function to initialize Waydroid
initialize_waydroid () {
    debug "Initializing Waydroid..."
    echo "Initializing Waydroid..."
    sudo waydroid init
    check_error "Waydroid initialization failed. Exiting."
    echo "Waydroid initialized successfully!"
}

# Function to configure waydroid_base.prop
configure_waydroid_base_prop () {
    local ANDROID_VERSION="$1"
    local DEVICE_NAME="$2"
    local BUILD_FINGERPRINT="$3"
    local BRAND="$4"
    local MANUFACTURER="$5"
    local MODEL="$6"
    local BUILD_ID="$7"

    debug "Configuring waydroid_base.prop with ANDROID_VERSION=${ANDROID_VERSION}, DEVICE_NAME=${DEVICE_NAME}, BUILD_FINGERPRINT=${BUILD_FINGERPRINT}, BRAND=${BRAND}, MANUFACTURER=${MANUFACTURER}, MODEL=${MODEL}, BUILD_ID=${BUILD_ID}"
    sudo tee /var/lib/waydroid/waydroid_base.prop > /dev/null <<EOF
##########################################################################
### Build Properties

ro.product.brand=${BRAND}
ro.product.manufacturer=${MANUFACTURER}
ro.system.build.product=${DEVICE_NAME}
ro.product.name=${DEVICE_NAME}
ro.product.device=${DEVICE_NAME}
ro.product.model=${MODEL}
ro.system.build.flavor=${DEVICE_NAME}-user
ro.build.fingerprint=${BUILD_FINGERPRINT}
ro.system.build.description=${DEVICE_NAME}-user ${ANDROID_VERSION} ${BUILD_FINGERPRINT} release-keys
ro.bootimage.build.fingerprint=${BUILD_FINGERPRINT}
ro.build.display.id=${BUILD_FINGERPRINT}
ro.build.tags=release-keys
ro.build.description=${DEVICE_NAME}-user ${ANDROID_VERSION} ${BUILD_ID} release-keys
ro.vendor.build.fingerprint=${BUILD_FINGERPRINT}
ro.vendor.build.id=${BUILD_ID}
ro.vendor.build.tags=release-keys
ro.vendor.build.type=user
ro.odm.build.tags=release-keys

# controller config for udev events
persist.waydroid.udev=true
persist.waydroid.uevent=true

# disable root
ro.adb.secure=1
ro.debuggable=0
ro.build.selinux=1
EOF
}

# Function to configure firewall
configure_firewall () {
    debug "Configuring firewall for Waydroid..."
    echo "Configuring firewall for Waydroid..."
    sudo firewall-cmd --zone=trusted --add-interface=waydroid0 &> /dev/null
    sudo firewall-cmd --zone=trusted --add-port=53/udp &> /dev/null
    sudo firewall-cmd --zone=trusted --add-port=67/udp &> /dev/null
    sudo firewall-cmd --zone=trusted --add-forward &> /dev/null
    sudo firewall-cmd --runtime-to-permanent &> /dev/null
}

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --version <version>    Specify the Android version to install. Supported versions:"
    echo "                         - 13tv: Install Android 13 TV"
    echo "                         - 13: Install Android 13"
    echo "  --gapps                Install Google Apps"
    echo "  --debug                Enable debug output"
    echo "  --uninstall            Uninstall Waydroid"
    echo "  --help                 Show this help message"
    exit 1
}

# Function to set up the offload directory for /var/lib/waydroid
setup_offload_directory() {
    echo "INFO: Setting up writable offload directory for /var/lib/waydroid..."
    debug "Creating writable offload directory at /home/.steamos/offload/var/lib/waydroid."
    sudo mkdir -p /home/.steamos/offload/var/lib/waydroid

    # Remove existing /var/lib/waydroid if it exists and is not a symlink
    if [ -e /var/lib/waydroid ] && [ ! -L /var/lib/waydroid ]; then
        echo "INFO: Removing existing /var/lib/waydroid directory."
        debug "Removing existing /var/lib/waydroid directory."
        sudo rm -rf /var/lib/waydroid
    fi

    # Create a symbolic link from /var/lib/waydroid to the offload directory
    if [ ! -L /var/lib/waydroid ]; then
        echo "INFO: Creating symbolic link from /var/lib/waydroid to /home/.steamos/offload/var/lib/waydroid."
        debug "Creating symbolic link from /var/lib/waydroid to /home/.steamos/offload/var/lib/waydroid."
        sudo ln -s /home/.steamos/offload/var/lib/waydroid /var/lib/waydroid
    fi

    echo "INFO: Writable offload directory for /var/lib/waydroid has been set up successfully!"
    debug "Writable offload directory for /var/lib/waydroid set up successfully."
}

# Function to prepare the custom image location
prepare_custom_image_location() {
    echo "INFO: Preparing custom image location..."
    debug "Preparing custom image location."

    # Create the /etc/waydroid-extra directory if it doesn't exist
    sudo mkdir -p /etc/waydroid-extra &> /dev/null || {
        echo "ERROR: Failed to create /etc/waydroid-extra directory."
        debug "Failed to create /etc/waydroid-extra directory."
        exit 1
    }

    # Create a symlink from ~/waydroid/custom to /etc/waydroid-extra/images
    sudo ln -sf "${HOME}/waydroid/custom" /etc/waydroid-extra/images &> /dev/null || {
        echo "ERROR: Failed to create symlink for custom images."
        debug "Failed to create symlink for custom images."
        exit 1
    }

    echo "INFO: Custom image location prepared successfully."
    debug "Custom image location prepared successfully."
}

# Function to set up custom image directory and symlink
setup_custom_image_directory() {
    echo "INFO: Setting up custom image directory..."
    debug "Setting up custom image directory."

    # Create the /etc/waydroid-extra directory if it doesn't exist
    sudo mkdir -p /etc/waydroid-extra &> /dev/null || {
        echo "ERROR: Failed to create /etc/waydroid-extra directory."
        debug "Failed to create /etc/waydroid-extra directory."
        exit 1
    }

    # Create or update a symlink from ~/waydroid/custom to /etc/waydroid-extra/images
    sudo ln -sf "${HOME}/waydroid/custom" /etc/waydroid-extra/images &> /dev/null || {
        echo "ERROR: Failed to create or update symlink for custom images."
        debug "Failed to create or update symlink for custom images."
        exit 1
    }

    echo "INFO: Custom image directory setup completed successfully."
    debug "Custom image directory setup completed successfully."
}

# Function to toggle SteamOS readonly mode
readonly_mode() {
    local MODE="$1"
    if [[ "$MODE" == "disable" ]]; then
        echo "INFO: Disabling SteamOS readonly mode to allow system modifications..."
        debug "Disabling SteamOS readonly mode."
        sudo steamos-readonly disable
    elif [[ "$MODE" == "enable" ]]; then
        echo "INFO: Re-enabling SteamOS readonly mode..."
        debug "Re-enabling SteamOS readonly mode."
        sudo steamos-readonly enable
    else
        echo "ERROR: Invalid argument to readonly_mode. Use 'enable' or 'disable'."
        debug "Invalid argument to readonly_mode: $MODE"
        exit 1
    fi
}

# Function to uninstall Waydroid
uninstall_waydroid() {
    echo "INFO: Uninstalling Waydroid and cleaning up all related files..."
    debug "Stopping and disabling Waydroid services."

    # Disable SteamOS readonly mode
    readonly_mode disable

    # Stop Waydroid services
    sudo systemctl stop waydroid-container.service &> /dev/null || echo "INFO: Waydroid container service is not running."
    sudo systemctl disable waydroid-container.service &> /dev/null

    # Remove Waydroid-related files and configurations
    echo "INFO: Removing Waydroid-related files and configurations..."
    debug "Removing Waydroid files from ${HOME}/waydroid, ${HOME}/AUR, and other locations."
    sudo pacman -R --noconfirm libglibutil libgbinder python-gbinder waydroid wlroots dnsmasq lxc cage &> /dev/null
    sudo rm -rf "${HOME}/waydroid" "${HOME}/AUR"
    sudo rm -f /etc/sudoers.d/zzzzzzzz-waydroid
    sudo rm -f /etc/modules-load.d/waydroid.conf
    sudo rm -f /usr/bin/waydroid*
    sudo rm -f /usr/bin/cage /usr/bin/wlr-randr
    sudo rm -rf "${ANDROID_HOME}"
    sudo rm -f /etc/post-update.d/waydroid-post-update.sh
    sudo rm -f "${HOME}/Desktop/Waydroid Toolbox.desktop"
    sudo rm -f "${HOME}/Applications/Waydroid.desktop"

    # Clear the contents of the offload directory but leave the directory and symlink intact
    echo "INFO: Clearing the contents of the Waydroid offload directory..."
    debug "Clearing contents of /home/.steamos/offload/var/lib/waydroid."
    sudo rm -rf /home/.steamos/offload/var/lib/waydroid/*

    # Re-enable SteamOS readonly mode
    readonly_mode enable

    echo "SUCCESS: Waydroid has been successfully uninstalled!"
    debug "Waydroid uninstallation completed successfully."
    exit 0
}

# Parse command-line arguments
INSTALL_GAPPS=0  # Default: Do not install Google Apps
while [[ $# -gt 0 ]]; do
    case "$1" in
        --install)
            if [[ -z "$2" ]]; then
                echo "Error: --install requires an argument."
                usage
            fi
            CHOICE="$2"
            shift 2
            ;;
        --gapps)
            INSTALL_GAPPS=1
            shift
            ;;
        --debug)
            DEBUG=1
            shift
            ;;
        --uninstall)
            uninstall_waydroid
            ;;
        --help)
            usage
            ;;
    esac
done

# Debug output for parsed arguments
debug "Parsed arguments: CHOICE=${CHOICE}, DEBUG=${DEBUG}, INSTALL_GAPPS=${INSTALL_GAPPS}"

# If no command-line option is provided, use Zenity to display a selection menu
if [[ -z "${CHOICE}" ]]; then
    debug "No version specified, displaying selection menu."
    CHOICE=$(zenity --width=600 --height=300 --list --radiolist \
        --title="Waydroid Installer" \
        --text="Select the version of Android you want to install:" \
        --column="Select" --column="Option" --column="Description" \
        TRUE 13 "Install Android 13" \
        FALSE 13tv "Install Android TV 13" \
        FALSE EXIT "Exit the installer")

    if [[ -z "${CHOICE}" || "${CHOICE}" == "EXIT" ]]; then
        echo "INFO: Exiting the installer."
        debug "User exited the installer."
        exit 0
    fi

    if [ ! "${INSTALL_GAPPS}" -eq 1 ]; then
      # Ask the user if they want to install Google Apps
      INSTALL_GAPPS=$(zenity --width=400 --height=200 --list --radiolist \
          --title="Google Apps Installation" \
          --text="Do you want to install Google Apps (Chrome, Play, etc)?" \
          --column="Select" --column="Option" \
          FALSE "Yes" \
          TRUE "No")

      if [[ "${INSTALL_GAPPS}" == "Yes" ]]; then
          INSTALL_GAPPS=1
          echo "INFO: User chose to install Google Apps."
          debug "User chose to install Google Apps."
      fi
    fi
fi

debug "Selected version: ${CHOICE}"

# Sanity check - are you running this in Desktop Mode or ssh / virtual tty session?
xdpyinfo &> /dev/null
if [ $? -eq 0 ]; then
    debug "Script is running in Desktop Mode."
    echo "Script is running in Desktop Mode."
else
    debug "Script is NOT running in Desktop Mode."
    echo "Script is NOT running in Desktop Mode."
    echo "Please run the script in Desktop Mode as mentioned in the README. Goodbye!"
    exit
fi

create_directories "${ANDROID_HOME}" "${HOME}/AUR/waydroid" "${HOME}/Applications"\

# Ensure the writable offload directory exists
setup_offload_directory

# Prepare the custom image location
prepare_custom_image_location

# Set up the custom image directory
setup_custom_image_directory

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

# Disable SteamOS readonly mode
readonly_mode disable

# Initialize the keyring
echo "INFO: Initializing the pacman keyring..."
debug "Initializing pacman keyring."
sudo pacman-key --init && sudo pacman-key --populate
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to initialize the pacman keyring. Please try running the script again."
    debug "Failed to initialize the pacman keyring."
    cleanup_exit
fi
echo "INFO: Pacman keyring initialized successfully!"
debug "Pacman keyring initialized successfully."

# Install Waydroid and dependencies
echo "INFO: Installing Waydroid and its dependencies. This may take a few minutes..."
debug "Installing Waydroid and dependencies."

# List of required packages
REQUIRED_PACKAGES=("fbset" "wlroots" "weston" "wlr-randr" "cage" "waydroid" "lzip")

# Loop through each package and check if it is installed
for PACKAGE in "${REQUIRED_PACKAGES[@]}"; do
    if pacman -Q "$PACKAGE" &> /dev/null; then
        echo "INFO: Package '$PACKAGE' is already installed. Skipping."
        debug "Package '$PACKAGE' is already installed. Skipping."
    else
        echo "INFO: Installing package '$PACKAGE'..."
        debug "Installing package '$PACKAGE'."
        sudo pacman -Sy --noconfirm --overwrite '*' "$PACKAGE"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to install package '$PACKAGE'. Please try running the script again."
            debug "Failed to install package '$PACKAGE'."
            cleanup_exit
        fi
    fi
done

echo "INFO: Waydroid and its dependencies installed successfully!"
debug "Waydroid and dependencies installed successfully."
sudo systemctl disable waydroid-container.service

# Configure Waydroid services
echo "INFO: Configuring Waydroid services and custom scripts..."
debug "Configuring Waydroid services and custom scripts."
sudo tee /usr/bin/waydroid-container-start > /dev/null <<'EOF'
#!/bin/bash
systemctl start waydroid-container.service
ln -s /dev/binderfs/binder /dev/anbox-binder &> /dev/null
chmod o=rw /dev/anbox-binder
EOF
sudo chmod +x /usr/bin/waydroid-container-start

sudo tee /usr/bin/waydroid-container-stop > /dev/null <<'EOF'
#!/bin/bash
systemctl stop waydroid-container.service
EOF
sudo chmod +x /usr/bin/waydroid-container-stop

sudo tee /usr/bin/waydroid-fix-controllers > /dev/null <<'EOF'
#!/bin/bash
echo add > /sys/devices/virtual/input/input*/event*/uevent

# Fix for scoped storage permission issue
waydroid shell sh /system/etc/nodataperm.sh
EOF
sudo chmod +x /usr/bin/waydroid-fix-controllers

# waydroid startup scripts
sudo cp bin/waydroid-startup-scripts /usr/bin/waydroid-startup-scripts
sudo chmod +x /usr/bin/waydroid-startup-scripts

echo "INFO: Waydroid services and custom scripts configured successfully!"
debug "Waydroid services and custom scripts configured successfully."

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

# Process the selected version
case "$CHOICE" in
    13tv)
        echo "INFO: Installing Android 13 TV image..."
        debug "Installing Android 13 TV image."
        download_image "${ANDROID13_TV_IMG}" "${ANDROID13_TV_IMG_HASH}" "${HOME}/waydroid/custom/13tv" "Android 13 TV"
        initialize_waydroid
        sudo cp extras/ATV-Generic.kl /var/lib/waydroid/overlay/system/usr/keylayout/Generic.kl
        configure_waydroid_base_prop \
            "7.0" \
            "PH7M_EU_5596" \
            "Philips/PH7M_EU_5596/PH7M_EU_5596:7.0/NTG46/276:user/release-keys" \
            "Philips" \
            "Philips" \
            "TPM171E" \
            "NTG46"
        ;;
    13)
        echo "INFO: Installing Android 13 image..."
        debug "Installing Android 13 image."
        download_image "${ANDROID13_IMG}" "${ANDROID13_IMG_HASH}" "${HOME}/waydroid/custom/13" "Android 13"
        initialize_waydroid
        configure_waydroid_base_prop \
            "11" \
            "redfin" \
            "google/redfin/redfin:11/RQ3A.211001.001/eng.electr.20230318.111310:user/release-keys" \
            "google" \
            "Valve" \
            "Steam Deck" \
            "RQ3A.211001.001"
        ;;
    *)
        echo "ERROR: Invalid version specified: ${CHOICE}"
        debug "Invalid version specified: ${CHOICE}"
        usage
        ;;
esac

# Check if this is a reinstall
echo "INFO: Checking if this is a reinstall..."
debug "Checking if this is a reinstall."
if grep -qE "redfin|Philips" /var/lib/waydroid/waydroid.prop &> /dev/null; then
    echo "INFO: This appears to be a reinstall. No further configuration is needed."
    debug "Reinstall detected. Skipping additional configuration."

    # Re-enable SteamOS readonly mode
    readonly_mode enable
    echo "SUCCESS: Waydroid has been successfully installed!"
else
    echo "INFO: Config file missing. Proceeding with Waydroid configuration..."
    debug "Config file missing. Proceeding with Waydroid configuration."

    # Determine if Google Apps should be installed
    if [[ $INSTALL_GAPPS -eq 1 ]]; then
        GAPPS_FLAG="-s GAPPS"
        SNEK_APPS="gapps"
        echo "INFO: Google Apps installation is enabled."
        debug "Google Apps installation is enabled."
    fi

    # Initialize Waydroid
    echo "INFO: Initializing Waydroid..."
    debug "Initializing Waydroid."
    mkdir -p "${HOME}/waydroid/{images,cache_http}"
    sudo mkdir -p /var/lib/waydroid &> /dev/null
    sudo ln -s "${HOME}/waydroid/images" /var/lib/waydroid/images &> /dev/null
    sudo ln -s "${HOME}/waydroid/cache_http" /var/lib/waydroid/cache_http &> /dev/null
    sudo waydroid init ${GAPPS_FLAG}
    if [ $? -eq 0 ]; then
        echo "INFO: Waydroid initialization completed successfully!"
        debug "Waydroid initialization completed successfully."
    else
        echo "ERROR: Waydroid initialization failed. Please check the logs for more details."
        debug "Waydroid initialization failed."
        cleanup_exit
    fi

    # Configure firewall
    echo "INFO: Configuring firewall for Waydroid..."
    debug "Configuring firewall for Waydroid."
    configure_firewall

    # Run Casualsnek script
    echo "INFO: Running Casualsnek script to install additional components..."
    debug "Running Casualsnek script."
    cd "${DIR_CASUALSNEK}"
    python3 -m venv venv
    venv/bin/pip install -r requirements.txt &> /dev/null
    sudo venv/bin/python3 main.py --android-version 13 install {libndk,widevine} ${SNEK_APPS} &> /dev/null
    if [ $? -eq 0 ]; then
        echo "INFO: Casualsnek script completed successfully!"
        debug "Casualsnek script completed successfully."
    else
        echo "ERROR: Casualsnek script failed. Please try running the script again."
        debug "Casualsnek script failed."
        cleanup_exit
    fi

    # Add Waydroid shortcut to Steam
    echo "INFO: Adding Waydroid shortcut to Steam..."
    debug "Adding Waydroid shortcut to Steam."
    cat <<EOF >"${HOME}/Applications/Waydroid.desktop"
[Desktop Entry]
Type=Application
Name=Waydroid
Exec=${ANDROID_HOME}/android_launcher.sh
Icon=waydroid
Categories=X-WayDroid-App;
X-Purism-FormFactor=Workstation;Mobile;
EOF
    chmod 0755 "${HOME}/Applications/Waydroid.desktop"
    steamos-add-to-steam "${HOME}/Applications/Waydroid.desktop"
    echo "INFO: Waydroid shortcut added to Steam successfully!"
    debug "Waydroid shortcut added to Steam successfully."

    # Re-enable SteamOS readonly mode
    readonly_mode enable
    echo "SUCCESS: Waydroid has been successfully installed!"
fi

# Final GPU rendering configuration
echo "INFO: Configuring GPU rendering to use minigbm_gbm_mesa..."
debug "Configuring GPU rendering to use minigbm_gbm_mesa."
sudo sed -i "s/ro.hardware.gralloc=.*/ro.hardware.gralloc=minigbm_gbm_mesa/g" /var/lib/waydroid/waydroid_base.prop

echo "SUCCESS: Waydroid installation script completed successfully!"
debug "Waydroid installation script completed successfully."


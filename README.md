# SteamOS Android Waydroid Installer

A collection of tools that is packaged into an easy to use script that is streamlined and tested to work with the Steam Deck running on SteamOS.
* The main program that does all the heavy lifting is [Waydroid - a container-based approach to boot a full Android system on a regular GNU/Linux system.](https://github.com/waydroid/waydroid)
* Waydroid Toolbox to easily toggle some configuration settings for Waydroid.
* [waydroid_script](https://github.com/casualsnek/waydroid_script) to easily add the libndk ARM translation layer and widevine.
* [libndk-fixer](https://github.com/Slappy826/libndk-fixer) is a fixed / improved libndk translation layer specific for Roblox [(demo guide here)](https://youtu.be/-czisFuKoTM?si=8EPXyzasi3no70Tl).

## Installation Steps
1. Go into Desktop Mode and open `konsole`.
2. Clone the github repo.
```
cd ~/
git clone https://github.com/SteamFork/steamos-waydroid-installer
```
3. Execute the script!
```
cd ~/steamos-waydroid-installer \
chmod +x installer.sh \
./installer.sh
```
4. Script will automatically install Waydroid together and a custom config. Please be patient as this may take a few minutes.
5. Once done close `konsole` and re-enter Game Mode.

## Launching Waydroid
1. Go to Game Mode.
2. Use the Steam Grid Manager Decky plugin to decorate the launcher if desired.
3. Run the Waydroid launcher.

## I dont want this anymore! I want to uninstall!
1. Go to Desktop Mode.
2. Launch Waydroid Toolbox (from the desktop).
3. Select UNINSTALL.

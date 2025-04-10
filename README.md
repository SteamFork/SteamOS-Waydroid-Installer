# SteamFork Android Waydroid Installer

A collection of tools that is packaged into an easy-to-use script that is streamlined and tested to work with the Steam Deck running on SteamFork.

This project is a fork of [SteamOS-Waydroid-Installer by ryanrudolfoba](https://github.com/ryanrudolfoba/SteamOS-Waydroid-Installer), with additional features and improvements for enhanced functionality.

* The main program that does all the heavy lifting is [Waydroid - a container-based approach to boot a full Android system on a regular GNU/Linux system.](https://github.com/waydroid/waydroid)
* Waydroid Toolbox to easily toggle some configuration settings for Waydroid.
* [waydroid_script](https://github.com/casualsnek/waydroid_script) to easily add the libndk ARM translation layer and widevine.
* [libndk-fixer](https://github.com/Slappy826/libndk-fixer) is a fixed/improved libndk translation layer specific for Roblox [(demo guide here)](https://youtu.be/-czisFuKoTM?si=8EPXyzasi3no70Tl).

---

## Installation Steps
1. Go into Desktop Mode and open `konsole`.
2. Clone the GitHub repository:
   ```bash
   cd ~/
   git clone https://github.com/SteamFork/steamos-waydroid-installer
   ```
3. Execute the script:
   ```bash
   cd ~/steamos-waydroid-installer
   chmod +x installer.sh
   ./installer.sh
   ```
4. The script will automatically install Waydroid along with a custom configuration. Please be patient as this may take a few minutes.
5. Once done, close `konsole` and re-enter Game Mode.

---

## Command-Line Options for the Installer
The `installer.sh` script now supports command-line options for selecting the Android version to install. If no options are provided, a `zenity` window will appear to allow interactive selection.

### Usage:
```bash
./installer.sh --version [A13_TV|A13]
```

### Options:
- `--version A13_TV`: Installs Android 13 TV.
- `--version A13`: Installs standard Android 13.

If no `--version` option is provided, the script will display a graphical menu to select the version interactively.

## Launching Waydroid
1. Go to Game Mode.
2. Use the Steam Grid Manager Decky plugin to decorate the launcher if desired.
3. Run the Waydroid launcher.

---

## Uninstalling Waydroid
1. Go to Desktop Mode.
2. Launch Waydroid Toolbox (from the desktop).
3. Select `UNINSTALL`.

---

## Additional Notes
- The installer script now includes error handling and cleanup functionality to ensure a smooth installation process.
- The build script includes ARM translation for compatibility with ARM-based applications.
- For advanced users, the build script can be customized to target other Android versions or configurations.

---

## Credits
This project is based on the original [SteamOS-Waydroid-Installer by ryanrudolfoba](https://github.com/ryanrudolfoba/SteamOS-Waydroid-Installer). Special thanks to all contributors of the upstream project.

Feel free to contribute to this repository or report any issues on [GitHub](https://github.com/SteamFork/steamos-waydroid-installer).

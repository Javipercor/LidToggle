# LidToggle

A native macOS menu bar app that toggles system sleep, including sleep triggered by closing the lid on supported Macs. Built with Swift and AppKit, with no external dependencies.

## Requirements

- macOS 13 Ventura or later.
- Apple's Command Line Tools with Swift 5.9 or later, or a compatible Xcode installation, to build from source.
- Administrator credentials to change the sleep setting.

The build script produces an app for your Mac's current architecture (Apple Silicon or Intel).

## Build and install

1. Open Terminal and change to the project directory:

   ```sh
   cd /path/to/LidToggle
   ```

2. If Apple's developer tools are not installed, run this command and complete the installer:

   ```sh
   xcode-select --install
   ```

3. Build and open the app:

   ```sh
   ./Scripts/build-app.sh
   open build/LidToggle.app
   ```

4. To install it for your user account, quit the running app and copy it to your Applications folder:

   ```sh
   mkdir -p "$HOME/Applications"
   ditto build/LidToggle.app "$HOME/Applications/LidToggle.app"
   open "$HOME/Applications/LidToggle.app"
   ```

LidToggle appears in the menu bar, with no Dock icon or main window. The build is signed locally with an ad hoc signature; it is not notarized for distribution. You can also open `Package.swift` in Xcode to inspect or develop the project.

## Use

1. Click the moon icon in the menu bar.
2. Select **Keep awake with the lid closed**.
3. Authenticate in the macOS administrator dialog. Canceling leaves the setting unchanged.
4. A sun icon and **Keep awake: enabled** indicate that sleep is blocked.
5. To return to normal behavior, select **Allow sleep when the lid is closed** and authenticate again.

The app reads the actual system setting when you open the menu and every ten seconds. It also verifies the setting after each change. A question mark means the sleep status could not be read; toggling is disabled until the status is available.

## Quit and restore sleep

Select **Quit…** from the menu. If sleep is blocked, the app offers:

- **Restore Sleep and Quit**: restores normal sleep, verifies the change, and exits. Canceling administrator authorization keeps the app open.
- **Cancel**: keeps the app running.
- **Quit Without Restoring**: exits and leaves sleep blocked.

The setting persists if you force quit the app, the app crashes, or you restart without restoring sleep. To restore normal sleep manually in Terminal:

```sh
sudo /usr/bin/pmset -a disablesleep 0
```

## How it works

LidToggle reads the sleep setting using `/usr/bin/pmset -g`. It runs one of these fixed commands through the macOS administrator authorization dialog:

```sh
/usr/bin/pmset -a disablesleep 1  # Block system sleep
/usr/bin/pmset -a disablesleep 0  # Restore normal sleep
```

This changes system sleep on both battery and AC power, including while the lid is open. It does not force the display to stay on. The app does not install background services or passwordless sudo rules.

A Mac that stays awake with its lid closed continues to use battery and generate heat. Restore sleep before putting it in a bag. Lid behavior depends on your hardware and macOS version, so verify it on your Mac before relying on it for a long-running task.

## Troubleshooting

- **No Dock icon or window:** this is expected. Look for the moon, sun, or question mark in the menu bar.
- **Authorization was canceled:** select the action again when you are ready to authenticate.
- **Sleep status unavailable:** check whether `pmset -g` works in Terminal, then reopen the menu.
- **Your Mac still sleeps with the lid closed:** check the reported status using the command below. Physical lid behavior must be tested on your hardware.
- **Your Mac stays awake after quitting:** restore sleep using the manual recovery command above.

Read the current status without changing any settings:

```sh
build/LidToggle.app/Contents/MacOS/LidToggle --status
```

If you installed the app in your user Applications folder, use:

```sh
"$HOME/Applications/LidToggle.app/Contents/MacOS/LidToggle" --status
```

## Development and verification

```sh
swift test
./Scripts/build-app.sh
build/LidToggle.app/Contents/MacOS/LidToggle --status
```

The automated tests cover parsing the system sleep setting, including missing overrides and invalid output. Tests and the status command do not change power settings.

For a manual end-to-end check:

1. Enable keep-awake mode and authorize the change.
2. Close the lid and verify that your task continues running.
3. Open the lid, restore sleep, and verify normal lid behavior.
4. Check that canceling authorization leaves the setting unchanged.
5. Enable keep-awake mode again, choose **Restore Sleep and Quit**, and confirm that normal sleep is restored.

## Uninstall

Restore normal sleep and quit the app first. Then move `LidToggle.app` from your Applications folder to the Trash. You can also delete the project folder if you no longer need the source code. Deleting the app alone does not restore the system sleep setting.

## References

See the system's `man pmset` manual and the [SleepSwitch documentation](https://github.com/tim0120/SleepSwitch#what-it-changes), which links to Apple's power management implementation. LidToggle uses its own implementation.

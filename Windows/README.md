# LidToggle for Windows 11

A Windows Forms tray app with the same compact menu as the macOS version. Right-click its notification-area icon (it may be under the hidden-icons arrow), then select **Keep awake with the lid closed**. To stop, select **Restore previous lid settings** or **Quit…**. No informational message rows are shown in the menu.

## Run

Copy `LidToggle.exe` from the published output to your Windows 11 laptop and double-click it. Accept the Windows administrator prompt. The self-contained executable does not need a separate .NET installation. It is locally built and unsigned; Windows may show its publisher as unknown.

`win-x64` is for Intel/AMD PCs. Use `win-arm64` for Windows on ARM. No installer, service or automatic startup is installed. To uninstall, quit through the tray menu and delete the executable.

## Behavior and recovery

- Enabling saves the active plan's original AC and battery lid-close actions, then sets both to **Do nothing**. It also requests that Windows prevent idle system sleep while the app is running; the display may still turn off.
- Disabling or quitting restores the exact saved actions, including hibernation or shutdown if those were selected before enabling.
- Changing power plans or editing the lid actions externally ends the session at the next refresh (at most ten seconds). The app restores the saved plan without selecting it again.
- Recovery data is stored in `%LOCALAPPDATA%\LidToggle\power-settings.json` under the account running the app. After a forced quit or power loss, lid actions can remain changed. Reopen LidToggle under the same account to restore them. Do not delete the recovery file before restoration succeeds.
- If restoration fails, the app keeps the backup and offers a retry. Normal exit waits for restoration. Shutdown/logoff triggers a best-effort restoration; recovery data remains if interrupted.
- Company policies, firmware and device sleep support can override these requests. Check actual lid behavior on your laptop. Keeping a closed laptop awake consumes battery and produces heat; restore its settings before putting it in a bag.

## Build

Install the .NET 10 SDK. From the repository root on macOS/Linux:

```sh
./Scripts/build-windows.sh
./Scripts/build-windows.sh win-arm64
```

Or in Windows PowerShell:

```powershell
dotnet publish Windows/LidToggle -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:DebugType=None -o build/win-x64
```

Output: `build/win-x64/LidToggle.exe` (or `build/win-arm64/LidToggle.exe`).

## Windows verification

Compilation can be checked from macOS; running the UI and Windows power APIs requires Windows. On a Windows 11 laptop:

1. Record the lid actions for AC and battery in Power Options.
2. Enable the toggle. Check both actions are **Do nothing** and test lid closure on AC and battery.
3. Disable and confirm both original actions return. Repeat with **Quit…**.
4. Enable, terminate from Task Manager, and reopen. Confirm recovery restores the original actions.
5. Enable and switch power plans. Confirm the prior plan is restored and the new plan stays selected.
6. Cancel the administrator prompt and confirm no app starts and no settings change. Test a second launch while running; only one tray icon should appear.

## Microsoft API references

- [Lid-close actions and values](https://learn.microsoft.com/en-us/windows-hardware/customize/power-settings/power-button-and-lid-settings-lid-switch-close-action)
- [PowerWriteACValueIndex and applying a power scheme](https://learn.microsoft.com/en-us/windows/win32/api/powersetting/nf-powersetting-powerwriteacvalueindex)
- [SetThreadExecutionState](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate)

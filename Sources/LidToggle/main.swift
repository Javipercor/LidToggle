import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let stateItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let toggleItem = NSMenuItem(title: "", action: #selector(toggle), keyEquivalent: "t")
    private let quitItem = NSMenuItem(title: "Quit…", action: #selector(quit), keyEquivalent: "q")
    private var state: PowerState?
    private var busy = false
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu.delegate = self
        menu.autoenablesItems = false
        toggleItem.target = self
        quitItem.target = self
        menu.addItem(NSMenuItem(title: "LidToggle", action: nil, keyEquivalent: ""))
        menu.addItem(stateItem)
        menu.addItem(.separator())
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        for title in ["Also prevents sleep while the lid is open.",
                      "A closed, awake Mac uses battery and generates heat.",
                      "Restore sleep before putting your Mac in a bag."] {
            menu.addItem(NSMenuItem(title: title, action: nil, keyEquivalent: ""))
        }
        menu.addItem(.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            guard let self, !self.busy else { return }
            self.refresh()
        }
    }

    func menuWillOpen(_ menu: NSMenu) { if !busy { refresh() } }

    private func refresh() {
        state = PowerState.read()
        stateItem.title = state.map { $0 == .blocked ? "● Keep awake: enabled" : "Normal sleep: enabled" }
            ?? "Sleep status unavailable"
        toggleItem.title = state == .blocked ? "Allow sleep when the lid is closed" : "Keep awake with the lid closed"
        toggleItem.state = state == .blocked ? .on : .off
        toggleItem.isEnabled = state != nil && !busy
        quitItem.isEnabled = !busy
        let symbol = state.map { $0 == .blocked ? "sun.max.fill" : "moon.zzz" } ?? "questionmark.circle"
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: stateItem.title)
        statusItem.button?.toolTip = "LidToggle · \(stateItem.title)"
    }

    @objc private func toggle() {
        refresh()
        guard let state, !busy else { return }
        change(to: state == .blocked ? .normal : .blocked)
    }

    private func change(to desired: PowerState, exitAfter: Bool = false) {
        busy = true
        toggleItem.isEnabled = false
        quitItem.isEnabled = false
        stateItem.title = "Waiting for administrator authorization…"
        let value = desired == .blocked ? 1 : 0
        // Only the fixed pmset command is elevated. No user input enters this script.
        let source = "do shell script \"/usr/bin/pmset -a disablesleep \(value)\" with administrator privileges"
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
            let errorCode = error?[NSAppleScript.errorNumber] as? Int
            let errorMessage = error?[NSAppleScript.errorMessage] as? String
            DispatchQueue.main.async {
                self.busy = false
                self.refresh()
                if errorCode == -128 { return } // User cancelled: leave state unchanged.
                guard errorMessage == nil, self.state == desired else {
                    let alert = NSAlert()
                    alert.messageText = "Could not change the sleep setting"
                    alert.informativeText = errorMessage ?? "Could not verify the new sleep setting. Please try again."
                    alert.alertStyle = .warning
                    alert.runModal()
                    return
                }
                if exitAfter { NSApp.terminate(nil) }
            }
        }
    }

    @objc private func quit() {
        refresh()
        guard state == .normal else {
            let alert = NSAlert()
            alert.messageText = "Restore sleep before quitting"
            alert.informativeText = "This setting persists. If you quit without restoring sleep, your Mac may stay awake with the lid closed, even after restarting."
            alert.addButton(withTitle: "Restore Sleep and Quit")
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "Quit Without Restoring")
            switch alert.runModal() {
            case .alertFirstButtonReturn: change(to: .normal, exitAfter: true)
            case .alertThirdButtonReturn: NSApp.terminate(nil)
            default: break
            }
            return
        }
        NSApp.terminate(nil)
    }
}

if CommandLine.arguments.contains("--status") {
    switch PowerState.read() {
    case .normal: print("Normal sleep (SleepDisabled = 0)")
    case .blocked: print("Sleep blocked (SleepDisabled = 1)")
    case nil: fputs("Could not read the sleep status.\n", stderr); exit(1)
    }
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.setActivationPolicy(.accessory)
    app.delegate = delegate
    app.run()
}

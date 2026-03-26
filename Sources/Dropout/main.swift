import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // No Dock icon — menu bar only

let delegate = DropoutApp()
app.delegate = delegate
app.run()

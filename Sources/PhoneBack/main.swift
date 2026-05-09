import SwiftUI
import AppKit
import UserNotifications

@main
struct PhoneBackApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, UNUserNotificationCenterDelegate {
    
    var statusItem: NSStatusItem?
    var activeWindows: [NSWindow] = []
    var inactivityTimer: Timer?
    var notificationTimer: Timer?
    var nonInteractedCount: Int = 0
    var flashTimers: [Timer] = []
    var secretInput: String = ""
    
    let notificationMessages = [
        "Give me my phone back!", "Stop taking my phone!", "Return my phone immediately",
        "I need my phone back right now", "You're not supposed to take me!", "Phone thief!",
        "This isn't funny anymore", "Give me back my phone!", "Stop hiding my phone!",
        "Where is my phone?!"
    ]
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                UNUserNotificationCenter.current().delegate = self
            }
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)
            button.action = #selector(showNewWindow)
        }
        
        startNotificationTimer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showNewWindow()
        }
    }
    
    // Rest of the code (I'll send the full version in next message because it's long)
    // For now, let's test the build first
    @objc func showNewWindow(isInteractionReset: Bool = false) {
        print("Window requested")
    }
    
    func startNotificationTimer() {
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 50, repeats: true) { [weak self] _ in
            self?.sendRandomNotification()
        }
    }
    
    func sendRandomNotification() {
        let content = UNMutableNotificationContent()
        content.title = "PhoneBack"
        content.body = notificationMessages.randomElement() ?? "Give me my phone back!"
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    deinit {
        notificationTimer?.invalidate()
    }
}

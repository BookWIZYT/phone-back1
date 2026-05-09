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
        "Where is my phone?!", "Bring me back to my owner", "Don't take my phone again"
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
    
    // ... (All the functions are included below - this is the complete version)
    func startNotificationTimer() {
        notificationTimer?.invalidate()
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 50.0, repeats: true) { [weak self] _ in
            self?.sendRandomNotification()
        }
    }
    
    func sendRandomNotification() {
        let message = notificationMessages.randomElement() ?? "Give me my phone back!"
        let content = UNMutableNotificationContent()
        content.title = "PhoneBack"
        content.body = message
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.showNewWindow(isInteractionReset: true)
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    @objc func showNewWindow(isInteractionReset: Bool = false) {
        invalidateTimers()
        if isInteractionReset {
            nonInteractedCount = 0
            secretInput = ""
        }
        
        let isEarlyWindow = nonInteractedCount < 3
        
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                              styleMask: [.titled, .closable, .miniaturizable],
                              backing: .buffered, defer: false)
        
        window.title = "Give me my phone back"
        window.center()
        window.delegate = self
        window.isReleasedWhenClosed = false
        
        if !activeWindows.isEmpty {
            let offset = CGFloat(activeWindows.count * 30)
            window.setFrameOrigin(NSPoint(x: window.frame.origin.x + offset, y: window.frame.origin.y - offset * 0.6))
        }
        
        let contentView = HelloWorldView(isEarly: isEarlyWindow, window: window, secretDelegate: self)
        window.contentView = NSHostingView(rootView: contentView)
        
        window.makeKeyAndOrderFront(nil)
        activeWindows.append(window)
        NSApp.activate(ignoringOtherApps: true)
        
        startInactivityTimer()
        
        if !isEarlyWindow {
            startFlashing(for: window)
        }
    }
    
    func handleKeyInput(_ key: String) {
        secretInput += key.lowercased()
        if secretInput.count > 10 { secretInput.removeFirst(secretInput.count - 10) }
        if secretInput.contains("895") {
            shutdownAllWindows()
        }
    }
    
    func shutdownAllWindows() {
        activeWindows.forEach { $0.close() }
        activeWindows.removeAll()
        invalidateTimers()
        nonInteractedCount = 0
        secretInput = ""
    }
    
    func startInactivityTimer() {
        invalidateInactivityTimer()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.nonInteractedCount >= 20 && !self.activeWindows.isEmpty {
                let toClose = min(10, self.activeWindows.count)
                for _ in 0..<toClose {
                    if let old = self.activeWindows.first {
                        old.close()
                        self.activeWindows.removeFirst()
                    }
                }
            }
            self.nonInteractedCount += 1
            self.showNewWindow()
        }
    }
    
    func invalidateInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }
    
    func startFlashing(for window: NSWindow) {
        let flashTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak window] _ in
            guard let w = window, let hosting = w.contentView as? NSHostingView<HelloWorldView> else { return }
            let isYellow = (Int(Date().timeIntervalSince1970 * 2) % 2 == 0)
            let bg = isYellow ? Color.yellow : Color(red: 0.0, green: 1.0, blue: 0.4)
            let txt = isYellow ? Color.purple : Color.red
            hosting.rootView = HelloWorldView(isEarly: false, window: w, backgroundColor: bg, textColor: txt)
        }
        flashTimers.append(flashTimer)
    }
    
    func invalidateTimers() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        flashTimers.forEach { $0.invalidate() }
        flashTimers.removeAll()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        activeWindows.removeAll { $0 == sender }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else { return }
            self.nonInteractedCount = 0
            for _ in 0..<3 {
                self.showNewWindow(isInteractionReset: true)
            }
        }
        return false
    }
    
    func windowDidMiniaturize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        window.orderOut(nil)
        activeWindows.removeAll { $0 == window }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else { return }
            self.nonInteractedCount = 0
            for _ in 0..<3 {
                self.showNewWindow(isInteractionReset: true)
            }
        }
    }
    
    @objc func systemWillSleep() {
        activeWindows.forEach { $0.close() }
        activeWindows.removeAll()
        invalidateTimers()
        nonInteractedCount = 0
    }
    
    @objc func systemDidWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 120.0) { [weak self] in
            self?.showNewWindow(isInteractionReset: true)
        }
    }
    
    deinit {
        notificationTimer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

struct HelloWorldView: View {
    let isEarly: Bool
    weak var window: NSWindow?
    var backgroundColor: Color = .white
    var textColor: Color = .red
    weak var secretDelegate: AppDelegate?
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            VStack {
                Spacer()
                Text("Give me my phone back")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            
            TextField("", text: Binding(get: { "" }, set: { secretDelegate?.handleKeyInput($0) }))
                .textFieldStyle(.plain)
                .opacity(0.02)
                .frame(height: 40)
                .offset(y: 160)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

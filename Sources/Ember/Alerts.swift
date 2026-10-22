import AppKit
import UserNotifications

enum Alerts {
    private static var canNotify: Bool { Bundle.main.bundleIdentifier != nil && Bundle.main.bundlePath.hasSuffix(".app") }

    static func requestAuthorization() {
        guard canNotify else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func timerDone(_ label: String, prefs: Prefs) {
        guard prefs.notificationsEnabled, canNotify else { return }
        let content = UNMutableNotificationContent()
        content.title = "Timer done"
        content.body = label
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    static func play(_ name: String, volume: Double) {
        guard let sound = NSSound(named: NSSound.Name(name)) else { return }
        sound.volume = Float(volume)
        sound.play()
    }
}

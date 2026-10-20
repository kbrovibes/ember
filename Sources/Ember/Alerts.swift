import AppKit
import UserNotifications
import EmberCore

enum Alerts {
    private static var canNotify: Bool { Bundle.main.bundleIdentifier != nil && Bundle.main.bundlePath.hasSuffix(".app") }

    static func requestAuthorization() {
        guard canNotify else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func segmentEnded(_ ended: Phase, next: Phase, sound: Bool, notify: Bool) {
        if sound { play(ended == .focus ? "Glass" : "Pop") }
        guard notify, canNotify else { return }

        let content = UNMutableNotificationContent()
        switch ended {
        case .focus:
            content.title = next == .longBreak ? "Long break" : "Break time"
            content.body = "Nice focus. Step away for a bit."
        case .shortBreak, .longBreak:
            content.title = "Back to focus"
            content.body = "Break's over."
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    static func play(_ name: String) {
        NSSound(named: NSSound.Name(name))?.play()
    }
}

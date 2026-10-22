import AppKit
import UserNotifications
import EmberCore

enum Alerts {
    private static var canNotify: Bool { Bundle.main.bundleIdentifier != nil && Bundle.main.bundlePath.hasSuffix(".app") }

    static func requestAuthorization() {
        guard canNotify else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func segmentEnded(_ ended: Phase, next: Phase, prefs: Prefs) {
        if prefs.soundEnabled { play(ended == .focus ? prefs.focusEndSound : prefs.breakEndSound, volume: prefs.soundVolume) }
        guard prefs.notificationsEnabled, canNotify else { return }

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

    static func timerDone(_ label: String, prefs: Prefs) {
        if prefs.soundEnabled { play(prefs.timerSound, volume: prefs.soundVolume) }
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

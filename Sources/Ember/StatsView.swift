import SwiftUI
import EmberCore

struct StatsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let s = model.summary
        let total = model.records.reduce(0) { $0 + $1.duration }
        VStack(alignment: .leading, spacing: 28) {
            Text("Stats").font(.system(size: 22, weight: .semibold))

            HStack(spacing: 14) {
                card("Today", value: s.todaySessions == 0 ? "—" : TimeFormat.spoken(s.todayFocus), note: "\(s.todaySessions) session\(s.todaySessions == 1 ? "" : "s")")
                card("Streak", value: s.streakDays == 0 ? "—" : "\(s.streakDays) day\(s.streakDays == 1 ? "" : "s")", note: "consecutive days")
                card("All time", value: total == 0 ? "—" : TimeFormat.spoken(total), note: "\(model.records.count) sessions")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Last 7 days").font(.system(size: 13, weight: .semibold))
                weekBars(s.last7Days)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Recent").font(.system(size: 13, weight: .semibold))
                if model.records.isEmpty {
                    Text("Finish a focus session and it shows up here.").font(.system(size: 12)).foregroundStyle(Theme.ink3)
                } else {
                    ForEach(model.records.suffix(5).reversed()) { r in
                        HStack {
                            Image(systemName: Phase.focus.symbol).foregroundStyle(Theme.accent(.focus)).font(.system(size: 11))
                            Text(r.endedAt.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 12))
                            Spacer()
                            Text(TimeFormat.spoken(r.duration)).font(.system(size: 12, weight: .medium)).monospacedDigit().foregroundStyle(Theme.ink2)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(28)
        .frame(minWidth: 560, minHeight: 440, alignment: .topLeading)
        .background(Theme.bg)
    }

    private func card(_ title: String, value: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.ink3)
            Text(value).font(.system(size: 22, weight: .light)).monospacedDigit().foregroundStyle(Theme.ink)
            Text(note).font(.system(size: 11)).foregroundStyle(Theme.ink3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.line))
    }

    private func weekBars(_ days: [TimeInterval]) -> some View {
        let peak = max(days.max() ?? 0, 1)
        let cal = Calendar.current
        return HStack(alignment: .bottom, spacing: 12) {
            ForEach(Array(days.enumerated()), id: \.offset) { i, seconds in
                let date = cal.date(byAdding: .day, value: i - 6, to: Date())!
                VStack(spacing: 6) {
                    Text(seconds > 0 ? "\(Int(seconds / 60))" : " ").font(.system(size: 10)).monospacedDigit().foregroundStyle(Theme.ink3)
                    Capsule()
                        .fill(i == 6 ? Theme.accent(.focus) : Theme.accent(.focus).opacity(0.35))
                        .frame(height: max(4, 70 * seconds / peak))
                    Text(date.formatted(.dateTime.weekday(.narrow))).font(.system(size: 11, weight: i == 6 ? .semibold : .regular)).foregroundStyle(i == 6 ? Theme.ink : Theme.ink3)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 110, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus minutes over the last 7 days: " + days.map { "\(Int($0 / 60))" }.joined(separator: ", "))
    }
}

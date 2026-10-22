import SwiftUI

/// Segmented sort control. Choosing the active key again flips the direction.
struct SortBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 2) {
            ForEach(TimerSort.allCases) { sort in
                let active = model.prefs.sort == sort
                Button { withAnimation(Theme.layout) { model.chooseSort(sort) } } label: {
                    HStack(spacing: 4) {
                        Text(sort.title)
                        if active && sort != .added || (active && !model.prefs.sortAscending) {
                            Image(systemName: model.prefs.sortAscending ? "arrow.up" : "arrow.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                    }
                    .font(.system(size: 12, weight: active ? .semibold : .medium))
                    .foregroundStyle(active ? Theme.accent : Theme.ink3)
                    .padding(.horizontal, 11)
                    .frame(height: 26)
                    .background(Capsule().fill(active ? Theme.soft : .clear))
                }
                .buttonStyle(PressStyle())
                .help(active ? "Sorted by \(sort.title.lowercased()), click to reverse" : "Sort by \(sort.title.lowercased())")
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Capsule().fill(Theme.surface))
        .overlay(Capsule().strokeBorder(Theme.line))
    }
}

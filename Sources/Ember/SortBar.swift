import SwiftUI

/// Quiet text tabs with a sliding accent underline. Choosing the active one again flips the direction.
struct SortBar: View {
    @Environment(AppModel.self) private var model
    @Namespace private var underline

    var body: some View {
        HStack(spacing: 20) {
            ForEach(TimerSort.allCases) { sort in
                let active = model.prefs.sort == sort
                Button { withAnimation(Theme.layout) { model.chooseSort(sort) } } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: sort.symbol).font(.system(size: 11, weight: .semibold))
                            Text(sort.title)
                            if active && (sort != .added || !model.prefs.sortAscending) {
                                Image(systemName: model.prefs.sortAscending ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 9, weight: .bold))
                            }
                        }
                        .font(.system(size: 13, weight: active ? .semibold : .medium))
                        .foregroundStyle(active ? Theme.ink : Theme.ink3)

                        ZStack {
                            Capsule().fill(.clear).frame(height: 2)
                            if active {
                                Capsule().fill(Theme.accent).frame(height: 2)
                                    .matchedGeometryEffect(id: "underline", in: underline)
                            }
                        }
                    }
                    .fixedSize()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .fixedSize()
                .help(active ? "Sorted by \(sort.title.lowercased()), click to reverse" : "Sort by \(sort.title.lowercased())")
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
    }
}

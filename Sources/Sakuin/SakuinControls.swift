import SwiftUI

struct SakuinIconButton: View {
    let icon: String
    let label: String
    var prominent = false
    var disabled = false
    let action: () -> Void
    @Environment(\.sakuinPalette) private var colors

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(prominent ? Color.white : colors.secondary)
                .frame(width: 30, height: 30)
                .background(prominent ? colors.accent : colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay {
                    if !prominent {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(colors.border.opacity(0.8), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.42 : 1)
        .help(label)
        .accessibilityLabel(label)
    }
}

import SwiftUI

struct SakuinColors {
    let isDark: Bool
    var base: Color { color(0xf5f7fa, 0x0b0f14) }
    var mantle: Color { color(0xffffff, 0x0f151d) }
    var surface: Color { color(0xe9eef5, 0x17202b) }
    var raised: Color { color(0xffffff, 0x1c2734) }
    var border: Color { color(0xd4dce7, 0x2b3949) }
    var text: Color { color(0x111827, 0xf2f6fb) }
    var secondary: Color { color(0x475569, 0xb6c2d0) }
    var muted: Color { color(0x718096, 0x78899d) }
    var accent: Color { color(0x0866d9, 0x4da3ff) }
    var accentSoft: Color { color(0xdbeafe, 0x112d49) }
    var blue: Color { accent }
    var success: Color { color(0x138a63, 0x42d3a0) }
    var danger: Color { color(0xc23b53, 0xff647c) }

    private func color(_ light: UInt32, _ dark: UInt32) -> Color {
        let hex = isDark ? dark : light
        return Color(.sRGB, red: Double((hex >> 16) & 255) / 255,
                     green: Double((hex >> 8) & 255) / 255,
                     blue: Double(hex & 255) / 255, opacity: 1)
    }
}

private struct SakuinPaletteKey: EnvironmentKey {
    static let defaultValue = SakuinColors(isDark: false)
}

extension EnvironmentValues {
    var sakuinPalette: SakuinColors {
        get { self[SakuinPaletteKey.self] }
        set { self[SakuinPaletteKey.self] = newValue }
    }
}

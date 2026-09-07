import SwiftUI

// Catppuccin Latte / Mocha: https://github.com/catppuccin/catppuccin
struct SakuinColors {
    let isDark: Bool
    var base: Color { color(0xeff1f5, 0x1e1e2e) }
    var mantle: Color { color(0xe6e9ef, 0x181825) }
    var surface: Color { color(0xccd0da, 0x313244) }
    var border: Color { color(0xbcc0cc, 0x45475a) }
    var text: Color { color(0x4c4f69, 0xcdd6f4) }
    var secondary: Color { color(0x5c5f77, 0xbac2de) }
    var muted: Color { color(0x6c6f85, 0xa6adc8) }
    var accent: Color { color(0x8839ef, 0xcba6f7) }
    var blue: Color { color(0x1e66f5, 0x89b4fa) }

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

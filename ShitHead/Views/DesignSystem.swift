// SheetHead/Views/DesignSystem.swift — Japanese Mountain Design System
import SwiftUI

// MARK: - Color Tokens

extension Color {
    // Parchment scale
    static let shParchment      = Color(hex: "#E0D0A5")
    static let shParchmentLight = Color(hex: "#EAE0C8")
    static let shParchmentDark  = Color(hex: "#D0C090")
    static let shParchmentDeep  = Color(hex: "#C0A878")

    // Ink scale
    static let shInk            = Color(hex: "#1A1815")
    static let shInkMed         = Color(hex: "#3A3530")
    static let shInkLight       = Color(hex: "#6B6050")
    static let shInkFaint       = Color(hex: "#9A9080")

    // Accent
    static let shCrimson        = Color(hex: "#C22C20")
    static let shCrimsonDeep    = Color(hex: "#8B1A1A")
    static let shCrimsonLight   = Color(hex: "#D43A2E")
    static let shGold           = Color(hex: "#C4A35A")
    static let shGoldLight      = Color(hex: "#D4B96A")

    // Board
    static let shBoardDark      = Color(hex: "#141919")
    static let shBoardMid       = Color(hex: "#1E2323")
    static let shMountain       = Color(hex: "#222727")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Font Tokens
// Required in Resources/: ShipporiMincho-Bold.ttf, ShipporiMincho-ExtraBold.ttf,
// ZenKakuGothicNew-Regular.ttf, ZenKakuGothicNew-Bold.ttf, NotoSerifCJKjp-Black.ttf
// Download from Google Fonts and add to Xcode target + Info.plist UIAppFonts.

extension Font {
    // Display — Shippori Mincho (Japanese-aesthetic Roman serif)
    static let shLogoLg     = Font.custom("ShipporiMincho-ExtraBold", size: 56)
    static let shDisplay    = Font.custom("ShipporiMincho-ExtraBold", size: 38)
    static let shLogoSm     = Font.custom("ShipporiMincho-Bold", size: 24)
    static let shTitle      = Font.custom("ShipporiMincho-Bold", size: 22)
    static let shButton     = Font.custom("ShipporiMincho-Bold", size: 18)
    static let shButtonSm   = Font.custom("ShipporiMincho-Bold", size: 14)
    static let shCardRank   = Font.custom("ShipporiMincho-Bold", size: 28)
    static let shCardCorner = Font.custom("ShipporiMincho-Bold", size: 11)

    // Body — Zen Kaku Gothic New
    static let shNavLabel   = Font.custom("ZenKakuGothicNew-Bold", size: 11)
    static let shLabel      = Font.custom("ZenKakuGothicNew-Bold", size: 11)
    static let shCaption    = Font.custom("ZenKakuGothicNew-Regular", size: 10)
    static let shScore      = Font.custom("ZenKakuGothicNew-Bold", size: 10)

    // Kanji accent — Noto Serif JP
    static let shKanjiXL    = Font.custom("NotoSerifCJKjp-Black", size: 120)
    static let shKanjiLg    = Font.custom("NotoSerifCJKjp-Black", size: 80)
    static let shKanjiMd    = Font.custom("NotoSerifCJKjp-Black", size: 28)
    static let shKanjiSm    = Font.custom("NotoSerifCJKjp-Black", size: 18)
    static let shKanjiXS    = Font.custom("NotoSerifCJKjp-Black", size: 14)
}

// MARK: - Card Sizes

enum CardSize: Equatable {
    case board      // 80×114 — draw/discard pile
    case player     // 52×74  — player hand + table cards (active)
    case opponent   // 36×52  — opponent hand
    case mini       // 32×44  — dormant table cards (hand phase)

    var width: CGFloat {
        switch self {
        case .board:    return 80
        case .player:   return 52
        case .opponent: return 36
        case .mini:     return 32
        }
    }
    var height: CGFloat {
        switch self {
        case .board:    return 114
        case .player:   return 74
        case .opponent: return 52
        case .mini:     return 44
        }
    }
    var cornerRadius: CGFloat { return 5 }
}

// MARK: - Animation Tokens

extension Animation {
    static let cardFlight = Animation.spring(response: 0.45, dampingFraction: 0.82)
    static let cardPlay   = Animation.spring(response: 0.38, dampingFraction: 0.78)
    static let uiSnap     = Animation.easeInOut(duration: 0.16)
    static let toastIn    = Animation.spring(response: 0.40, dampingFraction: 0.72)
    static let handReflow = Animation.easeInOut(duration: 0.20)
}

// MARK: - Haptic Manager

enum Haptics {
    private static var enabled: Bool { UserPreferences.shared.hapticsEnabled }
    static func light()   { guard enabled else { return }; UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()  { guard enabled else { return }; UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy()   { guard enabled else { return }; UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func rigid()   { guard enabled else { return }; UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    static func error()   { guard enabled else { return }; UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func success() { guard enabled else { return }; UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

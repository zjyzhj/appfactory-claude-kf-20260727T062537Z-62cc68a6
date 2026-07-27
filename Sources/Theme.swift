import SwiftUI

/// PM design.md "Evidence board on warm paper" — measurable palette / type /
/// shape tokens. Every reachable surface paints bg_paper edge-to-edge; panels
/// are white cards with 14pt corners; ONLY evidence photos get the 10pt corner
/// + ≤1.2° polaroid tilt (never data tables).
enum Theme {

    // MARK: Palette (design.md measurable tokens)
    static let bgPaper = Color(hex: 0xF6F1E7)      // bg_paper — full-page wash
    static let bgPanel = Color(hex: 0xFFFFFF)      // bg_panel — cards
    static let inkPrimary = Color(hex: 0x2B2620)   // ink_primary
    static let inkSecondary = Color(hex: 0x2B2620, opacity: 0.62)
    static let inkTertiary = Color(hex: 0x2B2620, opacity: 0.42)
    static let accentBrass = Color(hex: 0xB4762A)  // accent_brass — primary actions / rank #1
    static let accentSage = Color(hex: 0x6E7F5C)   // accent_sage — shortlist / positive
    static let warnTerracotta = Color(hex: 0xB4503C) // warn_terracotta — rejected / delete
    static let scoreTrack = Color(hex: 0xE4DCCB)   // score_track — bar rails
    static let heroFallbackStart = Color(hex: 0xE9DFC9) // hero slot fallback gradient
    static let heroFallbackEnd = Color(hex: 0xDCCFB2)
    static let photoStroke = Color.black.opacity(0.06) // #00000010 1pt evidence-photo stroke

    // MARK: Shape
    static let cardCorner: CGFloat = 14
    static let photoCorner: CGFloat = 10
    static let polaroidTiltDegrees: Double = 1.2 // ≤1.2°, evidence photos only

    // MARK: Type (design.md scale)
    static func pageTitle() -> Font { .system(size: 28, weight: .semibold) }       // 28/34 semibold
    static func sectionTitle() -> Font { .system(size: 17, weight: .semibold) }    // 17/22 semibold
    static func body() -> Font { .system(size: 15, weight: .regular) }             // 15/20 regular
    static func scoreNumber() -> Font { .system(size: 20, weight: .medium).monospacedDigit() } // 20/24 tabular-nums
    static func bigScore() -> Font { .system(size: 56, weight: .semibold).monospacedDigit() }
    static func caption() -> Font { .system(size: 13, weight: .regular) }

    // MARK: Status colors
    static func statusColor(_ status: ViewingStatus) -> Color {
        switch status {
        case .draft: return inkTertiary
        case .toured: return accentBrass
        case .shortlisted: return accentSage
        case .rejected: return warnTerracotta
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

/// Shared card chrome — white panel, 14pt corner, on warm paper.
struct PanelCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.bgPanel)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
    }
}

extension View {
    func panelCard() -> some View { modifier(PanelCard()) }

    /// Full-page warm-paper wash behind a screen's content.
    func paperBackground() -> some View {
        background(Theme.bgPaper.ignoresSafeArea())
    }
}

/// Polaroid-style evidence photo chrome: 10pt corner, 1pt hairline stroke,
/// slight ≤1.2° tilt. Evidence photos only — never applied to data tables.
struct PolaroidPhoto: View {
    let image: UIImage?
    var aspectRatio: CGFloat = 1.0
    var tiltDegrees: Double = Theme.polaroidTiltDegrees
    var accessibilityLabelText: String

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Theme.scoreTrack
                    Image(systemName: "photo")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Theme.photoCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.photoCorner, style: .continuous)
                .strokeBorder(Theme.photoStroke, lineWidth: 1)
        )
        .rotationEffect(.degrees(tiltDegrees))
        .accessibilityLabel(accessibilityLabelText)
    }
}

import SwiftUI
import UIKit

/// PM design.md "Motion & interaction language" — shared motion tokens.
/// Thesis: evidence lands on the board, conclusions surface — every score and
/// photo presses evidence onto the board; comparison and verdict emerge with
/// restrained growth and settle. Motion serves the chaos→certainty decision
/// mood, never decoration. Forbidden: carousels, particles, confetti,
/// forced full-screen photo admiration, rank flash-bangs.
enum MotionLanguage {
    /// dur_settle — 0.28s spring: evidence cards land, list inserts settle.
    static let durSettle = Animation.spring(response: 0.28, dampingFraction: 0.82)
    /// dur_grow — 0.45s easeOut: compare bars and rank changes regrow.
    static let durGrow = Animation.easeOut(duration: 0.45)
    /// dur_deal — 0.5s spring: verdict card deals in from the top edge.
    static let durDeal = Animation.spring(response: 0.5, dampingFraction: 0.75)
    /// stagger_room — 0.06s between walkthrough room steps / list card entrances.
    static let staggerRoom: Double = 0.06
    /// mot_empty_breathe — one 2.4s ±4pt breath, then rest (never loops).
    static let breatheCycle: Double = 2.4
    static let breatheAmplitude: CGFloat = 4

    /// Applies `animation` only when Reduce Motion is off; nil = instant state
    /// change, which is the declared Reduce Motion equivalent for every moment.
    static func animation(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}

enum TourWiseHaptics {
    /// haptic_commit — score submit / photo lands on the board.
    static func commit() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    /// haptic_verdict — verdict export succeeded.
    static func verdictSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

extension View {
    /// Animate a value change only when Reduce Motion is off.
    func tourwiseAnimation(_ animation: Animation, value: some Equatable, reduceMotion: Bool) -> some View {
        self.animation(MotionLanguage.animation(animation, reduceMotion: reduceMotion), value: value)
    }
}

/// mot_empty_breathe (ACC-MOT-EMPTY): the empty-state illustration floats ±4pt
/// for exactly one 2.4s cycle then rests; the Add button does one 5% brightness
/// pulse in sync. Reduce Motion → fully static.
struct OneBreathModifier: ViewModifier {
    let reduceMotion: Bool
    @State private var breathing = false

    func body(content: Content) -> some View {
        content
            .offset(y: breathing ? -MotionLanguage.breatheAmplitude : 0)
            .onAppear {
                guard !reduceMotion else { return }
                // One full breath: up (1.2s) then back down (1.2s), then stop.
                withAnimation(.easeInOut(duration: MotionLanguage.breatheCycle / 2).repeatCount(1, autoreverses: true)) {
                    breathing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + MotionLanguage.breatheCycle) {
                    breathing = false
                }
            }
    }
}

extension View {
    func oneBreath(reduceMotion: Bool) -> some View {
        modifier(OneBreathModifier(reduceMotion: reduceMotion))
    }

    /// Single 5% brightness pulse in sync with the breath (empty-state CTA).
    func onePulse(reduceMotion: Bool) -> some View {
        modifier(OnePulseModifier(reduceMotion: reduceMotion))
    }
}

private struct OnePulseModifier: ViewModifier {
    let reduceMotion: Bool
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .brightness(pulsing ? 0.05 : 0)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: MotionLanguage.breatheCycle / 2).repeatCount(1, autoreverses: true)) {
                    pulsing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + MotionLanguage.breatheCycle) {
                    pulsing = false
                }
            }
    }
}

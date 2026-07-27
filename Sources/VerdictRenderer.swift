import Foundation
import UIKit

/// Verdict card model (PM F7 / ACC-F7): rank #1 with badge, up to 3
/// representative evidence photos, runner-up rows, weight basis, date.
struct VerdictCardModel {
    var winnerTitle: String
    var winnerScore: Double?
    /// Runner-ups after #1 (title + score), up to 2 shown.
    var runnerUps: [(title: String, score: Double?)]
    /// Up to 3 evidence photos for the winner; empty → color-block fallback
    /// (export never blocked by missing photos).
    var evidencePhotos: [UIImage]
    var weightProfileName: String
    var date: Date
}

enum VerdictRenderError: Error {
    case pngEncodingFailed
}

/// Deterministic UIKit-drawn verdict card (verdict_card_render slot). Works
/// headless in unit tests; the same bytes go to Save to Photos / Share / the
/// sandbox copy. No photos → color blocks + score typography, never blocked.
enum VerdictRenderer {

    static let cardSize = CGSize(width: 1080, height: 1350)
    /// Retina export scale — pixel size is cardSize × outputScale (deterministic).
    static let outputScale: CGFloat = 2.0

    static func renderPNG(model: VerdictCardModel) throws -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = outputScale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: cardSize, format: format)
        let image = renderer.image { ctx in
            draw(model: model, in: CGRect(origin: .zero, size: cardSize), context: ctx.cgContext)
        }
        guard let data = image.pngData() else { throw VerdictRenderError.pngEncodingFailed }
        return data
    }

    // MARK: - Drawing

    private static let paper = UIColor(red: 0xF6 / 255, green: 0xF1 / 255, blue: 0xE7 / 255, alpha: 1)
    private static let panel = UIColor.white
    private static let ink = UIColor(red: 0x2B / 255, green: 0x26 / 255, blue: 0x20 / 255, alpha: 1)
    private static let brass = UIColor(red: 0xB4 / 255, green: 0x76 / 255, blue: 0x2A / 255, alpha: 1)
    private static let sage = UIColor(red: 0x6E / 255, green: 0x7F / 255, blue: 0x5C / 255, alpha: 1)
    private static let track = UIColor(red: 0xE4 / 255, green: 0xDC / 255, blue: 0xCB / 255, alpha: 1)

    private static func draw(model: VerdictCardModel, in rect: CGRect, context: CGContext) {
        paper.setFill()
        context.fill(rect)

        let cardRect = rect.insetBy(dx: 56, dy: 72)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 28)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 8), blur: 28, color: UIColor.black.withAlphaComponent(0.12).cgColor)
        panel.setFill()
        cardPath.fill()
        context.restoreGState()

        var cursorY = cardRect.minY + 64

        // #1 badge.
        let badgeRect = CGRect(x: cardRect.minX + 56, y: cursorY, width: 96, height: 96)
        brass.setFill()
        UIBezierPath(roundedRect: badgeRect, cornerRadius: 20).fill()
        drawText("#1", in: badgeRect, font: .systemFont(ofSize: 44, weight: .bold),
                 color: .white, alignment: .center)

        drawText("Verdict: \(model.winnerTitle)",
                 in: CGRect(x: badgeRect.maxX + 28, y: cursorY + 8, width: cardRect.width - (badgeRect.width + 56 * 3), height: 90),
                 font: .systemFont(ofSize: 44, weight: .semibold), color: ink, alignment: .left)
        cursorY += 150

        // Big score.
        let scoreText = model.winnerScore.map { String(format: "%.1f", $0) } ?? "—"
        drawText(scoreText, in: CGRect(x: cardRect.minX + 56, y: cursorY, width: 360, height: 190),
                 font: .monospacedSystemFont(ofSize: 150, weight: .semibold), color: ink, alignment: .left)
        drawText("/ 5", in: CGRect(x: cardRect.minX + 56 + 330, y: cursorY + 96, width: 130, height: 70),
                 font: .systemFont(ofSize: 52, weight: .medium), color: ink.withAlphaComponent(0.55), alignment: .left)
        cursorY += 210

        // Winner bar.
        let barRect = CGRect(x: cardRect.minX + 56, y: cursorY, width: cardRect.width - 112, height: 26)
        track.setFill()
        UIBezierPath(roundedRect: barRect, cornerRadius: 13).fill()
        if let score = model.winnerScore {
            let fillWidth = max(barRect.width * CGFloat(score / 5.0), 26)
            brass.setFill()
            UIBezierPath(roundedRect: CGRect(x: barRect.minX, y: barRect.minY, width: fillWidth, height: barRect.height), cornerRadius: 13).fill()
        }
        cursorY += 90

        // Evidence photos (polaroid tilt) or color-block fallback.
        let slotCount = max(model.evidencePhotos.count, model.evidencePhotos.isEmpty ? 3 : 0)
        if slotCount > 0 {
            let photoWidth: CGFloat = 260
            let photoHeight: CGFloat = 300
            let totalWidth = CGFloat(min(slotCount, 3)) * photoWidth + CGFloat(min(slotCount, 3) - 1) * 32
            var photoX = cardRect.midX - totalWidth / 2
            for index in 0..<min(slotCount, 3) {
                let photoRect = CGRect(x: photoX, y: cursorY, width: photoWidth, height: photoHeight)
                context.saveGState()
                let center = CGPoint(x: photoRect.midX, y: photoRect.midY)
                context.translateBy(x: center.x, y: center.y)
                context.rotate(by: CGFloat(index == 1 ? -1.2 : 1.2) * .pi / 180)
                let rotated = CGRect(x: -photoRect.width / 2, y: -photoRect.height / 2, width: photoRect.width, height: photoRect.height)
                if index < model.evidencePhotos.count {
                    let image = model.evidencePhotos[index]
                    // Aspect-fill into the slot.
                    let scale = max(rotated.width / image.size.width, rotated.height / image.size.height)
                    let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                    let drawRect = CGRect(x: -drawSize.width / 2, y: -drawSize.height / 2, width: drawSize.width, height: drawSize.height)
                    context.saveGState()
                    UIBezierPath(roundedRect: rotated, cornerRadius: 18).addClip()
                    image.draw(in: drawRect)
                    context.restoreGState()
                } else {
                    // Color-block fallback with score typography.
                    track.setFill()
                    UIBezierPath(roundedRect: rotated, cornerRadius: 18).fill()
                    drawText(scoreText, in: rotated.insetBy(dx: 0, dy: rotated.height / 2 - 44),
                             font: .monospacedSystemFont(ofSize: 64, weight: .semibold),
                             color: ink.withAlphaComponent(0.5), alignment: .center)
                }
                UIColor.black.withAlphaComponent(0.06).setStroke()
                let stroke = UIBezierPath(roundedRect: rotated, cornerRadius: 18)
                stroke.lineWidth = 2
                stroke.stroke()
                context.restoreGState()
                photoX += photoWidth + 32
            }
            cursorY += 300 + 64
        }

        // Runner-up rows.
        for runnerUp in model.runnerUps.prefix(2) {
            let rowRect = CGRect(x: cardRect.minX + 56, y: cursorY, width: cardRect.width - 112, height: 56)
            drawText(runnerUp.title, in: CGRect(x: rowRect.minX, y: rowRect.minY, width: 300, height: rowRect.height),
                     font: .systemFont(ofSize: 36, weight: .medium), color: ink, alignment: .left)
            let railRect = CGRect(x: rowRect.minX + 320, y: rowRect.midY - 12, width: rowRect.width - 320 - 150, height: 24)
            track.setFill()
            UIBezierPath(roundedRect: railRect, cornerRadius: 12).fill()
            if let score = runnerUp.score {
                let fill = max(railRect.width * CGFloat(score / 5.0), 24)
                sage.setFill()
                UIBezierPath(roundedRect: CGRect(x: railRect.minX, y: railRect.minY, width: fill, height: railRect.height), cornerRadius: 12).fill()
                drawText(String(format: "%.1f", score), in: CGRect(x: railRect.maxX + 20, y: rowRect.minY, width: 130, height: rowRect.height),
                         font: .monospacedSystemFont(ofSize: 40, weight: .medium), color: ink, alignment: .right)
            } else {
                drawText("—", in: CGRect(x: railRect.maxX + 20, y: rowRect.minY, width: 130, height: rowRect.height),
                         font: .monospacedSystemFont(ofSize: 40, weight: .medium), color: ink.withAlphaComponent(0.5), alignment: .right)
            }
            cursorY += 78
        }

        // Weight basis + date footer.
        let dateText = DateFormatter.verdictDate.string(from: model.date)
        drawText("Weights: \(model.weightProfileName) · \(dateText)",
                 in: CGRect(x: cardRect.minX + 56, y: cardRect.maxY - 110, width: cardRect.width - 112, height: 50),
                 font: .systemFont(ofSize: 30, weight: .regular), color: ink.withAlphaComponent(0.6), alignment: .left)
        drawText("TourWise — your evidence board",
                 in: CGRect(x: cardRect.minX + 56, y: cardRect.maxY - 62, width: cardRect.width - 112, height: 40),
                 font: .systemFont(ofSize: 24, weight: .regular), color: ink.withAlphaComponent(0.4), alignment: .left)
    }

    private static func drawText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
        ]
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }
}

private extension DateFormatter {
    static let verdictDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

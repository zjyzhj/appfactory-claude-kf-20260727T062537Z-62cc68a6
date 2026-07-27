import SwiftUI

// MARK: - verdict_card (sheet)

/// verdict_card route: rendered card preview (verdict_card_render slot), Save
/// to Photos / Share — each successful export spends 1 Export Credit. Balance
/// 0 → CTA becomes "Get Credits" → paywall; preview is NEVER blocked (ACC-F7).
/// Write-permission denied → inline notice; Share stays available.
/// mot_success_verdict: card deals in from the top edge; #1 badge pops 0.15s
/// later; success haptic on export (ACC-MOT-SUCCESS).
struct VerdictCardView: View {
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var credits: CreditStore
    @EnvironmentObject private var permissions: PermissionCenter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let viewingIds: [UUID]

    @State private var renderedImage: UIImage? = nil
    @State private var cardDealt = false
    @State private var badgePopped = false
    @State private var toast: String? = nil
    @State private var saveDeniedNotice = false
    @State private var showingPaywall = false
    @State private var showingShare = false
    @State private var shareItems: [Any] = []

    private var viewings: [Viewing] { viewingIds.compactMap { store.viewing(id: $0) } }
    private var profile: WeightProfile { store.activeWeightProfile ?? WeightProfile.balancedSeed(criteria: store.criteria) }

    private var ranked: [ScoringEngine.RankedViewing] {
        ScoringEngine.rank(viewings: viewings,
                           roomNotesByViewing: Dictionary(uniqueKeysWithValues: viewings.map { ($0.id, store.roomNotes(forViewing: $0.id)) }),
                           profile: profile,
                           enabledCriteria: store.criteria)
    }

    private var model: VerdictCardModel {
        let winner = ranked.first
        let winnerNotes = winner.map { store.roomNotes(forViewing: $0.viewing.id) } ?? []
        // Up to 3 representative evidence photos from the winner's rooms.
        let photos = winnerNotes
            .sorted { lhs, _ in lhs.roomType == .kitchen } // kitchen evidence first, stable enough
            .flatMap(\.photoRelativePaths)
            .prefix(3)
            .compactMap { store.loadPhoto(relativePath: $0) }
        return VerdictCardModel(
            winnerTitle: winner?.viewing.title ?? "—",
            winnerScore: winner?.score ?? nil,
            runnerUps: ranked.dropFirst().prefix(2).map { ($0.viewing.title, $0.score) },
            evidencePhotos: Array(photos),
            weightProfileName: profile.name,
            date: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    cardPreview
                        .offset(y: cardDealt ? 0 : -60)
                        .opacity(cardDealt ? 1 : 0)
                        .rotationEffect(.degrees(cardDealt ? 0 : -2))

                    if saveDeniedNotice {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .foregroundStyle(Theme.accentBrass)
                            Text("Saving to Photos is off. You can still Share the card.")
                                .font(Theme.caption())
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        .padding(10)
                        .background(Theme.accentBrass.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    creditLine
                    actionButtons
                }
                .padding(16)
            }
            .paperBackground()
            .navigationTitle("Verdict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .overlay(alignment: .bottom) { ToastView(text: $toast) }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingShare) {
                ActivityView(items: shareItems) { completed in
                    handleShareCompletion(completed: completed)
                }
            }
            .onAppear {
                // mot_success_verdict: deal from top edge (dur_deal), badge pops
                // 0.15s later. Reduce Motion → static card, badge fades in.
                withAnimation(MotionLanguage.animation(MotionLanguage.durDeal, reduceMotion: reduceMotion)) {
                    cardDealt = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(MotionLanguage.animation(MotionLanguage.durSettle, reduceMotion: reduceMotion)) {
                        badgePopped = true
                    }
                }
                renderPreview()
            }
        }
    }

    // MARK: Preview (verdict_card_render slot — color-block fallback inside renderer)

    private var cardPreview: some View {
        ZStack(alignment: .topLeading) {
            if let renderedImage {
                Image(uiImage: renderedImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.bgPanel)
                    .aspectRatio(VerdictRenderer.cardSize.width / VerdictRenderer.cardSize.height, contentMode: .fit)
                    .overlay { ProgressView().tint(Theme.accentBrass) }
            }
            // #1 rank badge pops in 0.15s after the card lands.
            Text("#1")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Theme.accentBrass)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(14)
                .scaleEffect(badgePopped ? 1 : 0.4)
                .opacity(badgePopped ? 1 : 0)
                .accessibilityLabel("Rank 1 badge")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Verdict card preview")
    }

    private var creditLine: some View {
        HStack(spacing: 8) {
            Image(systemName: "shippingbox.fill")
                .foregroundStyle(Theme.accentBrass)
            Text("Balance: \(store.ledger.balance) credits · each export uses 1")
                .font(Theme.caption())
                .foregroundStyle(Theme.inkSecondary)
            Spacer()
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if store.ledger.balance >= 1 {
                HStack(spacing: 12) {
                    Button { saveToPhotos() } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.accentBrass)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.bgPanel)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.accentBrass, lineWidth: 1.5))
                    }
                    .accessibilityLabel("Save verdict card to Photos")
                    Button { shareCard() } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.accentBrass)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .accessibilityLabel("Share verdict card")
                }
            } else {
                // credits_empty: CTA becomes Get Credits → paywall; preview above stays.
                Button { showingPaywall = true } label: {
                    Label("Get Credits", systemImage: "shippingbox")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accentBrass)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .accessibilityLabel("Get Credits")
                Text("You need 1 credit to export this card.")
                    .font(Theme.caption())
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }

    // MARK: Export flows (spend only on success; render+spend one transaction)

    private func renderPreview() {
        if let data = try? VerdictRenderer.renderPNG(model: model) {
            renderedImage = UIImage(data: data)
        }
    }

    private func saveToPhotos() {
        let snapshotModel = model
        let ids = viewingIds
        let profileId = profile.id
        Task {
            let outcome = await credits.performExport(
                viewingIds: ids,
                weightProfileId: profileId,
                render: { try VerdictRenderer.renderPNG(model: snapshotModel) },
                save: { data in try await permissions.saveVerdictImageToPhotos(pngData: data) })
            await MainActor.run {
                switch outcome {
                case .exported:
                    saveDeniedNotice = false
                    TourWiseHaptics.verdictSuccess() // haptic_verdict on export success
                    toast = "Verdict card saved to Photos."
                case .insufficientCredits:
                    break // CTA flips to Get Credits reactively
                case .renderFailed:
                    toast = "Couldn't render the card. Your credits were not changed."
                case .saveFailed:
                    // photos_write_denied — Share stays available.
                    permissions.refreshPhotosAdd()
                    saveDeniedNotice = true
                }
            }
        }
    }

    private func shareCard() {
        let snapshotModel = model
        guard let data = try? VerdictRenderer.renderPNG(model: snapshotModel),
              let image = UIImage(data: data) else {
            toast = "Couldn't render the card. Your credits were not changed."
            return
        }
        shareItems = [image]
        showingShare = true
    }

    /// Called by ActivityView completion — Share is also an export (1 credit),
    /// spent only when the share completes successfully.
    private func handleShareCompletion(completed: Bool) {
        guard completed else { return }
        let snapshotModel = model
        let ids = viewingIds
        let profileId = profile.id
        Task {
            let outcome = await credits.performExport(
                viewingIds: ids,
                weightProfileId: profileId,
                render: { try VerdictRenderer.renderPNG(model: snapshotModel) },
                save: { _ in }) // share delivery already happened; no photo-library write
            await MainActor.run {
                if case .exported = outcome {
                    TourWiseHaptics.verdictSuccess()
                    toast = "Verdict card shared."
                }
            }
        }
    }
}

/// System share sheet (UIActivityViewController) — independent of Photos write
/// permission, so the denied path keeps a working export route.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    var onCompletion: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onCompletion(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

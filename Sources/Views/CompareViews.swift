import SwiftUI

// MARK: - tab_compare

/// tab_compare route: shortlist picker (2–5) + weighted ranking list (bars +
/// scores). Selection persists in LocalStore across tab switches and restarts
/// (ACC-NAV). mot_rank_regrow: bars regrow + rows re-seat when the active
/// WeightProfile changes (ACC-MOT-COMMIT).
struct CompareHomeView: View {
    @EnvironmentObject private var store: LocalStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var profile: WeightProfile? { store.activeWeightProfile }
    private var candidates: [Viewing] {
        // Shortlist pool: shortlisted first, then toured (routes: pick from shortlist).
        store.viewings.filter { $0.status == .shortlisted || $0.status == .toured }
    }
    private var selectedViewings: [Viewing] {
        store.compareSelection.compactMap { id in store.viewing(id: id) }
    }
    private var validation: ScoringEngine.ShortlistValidation {
        ScoringEngine.validateShortlist(count: store.compareSelection.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Pick 2–5 viewings to compare. Your active weights shape the ranking.")
                        .font(Theme.body())
                        .foregroundStyle(Theme.inkSecondary)

                    if candidates.isEmpty {
                        emptyPoolCard
                    } else {
                        pickerSection
                    }

                    if case .tooFew = validation, !store.compareSelection.isEmpty {
                        hintCard(text: "Shortlist at least 2 viewings to compare.", systemImage: "list.bullet.clipboard")
                    }
                    if case .tooMany = validation {
                        hintCard(text: "Compare up to 5 at a time — remove one first.", systemImage: "hand.raised")
                    }

                    if validation == .valid, let profile {
                        rankingSection(profile: profile)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .paperBackground()
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emptyPoolCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Nothing to compare yet", systemImage: "chart.bar.xaxis")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)
            Text("Finish a walkthrough, then shortlist a viewing from the Viewings tab — it lands here.")
                .font(Theme.body())
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(14)
        .panelCard()
    }

    private var pickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shortlist")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)
            ForEach(candidates) { viewing in
                let selected = store.compareSelection.contains(viewing.id)
                Button {
                    store.toggleCompareSelection(viewingId: viewing.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(selected ? Theme.accentSage : Theme.inkTertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewing.title)
                                .font(Theme.body().weight(.medium))
                                .foregroundStyle(Theme.inkPrimary)
                            Text(viewing.status.displayName)
                                .font(Theme.caption())
                                .foregroundStyle(Theme.statusColor(viewing.status))
                        }
                        Spacer()
                        if let score = ScoringEngine.flatMean(roomNotes: store.roomNotes(forViewing: viewing.id)) {
                            Text(String(format: "%.1f", score))
                                .font(Theme.scoreNumber())
                                .foregroundStyle(Theme.inkSecondary)
                        }
                    }
                    .padding(12)
                    .background(Theme.bgPanel)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(selected ? Theme.accentSage : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(viewing.title), \(selected ? "selected" : "not selected")")
            }
        }
    }

    private func hintCard(text: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(Theme.accentBrass)
            Text(text)
                .font(Theme.body())
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accentBrass.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func rankingSection(profile: WeightProfile) -> some View {
        let ranked = ScoringEngine.rank(viewings: selectedViewings,
                                        roomNotesByViewing: Dictionary(uniqueKeysWithValues: selectedViewings.map { ($0.id, store.roomNotes(forViewing: $0.id)) }),
                                        profile: profile,
                                        enabledCriteria: store.criteria)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Weighted ranking")
                    .font(Theme.sectionTitle())
                    .foregroundStyle(Theme.inkPrimary)
                Spacer()
                Text("Weights: \(profile.name)")
                    .font(Theme.caption())
                    .foregroundStyle(Theme.inkTertiary)
            }
            ForEach(Array(ranked.enumerated()), id: \.element.viewing.id) { index, entry in
                HStack(spacing: 12) {
                    RankBadge(rank: index + 1)
                    Text(entry.viewing.title)
                        .font(Theme.body().weight(.medium))
                        .foregroundStyle(Theme.inkPrimary)
                        .lineLimit(1)
                    Spacer()
                    // mot_rank_regrow: bar regrows to the new value on weight switch.
                    ScoreBar(score: entry.score, maxScore: 5)
                        .animation(MotionLanguage.animation(MotionLanguage.durGrow, reduceMotion: reduceMotion),
                                   value: entry.score)
                    Text(entry.score.map { String(format: "%.2f", $0) } ?? "—")
                        .font(Theme.scoreNumber())
                        .foregroundStyle(Theme.inkPrimary)
                }
                .padding(12)
                .panelCard()
            }
            .animation(MotionLanguage.animation(MotionLanguage.durGrow, reduceMotion: reduceMotion),
                       value: ranked.map(\.viewing.id))

            NavigationLink {
                CompareBoardView(viewingIds: store.compareSelection)
            } label: {
                Label("Compare side by side", systemImage: "rectangle.split.3x1")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.accentBrass)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .accessibilityLabel("Compare side by side")
        }
    }
}

/// Text rank badge — ranking is never carried by color alone (a11y).
struct RankBadge: View {
    let rank: Int
    var body: some View {
        Text("#\(rank)")
            .font(.system(size: 14, weight: .bold).monospacedDigit())
            .foregroundStyle(rank == 1 ? .white : Theme.inkSecondary)
            .frame(width: 40, height: 28)
            .background(rank == 1 ? Theme.accentBrass : Theme.scoreTrack.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel("Rank \(rank)")
    }
}

// MARK: - compare_board

/// compare_board route: side-by-side table (rows = enabled criteria, columns =
/// viewings), evidence thumbnails, weight-source note. Fixed criteria column;
/// viewing columns ≥140pt wide, horizontally scrollable (a11y ≥132pt).
struct CompareBoardView: View {
    @EnvironmentObject private var store: LocalStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let viewingIds: [UUID]
    @State private var verdictTarget: VerdictTarget? = nil

    private var viewings: [Viewing] { viewingIds.compactMap { store.viewing(id: $0) } }
    private var profile: WeightProfile? { store.activeWeightProfile }
    private let columnWidth: CGFloat = 150
    private let criteriaColumnWidth: CGFloat = 116

    private var ranked: [ScoringEngine.RankedViewing] {
        guard let profile else { return [] }
        return ScoringEngine.rank(viewings: viewings,
                                  roomNotesByViewing: Dictionary(uniqueKeysWithValues: viewings.map { ($0.id, store.roomNotes(forViewing: $0.id)) }),
                                  profile: profile,
                                  enabledCriteria: store.criteria)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                rankChips
                boardTable
                weightSourceNote
                makeVerdictButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .paperBackground()
        .navigationTitle("Side by side")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $verdictTarget) { target in
            VerdictCardView(viewingIds: target.ids)
        }
    }

    private var rankChips: some View {
        HStack(spacing: 10) {
            ForEach(Array(ranked.enumerated()), id: \.element.viewing.id) { index, entry in
                VStack(spacing: 4) {
                    RankBadge(rank: index + 1)
                    Text(entry.viewing.title)
                        .font(Theme.caption().weight(.semibold))
                        .foregroundStyle(Theme.inkPrimary)
                        .lineLimit(1)
                    Text(entry.score.map { String(format: "%.1f", $0) } ?? "—")
                        .font(Theme.scoreNumber())
                        .foregroundStyle(Theme.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(index == 0 ? Theme.accentBrass.opacity(0.1) : Theme.bgPanel)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(index == 0 ? Theme.accentBrass : Color.clear, lineWidth: 1.5)
                )
            }
        }
        .animation(MotionLanguage.animation(MotionLanguage.durGrow, reduceMotion: reduceMotion),
                   value: ranked.map(\.viewing.id))
    }

    private var boardTable: some View {
        let orderedRanked = ranked // ranked order = column order
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Fixed criteria column.
                VStack(spacing: 0) {
                    headerCell(text: "Criteria", width: criteriaColumnWidth, isHeader: true)
                    ForEach(store.enabledCriteria) { criterion in
                        HStack(spacing: 6) {
                            Image(systemName: criterion.sfSymbol)
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.accentBrass)
                            Text(criterion.name)
                                .font(Theme.caption().weight(.medium))
                                .foregroundStyle(Theme.inkPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 8)
                        .frame(width: criteriaColumnWidth, height: 64, alignment: .leading)
                        .background(Theme.bgPanel)
                        .overlay(alignment: .bottom) { rowDivider }
                    }
                }
                .overlay(alignment: .trailing) {
                    Rectangle().fill(Theme.scoreTrack).frame(width: 1)
                }
                // Horizontally scrolling viewing columns.
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            ForEach(orderedRanked, id: \.viewing.id) { entry in
                                columnHeader(entry: entry)
                            }
                        }
                        ForEach(store.enabledCriteria) { criterion in
                            HStack(spacing: 0) {
                                ForEach(orderedRanked, id: \.viewing.id) { entry in
                                    scoreCell(entry: entry, criterion: criterion)
                                }
                            }
                        }
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
    }

    private var rowDivider: some View {
        Rectangle().fill(Theme.scoreTrack.opacity(0.6)).frame(height: 1)
    }

    private func headerCell(text: String, width: CGFloat, isHeader: Bool) -> some View {
        Text(text)
            .font(Theme.caption().weight(.semibold))
            .foregroundStyle(Theme.inkSecondary)
            .frame(width: width, height: 128, alignment: .leading)
            .padding(.horizontal, 8)
            .background(Theme.bgPanel)
            .overlay(alignment: .bottom) { rowDivider }
    }

    private func columnHeader(entry: ScoringEngine.RankedViewing) -> some View {
        let notes = store.roomNotes(forViewing: entry.viewing.id)
        let thumb = notes.lazy.compactMap { $0.photoRelativePaths.first }.first.flatMap { store.loadPhoto(relativePath: $0) }
        return VStack(spacing: 4) {
            PolaroidPhoto(image: thumb, aspectRatio: 16.0 / 9.0, tiltDegrees: 0,
                          accessibilityLabelText: "\(entry.viewing.title) evidence thumbnail")
                .frame(height: 56)
            Text(entry.viewing.title)
                .font(Theme.caption().weight(.semibold))
                .foregroundStyle(Theme.inkPrimary)
                .lineLimit(1)
            Text(entry.score.map { String(format: "%.2f", $0) } ?? "—")
                .font(Theme.caption().monospacedDigit())
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.horizontal, 8)
        .frame(width: columnWidth, height: 128)
        .background(Theme.bgPanel)
        .overlay(alignment: .bottom) { rowDivider }
    }

    private func scoreCell(entry: ScoringEngine.RankedViewing, criterion: Criterion) -> some View {
        let mean = entry.criterionMeans[criterion.id]
        return VStack(spacing: 4) {
            Text(mean.map { String(format: "%.1f", $0) } ?? "—")
                .font(Theme.scoreNumber())
                .foregroundStyle(mean == nil ? Theme.inkTertiary : Theme.inkPrimary)
            if let mean {
                ScoreBar(score: mean, maxScore: 5)
                    .frame(width: 60)
                    .animation(MotionLanguage.animation(MotionLanguage.durGrow, reduceMotion: reduceMotion),
                               value: mean)
            }
        }
        .frame(width: columnWidth, height: 64)
        .background(Theme.bgPanel)
        .overlay(alignment: .bottom) { rowDivider }
        .accessibilityLabel("\(criterion.name) for \(entry.viewing.title): \(mean.map { String(format: "%.1f of 5", $0) } ?? "not scored")")
    }

    private var weightSourceNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "scalemass.fill")
                .foregroundStyle(Theme.accentBrass)
            Text("Scores are on a 1–5 scale. Weights from \"\(profile?.name ?? "Balanced")\" shape the overall ranking.")
                .font(Theme.caption())
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accentBrass.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var makeVerdictButton: some View {
        Button {
            verdictTarget = VerdictTarget(ids: viewingIds)
        } label: {
            Label("Make Verdict", systemImage: "checkmark.seal.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accentBrass)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .accessibilityLabel("Make Verdict")
    }
}

struct VerdictTarget: Identifiable {
    var id: String { ids.map { $0.uuidString }.joined(separator: "-") }
    let ids: [UUID]
}

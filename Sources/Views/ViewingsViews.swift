import SwiftUI

// MARK: - tab_viewings (Viewings list)

/// tab_viewings route: hero slot (home_hero), status-grouped list with search,
/// empty-state illustration slot, Add flow. Filter text is @State on the tab's
/// persistent view — TabView keeps it alive across tab switches (ACC-NAV).
struct ViewingsListView: View {
    @EnvironmentObject private var store: LocalStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var filterText: String = ""
    @State private var showingNewViewing = false
    @State private var walkthroughTarget: WalkthroughTarget? = nil
    @State private var toast: String? = nil
    @State private var heroSettled = false
    @State private var cardsAppeared = false

    private var filteredViewings: [Viewing] {
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.viewings }
        return store.viewings.filter {
            $0.title.localizedCaseInsensitiveContains(query) || $0.address.localizedCaseInsensitiveContains(query)
        }
    }

    private func group(_ status: ViewingStatus) -> [Viewing] {
        filteredViewings.filter { $0.status == status }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HomeHeroSlot()
                        .offset(y: heroSettled ? 0 : 10)
                        .opacity(heroSettled ? 1 : 0)

                    if store.viewings.isEmpty {
                        ViewingsEmptySlot(onAdd: { showingNewViewing = true })
                            .padding(.top, 12)
                    } else {
                        searchField
                        ForEach([ViewingStatus.shortlisted, .toured, .draft, .rejected], id: \.self) { status in
                            let viewings = group(status)
                            if !viewings.isEmpty {
                                sectionHeader(status: status, count: viewings.count)
                                ForEach(Array(viewings.enumerated()), id: \.element.id) { index, viewing in
                                    NavigationLink(value: viewing.id) {
                                        ViewingRowCard(viewing: viewing)
                                    }
                                    .buttonStyle(.plain)
                                    .offset(y: cardsAppeared ? 0 : 24)
                                    .opacity(cardsAppeared ? 1 : 0)
                                    .animation(
                                        MotionLanguage.animation(
                                            MotionLanguage.durSettle.delay(Double(index) * MotionLanguage.staggerRoom),
                                            reduceMotion: reduceMotion),
                                        value: cardsAppeared)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .paperBackground()
            .navigationTitle("Viewings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNewViewing = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.accentBrass)
                    }
                    .accessibilityLabel("Add viewing")
                }
            }
            .navigationDestination(for: UUID.self) { viewingId in
                ViewingDetailView(viewingId: viewingId, toast: $toast)
            }
            .sheet(isPresented: $showingNewViewing) {
                ViewingEditSheet(mode: .create) { created in
                    toast = "Viewing saved."
                    // PM routes: after creating from tab_viewings, auto-enter
                    // walkthrough. Delay so the edit sheet fully dismisses
                    // before the cover presents (no presentation conflict).
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        walkthroughTarget = WalkthroughTarget(id: created.id)
                    }
                }
            }
            .fullScreenCover(item: $walkthroughTarget) { target in
                WalkthroughCoverView(viewingId: target.id)
            }
            .overlay(alignment: .bottom) { ToastView(text: $toast) }
            .onAppear {
                // mot_entry_settle (ACC-MOT-ENTRY): hero settles, cards stagger
                // in once per cold start. Reduce Motion → static end state.
                guard !heroSettled else { return }
                withAnimation(MotionLanguage.animation(MotionLanguage.durSettle, reduceMotion: reduceMotion)) {
                    heroSettled = true
                }
                withAnimation(MotionLanguage.animation(MotionLanguage.durSettle, reduceMotion: reduceMotion)) {
                    cardsAppeared = true
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.inkTertiary)
            TextField("Search address or title", text: $filterText)
                .font(Theme.body())
                .foregroundStyle(Theme.inkPrimary)
                .submitLabel(.done)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.bgPanel)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("Search viewings")
    }

    private func sectionHeader(status: ViewingStatus, count: Int) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Theme.statusColor(status))
                .frame(width: 8, height: 8)
            Text(status.displayName)
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)
            Text("\(count)")
                .font(Theme.caption())
                .foregroundStyle(Theme.inkTertiary)
            Spacer()
        }
        .padding(.top, 4)
    }
}

/// Identifiable wrapper for presenting the walkthrough cover.
struct WalkthroughTarget: Identifiable { let id: UUID }

// MARK: - home_hero slot (ACC-VIS-HERO / B7)

/// Hero slot: asset `hero_home` + gradient mask + title overlay, ~30% screen
/// height. Fallback branch: #E9DFC9 gradient + SF Symbol house.fill.
struct HomeHeroSlot: View {
    var body: some View {
        GeometryReader { proxy in
            let height = max(proxy.size.height, 220)
            ZStack(alignment: .bottomLeading) {
                if let hero = UIImage(named: "hero_home") {
                    Image(uiImage: hero)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: height)
                        .clipped()
                } else {
                    LinearGradient(colors: [Theme.heroFallbackStart, Theme.heroFallbackEnd],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "house.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Theme.accentBrass.opacity(0.4))
                }
                LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.45)],
                               startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TourWise")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Your evidence board")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(18)
            }
            .frame(width: proxy.size.width, height: height)
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("TourWise hero — your evidence board")
    }
}

// MARK: - viewings_empty_illustration slot (ACC-VIS-EMPTY / B8)

/// Empty-state slot: asset `empty_viewings` centered with "No viewings yet" +
/// Add CTA. mot_empty_breathe: one 2.4s ±4pt breath then rest (never loops);
/// CTA one 5% brightness pulse. Fallback: SF Symbol photo.stack 56pt brass 40%.
struct ViewingsEmptySlot: View {
    var onAdd: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 18) {
            Group {
                if let illustration = UIImage(named: "empty_viewings") {
                    Image(uiImage: illustration)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 260)
                } else {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.accentBrass.opacity(0.4))
                }
            }
            .oneBreath(reduceMotion: reduceMotion)
            .accessibilityLabel("Empty viewings illustration")

            Text("No viewings yet")
                .font(Theme.pageTitle())
                .foregroundStyle(Theme.inkPrimary)
            Text("Walk a place, capture evidence, compare calmly.")
                .font(Theme.body())
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)

            Button(action: onAdd) {
                Label("Add your first viewing", systemImage: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Theme.accentBrass)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .onePulse(reduceMotion: reduceMotion)
            .accessibilityLabel("Add your first viewing")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

// MARK: - List row card

struct ViewingRowCard: View {
    @EnvironmentObject private var store: LocalStore
    let viewing: Viewing

    private var notes: [RoomNote] { store.roomNotes(forViewing: viewing.id) }
    private var photoCount: Int { notes.reduce(0) { $0 + $1.photoRelativePaths.count } }
    private var scoredRooms: Int { notes.filter { $0.state == .scored }.count }
    private var coverPhoto: UIImage? {
        for note in notes {
            if let first = note.photoRelativePaths.first, let image = store.loadPhoto(relativePath: first) {
                return image
            }
        }
        return nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            PolaroidPhoto(image: coverPhoto, aspectRatio: 1.0,
                          accessibilityLabelText: "\(viewing.title) cover evidence photo")
                .frame(width: 92)
            VStack(alignment: .leading, spacing: 6) {
                Text(viewing.title)
                    .font(Theme.sectionTitle())
                    .foregroundStyle(Theme.inkPrimary)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    if let rent = viewing.rentDisplay {
                        Text(rent)
                    }
                    Label("\(scoredRooms) rooms", systemImage: "door.left.hand.open")
                    Label("\(photoCount) photos", systemImage: "camera.fill")
                }
                .font(Theme.caption())
                .foregroundStyle(Theme.inkSecondary)
                HStack(spacing: 10) {
                    Text("Overall score")
                        .font(Theme.caption())
                        .foregroundStyle(Theme.inkTertiary)
                    ScoreBar(score: ScoringEngine.flatMean(roomNotes: notes), maxScore: 5)
                    Text(ScoringEngine.flatMean(roomNotes: notes).map { String(format: "%.1f", $0) } ?? "—")
                        .font(Theme.scoreNumber())
                        .foregroundStyle(Theme.inkPrimary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .panelCard()
        .accessibilityElement(children: .combine)
    }
}

/// Segmented score bar (score_track rail, sage fill).
struct ScoreBar: View {
    let score: Double?
    var maxScore: Double = 5
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Theme.scoreTrack)
                if let score {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Theme.accentSage)
                        .frame(width: max(proxy.size.width * CGFloat(score / maxScore), 8))
                }
            }
        }
        .frame(width: 72, height: 10)
        .accessibilityHidden(true)
    }
}

// MARK: - Shared toast

struct ToastView: View {
    @Binding var text: String?
    var body: some View {
        if let message = text {
            Text(message)
                .font(Theme.body())
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Theme.inkPrimary.opacity(0.92))
                .clipShape(Capsule())
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                        withAnimation { text = nil }
                    }
                }
        }
    }
}

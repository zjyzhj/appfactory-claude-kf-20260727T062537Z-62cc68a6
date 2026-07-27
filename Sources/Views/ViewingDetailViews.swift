import SwiftUI

// MARK: - viewing_detail

/// viewing_detail route: basics, room-by-room assessment, evidence photo strip
/// (detail_photo_strip slot), overall score, status switching, walkthrough
/// entry, delete with cascade confirmation.
struct ViewingDetailView: View {
    @EnvironmentObject private var store: LocalStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let viewingId: UUID
    @Binding var toast: String?

    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false
    @State private var walkthroughTarget: WalkthroughTarget? = nil
    @State private var fullscreenPhoto: FullscreenPhotoTarget? = nil

    private var viewing: Viewing? { store.viewing(id: viewingId) }
    private var notes: [RoomNote] { store.roomNotes(forViewing: viewingId) }
    private var allPhotos: [(path: String, roomName: String, index: Int, count: Int)] {
        var result: [(String, String, Int, Int)] = []
        for note in RoomType.walkthroughQueue.compactMap({ type in notes.first(where: { $0.roomType == type }) }) {
            for (index, path) in note.photoRelativePaths.enumerated() {
                result.append((path, note.roomType.displayName, index + 1, note.photoRelativePaths.count))
            }
        }
        return result
    }

    var body: some View {
        Group {
            if let viewing {
                content(viewing: viewing)
            } else {
                Text("This viewing was removed.")
                    .font(Theme.body())
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        .paperBackground()
        .navigationTitle(viewing?.title ?? "Viewing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingEdit = true } label: { Label("Edit details", systemImage: "pencil") }
                    Divider()
                    Button(role: .destructive) { showingDeleteConfirm = true } label: {
                        Label("Delete viewing", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Theme.accentBrass)
                }
                .accessibilityLabel("Viewing actions")
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let viewing {
                ViewingEditSheet(mode: .edit(viewing)) { _ in
                    toast = "Viewing saved."
                }
            }
        }
        .fullScreenCover(item: $walkthroughTarget) { target in
            WalkthroughCoverView(viewingId: target.id)
        }
        .fullScreenCover(item: $fullscreenPhoto) { target in
            FullscreenPhotoView(relativePath: target.id, label: target.label)
        }
        .confirmationDialog("Delete this viewing? Its scores and photos will be removed from this iPhone.",
                            isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Viewing", role: .destructive) {
                store.deleteViewing(id: viewingId)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func content(viewing: Viewing) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard(viewing: viewing)
                photoStrip
                walkthroughCard(viewing: viewing)
                roomsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func headerCard(viewing: Viewing) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewing.address)
                        .font(Theme.body())
                        .foregroundStyle(Theme.inkSecondary)
                    HStack(spacing: 10) {
                        if let rent = viewing.rentDisplay { Text(rent) }
                        if let beds = viewing.beds { Text("\(beds) bd") }
                        if let baths = viewing.baths { Text(baths.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(baths)) ba" : String(format: "%.1f ba", baths)) }
                    }
                    .font(Theme.caption())
                    .foregroundStyle(Theme.inkTertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ScoringEngine.flatMean(roomNotes: notes).map { String(format: "%.1f", $0) } ?? "—")
                        .font(.system(size: 34, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.inkPrimary)
                    Text("overall")
                        .font(Theme.caption())
                        .foregroundStyle(Theme.inkTertiary)
                }
            }

            HStack(spacing: 8) {
                Text("Status")
                    .font(Theme.caption())
                    .foregroundStyle(Theme.inkTertiary)
                ForEach([ViewingStatus.toured, .shortlisted, .rejected], id: \.self) { status in
                    Button {
                        store.setViewingStatus(viewingId, status: status)
                    } label: {
                        Text(status.displayName)
                            .font(Theme.caption().weight(.semibold))
                            .foregroundStyle(viewing.status == status ? .white : Theme.statusColor(status))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(viewing.status == status ? Theme.statusColor(status) : Theme.statusColor(status).opacity(0.14))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Mark as \(status.displayName)")
                }
            }
            if !viewing.generalNotes.isEmpty {
                Text(viewing.generalNotes)
                    .font(Theme.caption())
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        .padding(14)
        .panelCard()
    }

    /// detail_photo_strip slot (ACC-VIS-MEDIA / B9): horizontal evidence strip,
    /// tap → fullscreen. Empty → declared text line.
    private var photoStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Evidence photos")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)
            if allPhotos.isEmpty {
                Text("No photos yet — add during a walkthrough")
                    .font(Theme.body())
                    .foregroundStyle(Theme.inkTertiary)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(allPhotos.enumerated()), id: \.offset) { _, photo in
                            Button {
                                fullscreenPhoto = FullscreenPhotoTarget(path: photo.path,
                                                                        label: "\(photo.roomName) evidence photo \(photo.index) of \(photo.count)")
                            } label: {
                                PolaroidPhoto(image: store.loadPhoto(relativePath: photo.path), aspectRatio: 1.0,
                                              accessibilityLabelText: "\(photo.roomName) evidence photo \(photo.index) of \(photo.count)")
                                    .frame(width: 120)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func walkthroughCard(viewing: Viewing) -> some View {
        let inProgress = store.walkthroughProgress[viewingId] != nil
        let counts = store.walkthroughCounts(forViewing: viewingId)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Walkthrough")
                    .font(Theme.sectionTitle())
                    .foregroundStyle(Theme.inkPrimary)
                Spacer()
                Text("\(counts.scored) scored · \(counts.skipped) skipped")
                    .font(Theme.caption())
                    .foregroundStyle(Theme.inkTertiary)
            }
            Button {
                walkthroughTarget = WalkthroughTarget(id: viewingId)
            } label: {
                Label(inProgress ? "Resume Walkthrough" : (counts.scored > 0 ? "Redo Walkthrough" : "Start Walkthrough"),
                      systemImage: "figure.walk")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.accentBrass)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .accessibilityLabel(inProgress ? "Resume Walkthrough" : "Start Walkthrough")
        }
        .padding(14)
        .panelCard()
    }

    private var roomsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rooms")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)
            ForEach(RoomType.walkthroughQueue, id: \.self) { roomType in
                if let note = notes.first(where: { $0.roomType == roomType }) {
                    RoomNoteCard(note: note)
                }
            }
        }
    }
}

struct FullscreenPhotoTarget: Identifiable {
    var id: String { path }
    let path: String
    let label: String
}

/// Tap-to-zoom fullscreen evidence viewer (system dark, dismiss on tap).
struct FullscreenPhotoView: View {
    @EnvironmentObject private var store: LocalStore
    @Environment(\.dismiss) private var dismiss
    let relativePath: String
    let label: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let image = store.loadPhoto(relativePath: relativePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(label)
            }
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding()
                    }
                    .accessibilityLabel("Close photo")
                }
                Spacer()
            }
        }
    }
}

// MARK: - RoomNote card

struct RoomNoteCard: View {
    @EnvironmentObject private var store: LocalStore
    let note: RoomNote

    private var stateText: String {
        switch note.state {
        case .scored: return "Scored"
        case .skipped: return "Skipped"
        case .pending: return "Pending"
        }
    }

    private var stateColor: Color {
        switch note.state {
        case .scored: return Theme.accentSage
        case .skipped: return Theme.inkTertiary
        case .pending: return Theme.accentBrass
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(note.roomType.displayName, systemImage: note.roomType.sfSymbol)
                    .font(Theme.body().weight(.semibold))
                    .foregroundStyle(Theme.inkPrimary)
                Spacer()
                Text(stateText)
                    .font(Theme.caption().weight(.semibold))
                    .foregroundStyle(stateColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(stateColor.opacity(0.14))
                    .clipShape(Capsule())
            }
            if !note.criterionScores.isEmpty {
                let enabledIds = Set(store.enabledCriteria.map(\.id))
                let scored = note.criterionScores.filter { enabledIds.contains($0.key) }
                if !scored.isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(store.enabledCriteria.filter { scored[$0.id] != nil }) { criterion in
                            HStack(spacing: 4) {
                                Image(systemName: criterion.sfSymbol)
                                Text("\(criterion.name) \(scored[criterion.id] ?? 0)")
                                    .lineLimit(1)
                            }
                            .font(Theme.caption())
                            .foregroundStyle(Theme.inkSecondary)
                        }
                    }
                }
            }
            if !note.note.isEmpty {
                Text(note.note)
                    .font(Theme.caption())
                    .foregroundStyle(Theme.inkSecondary)
                    .italic()
            }
        }
        .padding(12)
        .panelCard()
    }
}

// MARK: - viewing_edit sheet

struct ViewingEditSheet: View {
    enum Mode {
        case create
        case edit(Viewing)
    }

    @EnvironmentObject private var store: LocalStore
    @Environment(\.dismiss) private var dismiss

    let mode: Mode
    var onSaved: (Viewing) -> Void

    @State private var title: String = ""
    @State private var address: String = ""
    @State private var rentText: String = ""
    @State private var bedsText: String = ""
    @State private var bathsText: String = ""
    @State private var notes: String = ""
    @State private var attemptedSave = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case title, address, rent, beds, baths, notes }

    private var addressValid: Bool {
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    labeledField("Address", placeholder: "123 Main St, Apt 4B", text: $address, field: .address)
                    if attemptedSave && !addressValid {
                        Text("Address is required.")
                            .font(Theme.caption())
                            .foregroundStyle(Theme.warnTerracotta)
                    }
                    labeledField("Title (optional)", placeholder: "Defaults to address", text: $title, field: .title)
                    HStack(spacing: 12) {
                        labeledField("Rent $/mo", placeholder: "1850", text: $rentText, field: .rent, keyboard: .numberPad)
                        labeledField("Beds", placeholder: "2", text: $bedsText, field: .beds, keyboard: .numberPad)
                        labeledField("Baths", placeholder: "1", text: $bathsText, field: .baths, keyboard: .decimalPad)
                    }
                    labeledField("Notes", placeholder: "Broker contact, quirks…", text: $notes, field: .notes, axis: .vertical)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .paperBackground()
            .navigationTitle(isEditing ? "Edit Viewing" : "New Viewing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.inkSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.accentBrass)
                        .disabled(!addressValid)
                }
            }
            .onAppear {
                if case .edit(let viewing) = mode {
                    title = viewing.title
                    address = viewing.address
                    rentText = viewing.rentCents.map { "\($0 / 100)" } ?? ""
                    bedsText = viewing.beds.map { "\($0)" } ?? ""
                    bathsText = viewing.baths.map { $0.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int($0))" : "\($0)" } ?? ""
                    notes = viewing.generalNotes
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func labeledField(_ label: String, placeholder: String, text: Binding<String>, field: Field,
                              keyboard: UIKeyboardType = .default, axis: Axis = .horizontal) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Theme.caption().weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
            TextField(placeholder, text: text, axis: axis)
                .font(Theme.body())
                .foregroundStyle(Theme.inkPrimary)
                .keyboardType(keyboard)
                .focused($focusedField, equals: field)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Theme.bgPanel)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func save() {
        attemptedSave = true
        focusedField = nil // keyboard dismiss on commit, content preserved
        guard addressValid else { return }
        let rentCents = Int(rentText).map { $0 * 100 }
        let beds = Int(bedsText)
        let baths = Double(bathsText)
        switch mode {
        case .create:
            let created = store.createViewing(address: address, title: title, rentCents: rentCents,
                                              beds: beds, baths: baths, generalNotes: notes)
            dismiss()
            onSaved(created)
        case .edit(var viewing):
            viewing.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? address.trimmingCharacters(in: .whitespacesAndNewlines) : title
            viewing.address = address
            viewing.rentCents = rentCents
            viewing.beds = beds
            viewing.baths = baths
            viewing.generalNotes = notes
            store.updateViewing(viewing)
            dismiss()
            onSaved(viewing)
        }
    }
}

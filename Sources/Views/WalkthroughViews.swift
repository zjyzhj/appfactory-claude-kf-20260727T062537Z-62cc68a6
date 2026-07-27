import SwiftUI
import PhotosUI
import UIKit

// MARK: - capture_walkthrough (full-screen cover)

/// capture_walkthrough route: guided multi-room scoring. Room queue order from
/// RoomType.walkthroughQueue; arbitrary jumps allowed; Finish anytime (pending
/// rooms record skipped); interruption resumes via LocalStore progress (B1).
struct WalkthroughCoverView: View {
    @EnvironmentObject private var store: LocalStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let viewingId: UUID
    @State private var currentRoom: RoomType = .kitchen
    @State private var showingFinishSummary = false
    @State private var didLoad = false

    private var viewingTitle: String {
        store.viewing(id: viewingId)?.title ?? "Walkthrough"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                roomStepper
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                RoomCaptureView(viewingId: viewingId, roomType: currentRoom,
                                onAdvance: { advance(after: $0) },
                                onFinish: { showingFinishSummary = true })
                    .id(currentRoom) // stagger_room: room content swaps per step
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .opacity))
            }
            .paperBackground()
            .navigationTitle("Walkthrough")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.inkSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text("Scoring: \(currentRoom.displayName)")
                        .font(Theme.body())
                        .foregroundStyle(Theme.inkSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Finish") { showingFinishSummary = true }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.accentBrass)
                }
            }
            .sheet(isPresented: $showingFinishSummary) {
                WalkthroughFinishSummary(viewingId: viewingId) {
                    store.finishWalkthrough(viewingId: viewingId)
                    showingFinishSummary = false
                    dismiss()
                }
                .presentationDetents([.medium])
            }
            .onAppear {
                guard !didLoad else { return }
                didLoad = true
                let progress = store.startOrResumeWalkthrough(viewingId: viewingId)
                currentRoom = progress.currentRoomType
            }
        }
    }

    private func advance(after room: RoomType) {
        let queue = RoomType.walkthroughQueue
        guard let index = queue.firstIndex(of: room) else { return }
        if index + 1 < queue.count {
            selectRoom(queue[index + 1])
        } else {
            showingFinishSummary = true
        }
    }

    private func selectRoom(_ room: RoomType) {
        withAnimation(MotionLanguage.animation(.easeOut(duration: MotionLanguage.staggerRoom * 3), reduceMotion: reduceMotion)) {
            currentRoom = room
        }
        store.updateWalkthroughRoom(viewingId: viewingId, roomType: room)
    }

    private var roomStepper: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RoomType.walkthroughQueue, id: \.self) { room in
                    let note = store.roomNote(forViewing: viewingId, roomType: room)
                    let isCurrent = room == currentRoom
                    Button { selectRoom(room) } label: {
                        HStack(spacing: 5) {
                            if note?.state == .scored {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(isCurrent ? .white : Theme.accentSage)
                            } else if note?.state == .skipped {
                                Image(systemName: "minus.circle")
                                    .foregroundStyle(isCurrent ? .white : Theme.inkTertiary)
                            }
                            Text(room.displayName)
                                .font(Theme.caption().weight(.semibold))
                        }
                        .foregroundStyle(isCurrent ? .white : Theme.inkSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isCurrent ? Theme.accentBrass : Theme.bgPanel)
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("\(room.displayName), \(note?.state.rawValue ?? "pending")")
                }
            }
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Finish summary (B1: finish shows scored/skipped)

struct WalkthroughFinishSummary: View {
    @EnvironmentObject private var store: LocalStore
    let viewingId: UUID
    var onConfirm: () -> Void

    var body: some View {
        let counts = store.walkthroughCounts(forViewing: viewingId)
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.accentSage)
                    .padding(.top, 12)
                Text("Finish walkthrough?")
                    .font(Theme.pageTitle())
                    .foregroundStyle(Theme.inkPrimary)
                Text("Walkthrough complete — nice evidence. See how it ranks in Compare.")
                    .font(Theme.body())
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                HStack(spacing: 24) {
                    summaryPill(count: counts.scored, label: "scored", color: Theme.accentSage)
                    summaryPill(count: counts.skipped + counts.pending, label: "skipped", color: Theme.inkTertiary)
                }
                Button(action: onConfirm) {
                    Text("Finish & mark toured")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accentBrass)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                .accessibilityLabel("Finish walkthrough and mark toured")
            }
            .paperBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func summaryPill(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 26, weight: .semibold).monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(Theme.caption())
                .foregroundStyle(Theme.inkSecondary)
        }
    }
}

// MARK: - room_capture (per-room capture + scoring)

/// room_capture route (room_photo_slot + ACC-F3): camera capture / Photos pick
/// / skip, bound to the room's RoomNote. Camera denied → three in-app
/// continuations (Choose Photo / Add without a photo / Retry Camera) — never a
/// Settings jump (ACC-F3-DENIED). mot_commit_photo on bind (ACC-MOT-COMMIT).
struct RoomCaptureView: View {
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var permissions: PermissionCenter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let viewingId: UUID
    let roomType: RoomType
    var onAdvance: (RoomType) -> Void
    var onFinish: () -> Void

    @State private var noteText: String = ""
    @State private var scores: [UUID: Int] = [:]
    @State private var cameraDenied = false
    @State private var photosDenied = false
    @State private var showingCameraPicker = false
    @State private var showingPhotosPicker = false
    @State private var cardLifted = false
    @State private var latestPhotoToken: UUID? = nil
    @FocusState private var noteFocused: Bool

    private var roomNote: RoomNote? { store.roomNote(forViewing: viewingId, roomType: roomType) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photoSection
                criteriaSection
                noteSection
                navigationButtons
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { loadExisting() }
        .sheet(isPresented: $showingCameraPicker) {
            CameraPicker { image in
                showingCameraPicker = false
                if let image { bindPhoto(image) }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingPhotosPicker) {
            PhotosPickerSheet { image in
                showingPhotosPicker = false
                if let image { bindPhoto(image) }
            }
        }
    }

    // MARK: Photo section (room_photo_slot)

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Evidence photos")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)

            roomPhotoSlot
                .offset(y: cardLifted ? -2 : 0)

            if cameraDenied {
                // capture_denied in-place card — three in-app continuations.
                VStack(alignment: .leading, spacing: 8) {
                    Text("Camera is off for TourWise.")
                        .font(Theme.body().weight(.semibold))
                        .foregroundStyle(Theme.inkPrimary)
                    Text("You can Choose Photo from your library, Add without a photo, or Retry Camera.")
                        .font(Theme.caption())
                        .foregroundStyle(Theme.inkSecondary)
                    HStack(spacing: 10) {
                        deniedButton("Choose Photo", systemImage: "photo.on.rectangle") { choosePhoto() }
                        deniedButton("Add without a photo", systemImage: "arrow.right") { markScoredAndAdvance() }
                        deniedButton("Retry Camera", systemImage: "camera") { takePhoto() }
                    }
                }
                .padding(12)
                .panelCard()
            }
            if photosDenied {
                // photos_read_limited picker empty-state copy.
                Text("No photos available. You can Take Photo or Add without a photo.")
                    .font(Theme.caption())
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.horizontal, 4)
            }

            HStack(spacing: 10) {
                if permissions.takePhotoAvailable {
                    actionButton("Take Photo", systemImage: "camera.fill", primary: true) { takePhoto() }
                }
                actionButton("Choose Photo", systemImage: "photo.on.rectangle.angled", primary: false) { choosePhoto() }
            }
        }
    }

    private var roomPhotoSlot: some View {
        let photos = roomNote?.photoRelativePaths ?? []
        return Group {
            if photos.isEmpty {
                // Empty fallback: dashed frame + camera.fill + label.
                VStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.inkTertiary)
                    Text("Add photo evidence")
                        .font(Theme.body())
                        .foregroundStyle(Theme.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 170)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.photoCorner, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                        .foregroundStyle(Theme.inkTertiary)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Add photo evidence for \(roomType.displayName)")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, path in
                            PolaroidPhoto(image: store.loadPhoto(relativePath: path), aspectRatio: 4.0 / 3.0,
                                          accessibilityLabelText: "\(roomType.displayName) evidence photo \(index + 1) of \(photos.count)")
                                .frame(width: 190)
                                // mot_commit_photo: newest photo flies in and
                                // lands with the polaroid tilt; Reduce Motion →
                                // 60ms opacity fade only.
                                .transition(.asymmetric(
                                    insertion: reduceMotion
                                        ? .opacity.animation(.easeIn(duration: 0.06))
                                        : .scale(scale: 0.6).combined(with: .opacity).combined(with: .offset(x: 40)),
                                    removal: .opacity))
                        }
                    }
                    .padding(.vertical, 6)
                }
                .animation(MotionLanguage.animation(MotionLanguage.durSettle, reduceMotion: reduceMotion),
                           value: photos.count)
            }
        }
    }

    // MARK: Criteria scoring (1–5 per enabled criterion)

    private var criteriaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Score this room")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)
            ForEach(store.enabledCriteria) { criterion in
                CriterionScoreRow(criterion: criterion,
                                  value: scores[criterion.id],
                                  onScore: { value in setScore(criterionId: criterion.id, value: value) })
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("One-line note")
                .font(Theme.caption().weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
            HStack(spacing: 8) {
                Image(systemName: "pencil.line")
                    .foregroundStyle(Theme.inkTertiary)
                TextField("Drafty window near sink…", text: $noteText)
                    .font(Theme.body())
                    .foregroundStyle(Theme.inkPrimary)
                    .focused($noteFocused)
                    .submitLabel(.done)
                    .onSubmit { noteFocused = false; persist() }
                    .onChange(of: noteText) { _, _ in persist() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Theme.bgPanel)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            Button {
                skipRoom()
            } label: {
                Text("Skip room")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Theme.bgPanel)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Spacer()
            Button {
                markScoredAndAdvance()
            } label: {
                Label("Next room", systemImage: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Theme.accentBrass)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .accessibilityLabel("Save and go to next room")
        }
        .padding(.top, 4)
    }

    private func actionButton(_ title: String, systemImage: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(primary ? .white : Theme.accentBrass)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(primary ? Theme.accentBrass : Theme.bgPanel)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .accessibilityLabel(title)
    }

    private func deniedButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Theme.caption().weight(.semibold))
                .foregroundStyle(Theme.accentBrass)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Theme.accentBrass.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .accessibilityLabel(title)
    }

    // MARK: Behavior

    private func loadExisting() {
        guard let note = roomNote else { return }
        scores = note.criterionScores
        noteText = note.note
    }

    private func setScore(criterionId: UUID, value: Int) {
        if scores[criterionId] == value {
            scores.removeValue(forKey: criterionId) // tap again to clear
        } else {
            scores[criterionId] = value
            TourWiseHaptics.commit() // haptic_commit on score submit
        }
        persist()
    }

    private func persist() {
        guard var note = roomNote ?? Optional(store.upsertRoomNote(RoomNote(viewingId: viewingId, roomType: roomType))) else { return }
        note.criterionScores = scores
        note.note = noteText
        if note.state == .pending && (!scores.isEmpty || !(note.photoRelativePaths.isEmpty)) {
            note.state = .scored
        }
        store.upsertRoomNote(note)
    }

    private func markScoredAndAdvance() {
        guard var note = roomNote ?? Optional(store.upsertRoomNote(RoomNote(viewingId: viewingId, roomType: roomType))) else { return }
        note.criterionScores = scores
        note.note = noteText
        note.state = .scored
        store.upsertRoomNote(note)
        TourWiseHaptics.commit()
        onAdvance(roomType)
    }

    private func skipRoom() {
        guard var note = roomNote ?? Optional(store.upsertRoomNote(RoomNote(viewingId: viewingId, roomType: roomType))) else { return }
        note.state = .skipped
        store.upsertRoomNote(note)
        onAdvance(roomType)
    }

    // MARK: Capture flows (JIT permission; denied → in-app continuation)

    private func takePhoto() {
        photosDenied = false
        if PermissionCenter.syntheticCaptureEnabled {
            // Deterministic capture substitute seam (checklist A12): synthetic
            // media walks the granted capture → bind journey headlessly.
            let image = PermissionCenter.syntheticPhoto(roomName: roomType.displayName)
            bindPhoto(image)
            return
        }
        Task {
            let granted = await permissions.requestCameraAccessIfNeeded()
            await MainActor.run {
                if granted {
                    cameraDenied = false
                    showingCameraPicker = true
                } else {
                    cameraDenied = true // stays in-app; three continuations above
                }
            }
        }
    }

    private func choosePhoto() {
        cameraDenied = false
        Task {
            let granted = await permissions.requestPhotosReadIfNeeded()
            await MainActor.run {
                if granted {
                    photosDenied = false
                    showingPhotosPicker = true
                } else {
                    photosDenied = true // picker empty-state copy; Take Photo / Add remain
                }
            }
        }
    }

    private func bindPhoto(_ image: UIImage) {
        guard let note = roomNote ?? Optional(store.upsertRoomNote(RoomNote(viewingId: viewingId, roomType: roomType))) else { return }
        guard let data = image.jpegData(compressionQuality: 0.82) else { return }
        if store.attachPhoto(data: data, toRoomNote: note.id) != nil {
            // mot_commit_photo: photo lands on the board + medium haptic; the
            // room card lifts 2pt and settles (dur_settle).
            TourWiseHaptics.commit()
            latestPhotoToken = UUID()
            withAnimation(MotionLanguage.animation(MotionLanguage.durSettle, reduceMotion: reduceMotion)) {
                cardLifted = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                withAnimation(MotionLanguage.animation(MotionLanguage.durSettle, reduceMotion: reduceMotion)) {
                    cardLifted = false
                }
            }
            persist() // photo presence flips pending → scored
        }
    }
}

// MARK: - Criterion score row (320×568 → vertical 5-button column)

struct CriterionScoreRow: View {
    let criterion: Criterion
    let value: Int?
    var onScore: (Int) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalRow
            verticalRow
        }
        .padding(12)
        .panelCard()
    }

    private var horizontalRow: some View {
        HStack(spacing: 10) {
            Image(systemName: criterion.sfSymbol)
                .foregroundStyle(Theme.accentBrass)
                .frame(width: 22)
            Text(criterion.name)
                .font(Theme.body().weight(.medium))
                .foregroundStyle(Theme.inkPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            scoreButtons(horizontal: true)
        }
        .accessibilityElement(children: .contain)
    }

    /// 320×568 minimum layout: 5 score buttons stack vertically (design.md a11y).
    private var verticalRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: criterion.sfSymbol)
                    .foregroundStyle(Theme.accentBrass)
                    .frame(width: 22)
                Text(criterion.name)
                    .font(Theme.body().weight(.medium))
                    .foregroundStyle(Theme.inkPrimary)
            }
            scoreButtons(horizontal: false)
        }
    }

    private func scoreButtons(horizontal: Bool) -> some View {
        let buttons = ForEach(1...5, id: \.self) { score in
            Button { onScore(score) } label: {
                Text("\(score)")
                    .font(.system(size: 14, weight: .semibold).monospacedDigit())
                    .foregroundStyle(value == score ? .white : Theme.inkSecondary)
                    .frame(width: horizontal ? 34 : 44, height: 34)
                    .background(value == score ? Theme.accentBrass : Theme.scoreTrack.opacity(0.55))
                    .clipShape(Circle())
            }
            .accessibilityLabel("\(score) of 5 for \(criterion.name)")
            .accessibilityHint(value == score ? "Selected" : "")
        }
        return Group {
            if horizontal {
                HStack(spacing: 6) { buttons }
            } else {
                HStack(spacing: 10) { buttons }
            }
        }
    }
}

// MARK: - Camera picker (UIImagePickerController, hardware only)

struct CameraPicker: UIViewControllerRepresentable {
    var onResult: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onResult: (UIImage?) -> Void
        init(onResult: @escaping (UIImage?) -> Void) { self.onResult = onResult }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onResult(info[.originalImage] as? UIImage)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onResult(nil)
        }
    }
}

// MARK: - Photos picker (PHPicker, read access JIT-gated by caller)

struct PhotosPickerSheet: UIViewControllerRepresentable {
    var onResult: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onResult: (UIImage?) -> Void
        init(onResult: @escaping (UIImage?) -> Void) { self.onResult = onResult }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                onResult(nil)
                return
            }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async { [weak self] in
                    self?.onResult(object as? UIImage)
                }
            }
        }
    }
}

import Foundation
import UIKit

/// Walkthrough resume snapshot (PM routes: Resume Walkthrough restores the
/// exact room + progress after interruption).
struct WalkthroughProgress: Codable, Equatable {
    var currentRoomType: RoomType
    var startedAt: Date
}

/// In-progress weight editor draft — preserved across tab switches (ACC-NAV).
struct WeightEditorDraft: Codable, Equatable {
    var profileId: UUID? // nil = unsaved new profile
    var name: String
    var weights: [UUID: Int]
}

/// Local-first persistence (PM data-model.md): every entity lives on-device as
/// JSON in the app sandbox; photos are files under `Photos/<viewingId>/`.
/// No account, no sync, no analytics, no third-party network calls.
@MainActor
final class LocalStore: ObservableObject {
    @Published private(set) var viewings: [Viewing] = []
    @Published private(set) var roomNotes: [RoomNote] = []
    @Published private(set) var criteria: [Criterion] = []
    @Published private(set) var weightProfiles: [WeightProfile] = []
    @Published private(set) var ledger: ExportCreditLedger = .init()
    @Published private(set) var exportRecords: [ExportRecord] = []

    /// Cross-tab preserved state (ACC-NAV / ACC-F2 resume).
    @Published var compareSelection: [UUID] = [] { didSet { scheduleSave() } }
    @Published var weightEditorDraft: WeightEditorDraft? = nil { didSet { scheduleSave() } }
    @Published private(set) var walkthroughProgress: [UUID: WalkthroughProgress] = [:]

    private let fileURL: URL
    private let documentsDirectory: URL
    private var saveTask: Task<Void, Never>?

    // MARK: - Init / load

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        documentsDirectory = dir
        fileURL = dir.appendingPathComponent("tourwise-store.json")
        load()
        seedIfNeeded()
    }

    /// Isolated store for unit tests — never touches the live Documents JSON.
    init(testingDirectory: URL) {
        try? FileManager.default.createDirectory(at: testingDirectory, withIntermediateDirectories: true)
        documentsDirectory = testingDirectory
        fileURL = testingDirectory.appendingPathComponent("tourwise-store.json")
        seedIfNeeded()
    }

    private struct Snapshot: Codable {
        var viewings: [Viewing]
        var roomNotes: [RoomNote]
        var criteria: [Criterion]
        var weightProfiles: [WeightProfile]
        var ledger: ExportCreditLedger
        var exportRecords: [ExportRecord]
        var compareSelection: [UUID]
        var weightEditorDraft: WeightEditorDraft?
        var walkthroughProgress: [UUID: WalkthroughProgress]
        var creditedStoreKitTransactionIds: [UInt64]
        var seeded: Bool
    }

    private var seededFlag: Bool = false
    /// StoreKit transaction ids already credited — makes consumable crediting
    /// idempotent across purchase() and Transaction.updates redelivery.
    private(set) var creditedStoreKitTransactionIds: [UInt64] = []

    func markStoreKitTransactionCredited(_ id: UInt64) {
        guard !creditedStoreKitTransactionIds.contains(id) else { return }
        creditedStoreKitTransactionIds.append(id)
        scheduleSave()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        viewings = snapshot.viewings
        roomNotes = snapshot.roomNotes
        criteria = snapshot.criteria
        weightProfiles = snapshot.weightProfiles
        ledger = snapshot.ledger
        exportRecords = snapshot.exportRecords
        compareSelection = snapshot.compareSelection
        weightEditorDraft = snapshot.weightEditorDraft
        walkthroughProgress = snapshot.walkthroughProgress
        creditedStoreKitTransactionIds = snapshot.creditedStoreKitTransactionIds
        seededFlag = snapshot.seeded
    }

    /// First launch: 9 built-in criteria, "Balanced" WeightProfile, ledger
    /// grant(+100) per yanran initial_balance=100.
    private func seedIfNeeded() {
        guard !seededFlag else { return }
        if criteria.isEmpty { criteria = Criterion.seeded }
        if weightProfiles.isEmpty { weightProfiles = [WeightProfile.balancedSeed(criteria: criteria)] }
        if ledger.transactions.isEmpty { ledger = .seeded }
        seededFlag = true
        saveNow()
    }

    // MARK: - Save

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    func saveNow() {
        let snapshot = Snapshot(viewings: viewings, roomNotes: roomNotes, criteria: criteria,
                                weightProfiles: weightProfiles, ledger: ledger,
                                exportRecords: exportRecords, compareSelection: compareSelection,
                                weightEditorDraft: weightEditorDraft,
                                walkthroughProgress: walkthroughProgress,
                                creditedStoreKitTransactionIds: creditedStoreKitTransactionIds,
                                seeded: seededFlag)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Photo files (relative paths only)

    var photosRootDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func photoDirectory(forViewing viewingId: UUID) -> URL {
        let dir = photosRootDirectory.appendingPathComponent(viewingId.idString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Saves JPEG bytes into the viewing's sandbox folder; returns the RELATIVE path.
    func savePhoto(data: Data, viewingId: UUID) -> String? {
        let fileName = "\(UUID().uuidString).jpg"
        let url = photoDirectory(forViewing: viewingId).appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return "Photos/\(viewingId.idString)/\(fileName)"
        } catch {
            return nil
        }
    }

    func absoluteURL(forRelativePath relativePath: String) -> URL {
        documentsDirectory.appendingPathComponent(relativePath)
    }

    func loadPhoto(relativePath: String) -> UIImage? {
        guard let data = try? Data(contentsOf: absoluteURL(forRelativePath: relativePath)) else { return nil }
        return UIImage(data: data)
    }

    private func deletePhotoFiles(forViewing viewingId: UUID) {
        let dir = photosRootDirectory.appendingPathComponent(viewingId.idString, isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - Viewings (F1)

    @discardableResult
    func createViewing(address: String, title: String? = nil, rentCents: Int? = nil,
                       beds: Int? = nil, baths: Double? = nil, generalNotes: String = "") -> Viewing {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let derivedTitle = (title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? title!.trimmingCharacters(in: .whitespacesAndNewlines)
            : trimmedAddress
        let viewing = Viewing(title: derivedTitle, address: trimmedAddress, rentCents: rentCents,
                              beds: beds, baths: baths, status: .draft, generalNotes: generalNotes)
        viewings.insert(viewing, at: 0)
        scheduleSave()
        return viewing
    }

    func updateViewing(_ viewing: Viewing) {
        guard let index = viewings.firstIndex(where: { $0.id == viewing.id }) else { return }
        var updated = viewing
        updated.updatedAt = Date()
        viewings[index] = updated
        scheduleSave()
    }

    func viewing(id: UUID) -> Viewing? {
        viewings.first(where: { $0.id == id })
    }

    func setViewingStatus(_ viewingId: UUID, status: ViewingStatus) {
        guard var viewing = viewing(id: viewingId) else { return }
        viewing.status = status
        updateViewing(viewing)
    }

    /// ACC-F1-DELETE / B4: confirm copy lives in the view; here the cascade.
    /// Removes the Viewing, its RoomNotes, its sandbox Photos/<id>/ files, and
    /// any compare-selection / walkthrough residue.
    func deleteViewing(id: UUID) {
        viewings.removeAll { $0.id == id }
        roomNotes.removeAll { $0.viewingId == id }
        compareSelection.removeAll { $0 == id }
        walkthroughProgress.removeValue(forKey: id)
        deletePhotoFiles(forViewing: id)
        scheduleSave()
    }

    // MARK: - RoomNotes (F2/F3)

    func roomNotes(forViewing viewingId: UUID) -> [RoomNote] {
        roomNotes.filter { $0.viewingId == viewingId }
    }

    @discardableResult
    func upsertRoomNote(_ note: RoomNote) -> RoomNote {
        if let index = roomNotes.firstIndex(where: { $0.id == note.id }) {
            roomNotes[index] = note
        } else {
            roomNotes.append(note)
        }
        scheduleSave()
        return note
    }

    func roomNote(forViewing viewingId: UUID, roomType: RoomType) -> RoomNote? {
        roomNotes.first { $0.viewingId == viewingId && $0.roomType == roomType }
    }

    /// Binds a captured/picked photo to a RoomNote (ACC-F3-PHOTO).
    @discardableResult
    func attachPhoto(data: Data, toRoomNote roomNoteId: UUID) -> String? {
        guard let index = roomNotes.firstIndex(where: { $0.id == roomNoteId }) else { return nil }
        let note = roomNotes[index]
        guard let relativePath = savePhoto(data: data, viewingId: note.viewingId) else { return nil }
        roomNotes[index].photoRelativePaths.append(relativePath)
        scheduleSave()
        return relativePath
    }

    // MARK: - Walkthrough lifecycle (B1)

    func startOrResumeWalkthrough(viewingId: UUID) -> WalkthroughProgress {
        if let existing = walkthroughProgress[viewingId] { return existing }
        let progress = WalkthroughProgress(currentRoomType: RoomType.walkthroughQueue[0], startedAt: Date())
        walkthroughProgress[viewingId] = progress
        // Ensure RoomNote shells exist for every room in the queue.
        for roomType in RoomType.walkthroughQueue where roomNote(forViewing: viewingId, roomType: roomType) == nil {
            upsertRoomNote(RoomNote(viewingId: viewingId, roomType: roomType))
        }
        scheduleSave()
        return progress
    }

    func updateWalkthroughRoom(viewingId: UUID, roomType: RoomType) {
        guard var progress = walkthroughProgress[viewingId] else { return }
        progress.currentRoomType = roomType
        walkthroughProgress[viewingId] = progress
        scheduleSave()
    }

    /// Finish: pending rooms become skipped; viewing becomes toured; progress clears.
    func finishWalkthrough(viewingId: UUID) {
        for index in roomNotes.indices where roomNotes[index].viewingId == viewingId && roomNotes[index].state == .pending {
            roomNotes[index].state = .skipped
        }
        setViewingStatus(viewingId, status: .toured)
        walkthroughProgress.removeValue(forKey: viewingId)
        scheduleSave()
    }

    func walkthroughCounts(forViewing viewingId: UUID) -> (scored: Int, skipped: Int, pending: Int) {
        let notes = roomNotes(forViewing: viewingId)
        let scored = notes.filter { $0.state == .scored }.count
        let skipped = notes.filter { $0.state == .skipped }.count
        return (scored, skipped, notes.count - scored - skipped)
    }

    // MARK: - Criteria (F4 / B3)

    var enabledCriteria: [Criterion] {
        criteria.filter { $0.isEnabled }.sorted { $0.sortOrder < $1.sortOrder }
    }

    @discardableResult
    func createCriterion(name: String, sfSymbol: String) -> Criterion? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !criteria.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) else { return nil }
        let criterion = Criterion(name: trimmed, sfSymbol: sfSymbol, isBuiltIn: false,
                                  sortOrder: (criteria.map(\.sortOrder).max() ?? 0) + 1)
        criteria.append(criterion)
        scheduleSave()
        return criterion
    }

    func setCriterionEnabled(_ criterionId: UUID, enabled: Bool) {
        guard let index = criteria.firstIndex(where: { $0.id == criterionId }) else { return }
        criteria[index].isEnabled = enabled
        scheduleSave()
    }

    /// Built-in criteria are never deletable (B3).
    func deleteCriterion(id: UUID) -> Bool {
        guard let criterion = criteria.first(where: { $0.id == id }), !criterion.isBuiltIn else { return false }
        criteria.removeAll { $0.id == id }
        scheduleSave()
        return true
    }

    // MARK: - WeightProfiles (F5)

    var activeWeightProfile: WeightProfile? {
        weightProfiles.first(where: { $0.isActive }) ?? weightProfiles.first
    }

    @discardableResult
    func saveWeightProfile(id: UUID?, name: String, weights: [UUID: Int]) -> WeightProfile? {
        guard ScoringEngine.weightsAreSaveable(weights: weights) else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let id, let index = weightProfiles.firstIndex(where: { $0.id == id }) {
            weightProfiles[index].name = trimmed
            weightProfiles[index].weights = weights
            weightProfiles[index].updatedAt = Date()
            scheduleSave()
            return weightProfiles[index]
        }
        let profile = WeightProfile(name: trimmed, weights: weights, isActive: weightProfiles.isEmpty)
        weightProfiles.append(profile)
        scheduleSave()
        return profile
    }

    /// Exactly one active profile globally; compare re-ranks immediately.
    func activateWeightProfile(id: UUID) {
        for index in weightProfiles.indices {
            weightProfiles[index].isActive = (weightProfiles[index].id == id)
        }
        scheduleSave()
    }

    /// Cannot delete the active profile or the last remaining one. ExportRecords
    /// keep their weightProfileId snapshot — never cascaded.
    func deleteWeightProfile(id: UUID) -> Bool {
        guard weightProfiles.count > 1,
              let profile = weightProfiles.first(where: { $0.id == id }),
              !profile.isActive else { return false }
        weightProfiles.removeAll { $0.id == id }
        scheduleSave()
        return true
    }

    // MARK: - Compare selection (tab state preserved)

    func toggleCompareSelection(viewingId: UUID) {
        if let index = compareSelection.firstIndex(of: viewingId) {
            compareSelection.remove(at: index)
        } else if compareSelection.count < 5 {
            compareSelection.append(viewingId)
        }
    }

    // MARK: - Export credits + records (F7/F8; CreditStore drives mutations)

    func applyCreditTransaction(_ txn: CreditTxn) {
        let newBalance = ledger.balance + txn.amount
        guard newBalance >= 0 else { return } // invariant: balance ≥ 0
        ledger.balance = newBalance
        ledger.transactions.append(txn)
        ledger.updatedAt = Date()
        scheduleSave()
    }

    func recordExport(_ record: ExportRecord) {
        exportRecords.insert(record, at: 0)
        scheduleSave()
    }

    /// Saves the rendered verdict card copy into the sandbox (relative path).
    func saveVerdictCopy(data: Data) -> String? {
        let dir = photosRootDirectory.appendingPathComponent("verdicts", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileName = "verdict-\(UUID().uuidString).png"
        let url = dir.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return "Photos/verdicts/\(fileName)"
        } catch {
            return nil
        }
    }

    // MARK: - Delete All Data (B10)

    /// Wipes every entity + photo file, then reseeds first-launch defaults.
    func deleteAllData() {
        viewings = []
        roomNotes = []
        exportRecords = []
        compareSelection = []
        weightEditorDraft = nil
        walkthroughProgress = [:]
        try? FileManager.default.removeItem(at: photosRootDirectory)
        criteria = Criterion.seeded
        weightProfiles = [WeightProfile.balancedSeed(criteria: criteria)]
        ledger = .seeded
        seededFlag = true
        saveNow()
    }
}

private extension UUID {
    /// path-safe id string used for sandbox folders.
    var idString: String { uuidString }
}

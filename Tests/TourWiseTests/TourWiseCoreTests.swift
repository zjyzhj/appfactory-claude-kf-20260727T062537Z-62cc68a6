import XCTest
import UIKit
@testable import TourWise

/// Headless unit coverage (B11 / B2 / A9 / B3 / B4 / A14 / A15):
/// weighted formula + bounds, ledger invariants (grant/purchase/spend/refund),
/// criteria seeds, cascade delete, walkthrough lifecycle, verdict renderer,
/// and privacy-boundary absences.
final class TourWiseCoreTests: XCTestCase {

    @MainActor
    private func makeStore() -> (LocalStore, URL) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("tourwise-tests-\(UUID().uuidString)", isDirectory: true)
        return (LocalStore(testingDirectory: root), root)
    }

    // MARK: - Seeding (B3 / A9)

    @MainActor
    func testFirstLaunchSeedsNineCriteriaBalancedProfileAndGrant100() {
        let (store, root) = makeStore()
        defer { try? FileManager.default.removeItem(at: root) }

        // 9 built-in criteria in PM order.
        XCTAssertEqual(store.criteria.count, 9)
        XCTAssertTrue(store.criteria.allSatisfy { $0.isBuiltIn && $0.isEnabled })
        XCTAssertEqual(store.criteria.map(\.name),
                       ["Natural Light", "Noise", "Space & Storage", "Condition", "Kitchen",
                        "Bathroom", "Location & Commute", "Building & Safety", "Price Fit"])

        // Balanced profile: active, sums to exactly 100.
        let profile = store.activeWeightProfile
        XCTAssertEqual(profile?.name, "Balanced")
        XCTAssertEqual(profile?.total, 100)
        XCTAssertEqual(profile?.weights.count, 9)

        // yanran initial_balance=100 as grant(+100).
        XCTAssertEqual(store.ledger.balance, 100)
        XCTAssertEqual(store.ledger.transactions.count, 1)
        XCTAssertEqual(store.ledger.transactions.first?.kind, .grant)
        XCTAssertEqual(store.ledger.transactions.first?.amount, 100)
        XCTAssertEqual(store.ledger.transactions.first?.reason, "seed")
    }

    // MARK: - Weighted formula (B2 / ACC-F6)

    func testWeightedScoreNormalizesOverScoredCriteriaOnly() {
        let c1 = UUID(), c2 = UUID(), c3 = UUID()
        let notes = [
            RoomNote(viewingId: UUID(), roomType: .kitchen, criterionScores: [c1: 5, c2: 3], state: .scored),
            RoomNote(viewingId: UUID(), roomType: .living, criterionScores: [c1: 1, c2: 3], state: .scored),
        ]
        // c1 mean = 3.0, c2 mean = 3.0, c3 unscored → drops out entirely.
        let score = ScoringEngine.weightedScore(
            roomNotes: notes,
            weights: [c1: 50, c2: 25, c3: 25],
            enabledCriterionIds: [c1, c2, c3])
        // (3×50 + 3×25) / (50+25) = 225/75 = 3.0 — c3's 25 weight does NOT punish.
        XCTAssertEqual(score ?? 0, 3.0, accuracy: 0.0001)
    }

    func testMissingCriterionNeverBecomesZero() {
        let c1 = UUID(), c2 = UUID()
        let notes = [RoomNote(viewingId: UUID(), roomType: .bath, criterionScores: [c1: 5], state: .scored)]
        XCTAssertNil(ScoringEngine.criterionMean(criterionId: c2, roomNotes: notes)) // "—", not 0
        let score = ScoringEngine.weightedScore(
            roomNotes: notes, weights: [c1: 50, c2: 50], enabledCriterionIds: [c1, c2])
        XCTAssertEqual(score ?? 0, 5.0, accuracy: 0.0001) // renormalized over c1 only
    }

    func testDisabledCriterionIsExcludedFromDenominator() {
        let c1 = UUID(), c2 = UUID()
        let notes = [RoomNote(viewingId: UUID(), roomType: .kitchen, criterionScores: [c1: 4, c2: 1], state: .scored)]
        let score = ScoringEngine.weightedScore(
            roomNotes: notes, weights: [c1: 50, c2: 50], enabledCriterionIds: [c1]) // c2 disabled
        XCTAssertEqual(score ?? 0, 4.0, accuracy: 0.0001)
    }

    func testWeightSwitchReranksImmediately() {
        let light = UUID(), commute = UUID()
        let v1 = Viewing(title: "Sunny Flat", address: "1 Sun St")
        let v2 = Viewing(title: "Metro Loft", address: "2 Rail Ave")
        let notesByViewing: [UUID: [RoomNote]] = [
            v1.id: [RoomNote(viewingId: v1.id, roomType: .living, criterionScores: [light: 5, commute: 2], state: .scored)],
            v2.id: [RoomNote(viewingId: v2.id, roomType: .living, criterionScores: [light: 2, commute: 5], state: .scored)],
        ]
        let enabled = [
            Criterion(id: light, name: "Natural Light", sfSymbol: "sun.max.fill", isBuiltIn: true, sortOrder: 0),
            Criterion(id: commute, name: "Location & Commute", sfSymbol: "tram.fill", isBuiltIn: true, sortOrder: 1),
        ]
        let lightFirst = WeightProfile(name: "Light-first", weights: [light: 90, commute: 10], isActive: true)
        let commuteFirst = WeightProfile(name: "Commute-first", weights: [light: 10, commute: 90], isActive: true)

        let rankedLight = ScoringEngine.rank(viewings: [v1, v2], roomNotesByViewing: notesByViewing,
                                             profile: lightFirst, enabledCriteria: enabled)
        let rankedCommute = ScoringEngine.rank(viewings: [v1, v2], roomNotesByViewing: notesByViewing,
                                               profile: commuteFirst, enabledCriteria: enabled)
        XCTAssertEqual(rankedLight.first?.viewing.id, v1.id)
        XCTAssertEqual(rankedCommute.first?.viewing.id, v2.id) // observable re-rank
    }

    func testShortlistBoundsAreTwoToFive() {
        XCTAssertEqual(ScoringEngine.validateShortlist(count: 0), .tooFew(0))
        XCTAssertEqual(ScoringEngine.validateShortlist(count: 1), .tooFew(1))
        XCTAssertEqual(ScoringEngine.validateShortlist(count: 2), .valid)
        XCTAssertEqual(ScoringEngine.validateShortlist(count: 5), .valid)
        XCTAssertEqual(ScoringEngine.validateShortlist(count: 6), .tooMany(6))
    }

    func testWeightValidationBlocksNonHundred() {
        XCTAssertFalse(ScoringEngine.weightsAreSaveable(weights: [UUID(): 50, UUID(): 40])) // Σ=90
        XCTAssertEqual(ScoringEngine.weightDelta(weights: [UUID(): 50, UUID(): 40]), 10) // "add 10 to save"
        XCTAssertEqual(ScoringEngine.weightDelta(weights: [UUID(): 60, UUID(): 50]), -10) // "remove 10"
        XCTAssertTrue(ScoringEngine.weightsAreSaveable(weights: [UUID(): 60, UUID(): 40]))
    }

    // MARK: - Criteria lifecycle (B3 / ACC-F4)

    @MainActor
    func testBuiltInCriteriaCannotBeDeletedCustomImmediatelyAvailable() {
        let (store, root) = makeStore()
        defer { try? FileManager.default.removeItem(at: root) }

        let builtInId = store.criteria[0].id
        XCTAssertFalse(store.deleteCriterion(id: builtInId))
        XCTAssertEqual(store.criteria.count, 9)

        let custom = store.createCriterion(name: "Water Pressure", sfSymbol: "drop.fill")
        XCTAssertNotNil(custom)
        // Immediately in the enabled set → walkthrough & compare pick it up.
        XCTAssertTrue(store.enabledCriteria.contains(where: { $0.id == custom?.id }))

        // Disable filters it out of scoring surfaces.
        store.setCriterionEnabled(custom!.id, enabled: false)
        XCTAssertFalse(store.enabledCriteria.contains(where: { $0.id == custom!.id }))
        store.setCriterionEnabled(custom!.id, enabled: true)

        // Duplicate names rejected; custom deletable.
        XCTAssertNil(store.createCriterion(name: "Water Pressure", sfSymbol: "star.fill"))
        XCTAssertTrue(store.deleteCriterion(id: custom!.id))
    }

    // MARK: - WeightProfile rules (data-model invariants)

    @MainActor
    func testActiveAndLastProfilesCannotBeDeleted() {
        let (store, root) = makeStore()
        defer { try? FileManager.default.removeItem(at: root) }

        let balanced = store.weightProfiles[0]
        XCTAssertFalse(store.deleteWeightProfile(id: balanced.id)) // last one

        let weights = Dictionary(uniqueKeysWithValues: store.enabledCriteria.map { ($0.id, $0.sortOrder == 0 ? 100 : 0) })
        let second = store.saveWeightProfile(id: nil, name: "Commute-first", weights: weights)
        XCTAssertNotNil(second)
        XCTAssertFalse(store.deleteWeightProfile(id: balanced.id)) // still active
        store.activateWeightProfile(id: second!.id)
        XCTAssertTrue(store.deleteWeightProfile(id: balanced.id)) // now deletable
        XCTAssertEqual(store.activeWeightProfile?.id, second!.id)
    }

    @MainActor
    func testNonHundredProfileSaveIsRejected() {
        let (store, root) = makeStore()
        defer { try? FileManager.default.removeItem(at: root) }
        let bad = Dictionary(uniqueKeysWithValues: store.enabledCriteria.map { ($0.id, 10) }) // Σ=90
        XCTAssertNil(store.saveWeightProfile(id: nil, name: "Broken", weights: bad))
        XCTAssertEqual(store.weightProfiles.count, 1)
    }

    // MARK: - Walkthrough lifecycle (B1)

    @MainActor
    func testWalkthroughFinishMarksPendingSkippedAndToured() {
        let (store, root) = makeStore()
        defer { try? FileManager.default.removeItem(at: root) }

        let viewing = store.createViewing(address: "12 Oak Ave")
        XCTAssertEqual(viewing.status, .draft)

        let progress = store.startOrResumeWalkthrough(viewingId: viewing.id)
        XCTAssertEqual(progress.currentRoomType, .kitchen)
        XCTAssertEqual(store.roomNotes(forViewing: viewing.id).count, 6) // queue shells

        // Score one room, resume mid-flow, finish.
        var kitchen = store.roomNote(forViewing: viewing.id, roomType: .kitchen)!
        kitchen.criterionScores = [store.enabledCriteria[0].id: 4]
        kitchen.state = .scored
        store.upsertRoomNote(kitchen)
        store.updateWalkthroughRoom(viewingId: viewing.id, roomType: .bath)

        // Interruption + resume restores the exact room.
        let resumed = store.startOrResumeWalkthrough(viewingId: viewing.id)
        XCTAssertEqual(resumed.currentRoomType, .bath)

        store.finishWalkthrough(viewingId: viewing.id)
        XCTAssertEqual(store.viewing(id: viewing.id)?.status, .toured)
        let counts = store.walkthroughCounts(forViewing: viewing.id)
        XCTAssertEqual(counts.scored, 1)
        XCTAssertEqual(counts.skipped, 5) // pending → skipped
        XCTAssertNil(store.walkthroughProgress[viewing.id])
    }

    // MARK: - Cascade delete (B4 / ACC-F1-DELETE)

    @MainActor
    func testDeleteViewingCascadesNotesAndPhotoFiles() throws {
        let (store, root) = makeStore()
        defer { try? FileManager.default.removeItem(at: root) }

        let viewing = store.createViewing(address: "9 Pine Rd")
        store.startOrResumeWalkthrough(viewingId: viewing.id)
        let note = store.roomNote(forViewing: viewing.id, roomType: .kitchen)!

        // Photo bytes land in sandbox Photos/<viewingId>/ with a RELATIVE path.
        let jpeg = PermissionCenter.syntheticPhoto(roomName: "Kitchen").jpegData(compressionQuality: 0.8)!
        let relative = store.attachPhoto(data: jpeg, toRoomNote: note.id)
        XCTAssertNotNil(relative)
        XCTAssertFalse(relative!.hasPrefix("/"), "paths stay relative")
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.absoluteURL(forRelativePath: relative!).path))

        store.toggleCompareSelection(viewingId: viewing.id)
        store.deleteViewing(id: viewing.id)

        XCTAssertNil(store.viewing(id: viewing.id))
        XCTAssertTrue(store.roomNotes(forViewing: viewing.id).isEmpty)
        XCTAssertFalse(store.compareSelection.contains(viewing.id))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.absoluteURL(forRelativePath: relative!).path))
    }

    // MARK: - Credit ledger + export spend (A9 / ACC-F8-IAP / B5)

    @MainActor
    func testPurchaseCreditAndIdempotency() {
        let (store, root) = makeStore()
        defer { try? FileManager.default.removeItem(at: root) }

        // yanran catalog: 473900 → +110, 473901 → +210.
        XCTAssertEqual(CreditStore.catalog["473900"], 110)
        XCTAssertEqual(CreditStore.catalog["473901"], 210)
        XCTAssertEqual(CreditStore.catalogProductIDs, ["473900", "473901"])

        store.applyCreditTransaction(CreditTxn(kind: .purchase, amount: 110, reason: "purchase(473900)"))
        XCTAssertEqual(store.ledger.balance, 210)
        store.applyCreditTransaction(CreditTxn(kind: .purchase, amount: 210, reason: "purchase(473901)"))
        XCTAssertEqual(store.ledger.balance, 420)
        XCTAssertEqual(store.ledger.transactions.filter { $0.kind == .purchase }.count, 2)
    }

    @MainActor
    func testExportSuccessSpendsExactlyOneAndRecordsSnapshot() async {
        let (store, root) = makeStore()
        defer { try? FileManager.default.removeItem(at: root) }
        let credits = CreditStore(store: store)
        let viewing = store.createViewing(address: "3 Elm St")

        let outcome = await credits.performExport(
            viewingIds: [viewing.id], weightProfileId: store.activeWeightProfile!.id,
            render: { Data("png-bytes".utf8) },
            save: { _ in })
        guard case .exported = outcome else { return XCTFail("export should succeed") }
        XCTAssertEqual(store.ledger.balance, 99)
        XCTAssertEqual(store.ledger.transactions.last?.kind, .spend)
        XCTAssertEqual(store.ledger.transactions.last?.amount, -1)
        XCTAssertEqual(store.ledger.transactions.last?.reason, "verdictExport")
        XCTAssertEqual(store.exportRecords.first?.viewingIds, [viewing.id])
        XCTAssertEqual(store.exportRecords.first?.weightProfileId, store.activeWeightProfile!.id)
    }

    @MainActor
    func testRenderFailureRefundsSpendIsNotCommitted() async {
        struct RenderBroke: Error {}
        let (store, root) = makeStore()
        defer { try? FileManager.default.removeItem(at: root) }
        let credits = CreditStore(store: store)

        let outcome = await credits.performExport(
            viewingIds: [], weightProfileId: store.activeWeightProfile!.id,
            render: { throw RenderBroke() },
            save: { _ in XCTFail("save must not run when render fails") })
        XCTAssertEqual(outcome, .renderFailed)
        XCTAssertEqual(store.ledger.balance, 100) // refund semantics: nothing debited
        XCTAssertTrue(store.exportRecords.isEmpty)
    }

    @MainActor
    func testSaveFailureDoesNotDebit() async {
        struct SaveBroke: Error {}
        let (store, root) = makeStore()
        defer { try? FileManager.default.removeItem(at: root) }
        let credits = CreditStore(store: store)

        let outcome = await credits.performExport(
            viewingIds: [], weightProfileId: store.activeWeightProfile!.id,
            render: { Data("png".utf8) },
            save: { _ in throw SaveBroke() })
        XCTAssertEqual(outcome, .saveFailed)
        XCTAssertEqual(store.ledger.balance, 100)
        XCTAssertTrue(store.exportRecords.isEmpty)
    }

    @MainActor
    func testInsufficientCreditsBlocksExportAndBalanceNeverGoesNegative() async {
        let (store, root) = makeStore()
        defer { try? FileManager.default.removeItem(at: root) }
        // Drain to zero via 100 successful exports.
        for _ in 0..<100 {
            store.applyCreditTransaction(CreditTxn(kind: .spend, amount: -1, reason: "verdictExport"))
        }
        XCTAssertEqual(store.ledger.balance, 0)

        let credits = CreditStore(store: store)
        let outcome = await credits.performExport(
            viewingIds: [], weightProfileId: store.activeWeightProfile!.id,
            render: { Data("png".utf8) },
            save: { _ in })
        XCTAssertEqual(outcome, .insufficientCredits)
        XCTAssertEqual(store.ledger.balance, 0)

        // Invariant: applyCreditTransaction refuses negative balances.
        store.applyCreditTransaction(CreditTxn(kind: .spend, amount: -1, reason: "verdictExport"))
        XCTAssertEqual(store.ledger.balance, 0)
    }

    // MARK: - Verdict renderer (verdict_card_render; headless)

    func testVerdictRendererProducesPNGWithAndWithoutPhotos() throws {
        let model = VerdictCardModel(
            winnerTitle: "Maple St 2B", winnerScore: 4.3,
            runnerUps: [("Oak Ave 4C", 3.9), ("Cedar Ln", 3.4)],
            evidencePhotos: [], // color-block fallback path — export never blocked
            weightProfileName: "Balanced", date: Date())
        let data = try VerdictRenderer.renderPNG(model: model)
        XCTAssertFalse(data.isEmpty)
        let expected = CGSize(width: VerdictRenderer.cardSize.width * VerdictRenderer.outputScale,
                              height: VerdictRenderer.cardSize.height * VerdictRenderer.outputScale)
        XCTAssertEqual(UIImage(data: data)?.size, expected)

        let withPhoto = VerdictCardModel(
            winnerTitle: "Maple St 2B", winnerScore: 4.3,
            runnerUps: [("Oak Ave 4C", 3.9)],
            evidencePhotos: [PermissionCenter.syntheticPhoto(roomName: "Kitchen")],
            weightProfileName: "Balanced", date: Date())
        XCTAssertFalse(try VerdictRenderer.renderPNG(model: withPhoto).isEmpty)
    }

    // MARK: - Privacy boundary absences (A14 / A15 / ACC-REV-PRIVACY)

    func testInfoPlistDeclaresExactlyCameraAndPhotoPermissions() {
        let bundle = Bundle.main
        XCTAssertEqual(
            bundle.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String,
            "TourWise uses the camera to attach evidence photos to the room you are scoring.")
        XCTAssertEqual(
            bundle.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") as? String,
            "TourWise lets you attach existing photos from a viewing to its room scores.")
        XCTAssertEqual(
            bundle.object(forInfoDictionaryKey: "NSPhotoLibraryAddUsageDescription") as? String,
            "TourWise saves your verdict card to Photos so you can share it with family.")
        // Absence proof set: microphone + ATT are declared-absent capabilities.
        XCTAssertNil(bundle.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription"))
        XCTAssertNil(bundle.object(forInfoDictionaryKey: "NSUserTrackingUsageDescription"))
        XCTAssertNil(bundle.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription"))
        XCTAssertNil(bundle.object(forInfoDictionaryKey: "NSContactsUsageDescription"))
    }

    // MARK: - Delete All Data (B10)

    @MainActor
    func testDeleteAllDataWipesAndReseeds() {
        let (store, root) = makeStore()
        defer { try? FileManager.default.removeItem(at: root) }
        let viewing = store.createViewing(address: "7 Birch Way")
        store.startOrResumeWalkthrough(viewingId: viewing.id)
        store.applyCreditTransaction(CreditTxn(kind: .spend, amount: -1, reason: "verdictExport"))

        store.deleteAllData()
        XCTAssertTrue(store.viewings.isEmpty)
        XCTAssertTrue(store.roomNotes.isEmpty)
        XCTAssertTrue(store.exportRecords.isEmpty)
        XCTAssertEqual(store.criteria.count, 9) // reseeded defaults
        XCTAssertEqual(store.activeWeightProfile?.name, "Balanced")
        XCTAssertEqual(store.ledger.balance, 100)
    }
}

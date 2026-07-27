import Foundation

/// PM data-model.md weighted formula (B2 / ACC-F5 / ACC-F6):
///   weighted score = Σ(score[c] × weight[c]) / Σ(weight[c] over scored AND enabled criteria)
/// A viewing's score[c] is the mean of that criterion's room scores (1...5).
/// Missing scores never count as 0 — the criterion drops out of the denominator
/// and compare cells render "—".
enum ScoringEngine {

    /// Mean score for one criterion across a viewing's room notes.
    /// Returns nil when no room scored it (renders "—" downstream).
    static func criterionMean(criterionId: UUID, roomNotes: [RoomNote]) -> Double? {
        var sum = 0
        var count = 0
        for note in roomNotes {
            if let score = note.criterionScores[criterionId], (1...5).contains(score) {
                sum += score
                count += 1
            }
        }
        guard count > 0 else { return nil }
        return Double(sum) / Double(count)
    }

    /// Normalized weighted score in 0...5. Only enabled criteria with at least
    /// one scored room participate; weights renormalize over what is present.
    /// Returns nil when nothing scored (viewing has no usable data).
    static func weightedScore(roomNotes: [RoomNote], weights: [UUID: Int], enabledCriterionIds: Set<UUID>) -> Double? {
        var weightedSum = 0.0
        var weightTotal = 0
        for (criterionId, weight) in weights where weight > 0 && enabledCriterionIds.contains(criterionId) {
            guard let mean = criterionMean(criterionId: criterionId, roomNotes: roomNotes) else { continue }
            weightedSum += mean * Double(weight)
            weightTotal += weight
        }
        guard weightTotal > 0 else { return nil }
        return weightedSum / Double(weightTotal)
    }

    /// Unweighted overall mean across every scored criterion (list "Overall score").
    static func flatMean(roomNotes: [RoomNote]) -> Double? {
        var sum = 0
        var count = 0
        for note in roomNotes {
            for score in note.criterionScores.values where (1...5).contains(score) {
                sum += score
                count += 1
            }
        }
        guard count > 0 else { return nil }
        return Double(sum) / Double(count)
    }

    // MARK: - Compare ranking

    struct RankedViewing: Equatable {
        var viewing: Viewing
        /// nil = no usable scores; ranks below every scored viewing.
        var score: Double?
        var criterionMeans: [UUID: Double]
    }

    /// Rank shortlisted viewings by the active WeightProfile. Scored viewings
    /// sort high→low; unscored trail alphabetically. Ties break by title.
    static func rank(viewings: [Viewing], roomNotesByViewing: [UUID: [RoomNote]],
                     profile: WeightProfile, enabledCriteria: [Criterion]) -> [RankedViewing] {
        let enabledIds = Set(enabledCriteria.filter { $0.isEnabled }.map(\.id))
        var ranked = viewings.map { viewing -> RankedViewing in
            let notes = roomNotesByViewing[viewing.id] ?? []
            var means: [UUID: Double] = [:]
            for criterion in enabledCriteria where criterion.isEnabled {
                if let mean = criterionMean(criterionId: criterion.id, roomNotes: notes) {
                    means[criterion.id] = mean
                }
            }
            let score = weightedScore(roomNotes: notes, weights: profile.weights, enabledCriterionIds: enabledIds)
            return RankedViewing(viewing: viewing, score: score, criterionMeans: means)
        }
        ranked.sort { lhs, rhs in
            switch (lhs.score, rhs.score) {
            case let (l?, r?):
                if abs(l - r) > 0.0005 { return l > r }
                return lhs.viewing.title.localizedCaseInsensitiveCompare(rhs.viewing.title) == .orderedAscending
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil):
                return lhs.viewing.title.localizedCaseInsensitiveCompare(rhs.viewing.title) == .orderedAscending
            }
        }
        return ranked
    }

    // MARK: - Shortlist bounds (B2: 2–5)

    enum ShortlistValidation: Equatable {
        case valid
        case tooFew(Int)   // "Shortlist at least 2 viewings to compare."
        case tooMany(Int)  // blocked > 5
    }

    static func validateShortlist(count: Int) -> ShortlistValidation {
        if count < 2 { return .tooFew(count) }
        if count > 5 { return .tooMany(count) }
        return .valid
    }

    // MARK: - Weight editing validation (Σ=100)

    /// Returns the delta from 100; 0 means saveable. Sign shows direction:
    /// negative = under-allocated (add), positive = over (remove).
    static func weightDelta(weights: [UUID: Int]) -> Int {
        100 - weights.values.reduce(0, +)
    }

    static func weightsAreSaveable(weights: [UUID: Int]) -> Bool {
        weightDelta(weights: weights) == 0 && weights.values.allSatisfy { (0...100).contains($0) }
    }
}

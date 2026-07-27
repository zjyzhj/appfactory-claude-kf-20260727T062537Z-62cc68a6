import Foundation

/// PM data-model.md — all-local entities. No account, no network.
/// Photos live in the app sandbox under `Photos/<viewingId>/<uuid>.jpg` and are
/// referenced by RELATIVE path only (never absolute).

// MARK: - Viewing

enum ViewingStatus: String, Codable, CaseIterable {
    case draft, toured, shortlisted, rejected

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .toured: return "Toured"
        case .shortlisted: return "Shortlist"
        case .rejected: return "Rejected"
        }
    }
}

struct Viewing: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var address: String
    var rentCents: Int?
    var beds: Int?
    var baths: Double?
    var status: ViewingStatus
    var visitedAt: Date
    var generalNotes: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, address: String, rentCents: Int? = nil,
         beds: Int? = nil, baths: Double? = nil, status: ViewingStatus = .draft,
         visitedAt: Date = Date(), generalNotes: String = "",
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.address = address
        self.rentCents = rentCents
        self.beds = beds
        self.baths = baths
        self.status = status
        self.visitedAt = visitedAt
        self.generalNotes = generalNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var rentDisplay: String? {
        guard let rentCents else { return nil }
        let dollars = rentCents / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let amount = formatter.string(from: NSNumber(value: dollars)) ?? "\(dollars)"
        return "$\(amount)/mo"
    }
}

// MARK: - RoomNote

enum RoomType: Codable, Hashable, CaseIterable {
    case kitchen, living, bedroom, bath, building, outdoor
    case custom(String)

    static var allCases: [RoomType] { [.kitchen, .living, .bedroom, .bath, .building, .outdoor] }

    var displayName: String {
        switch self {
        case .kitchen: return "Kitchen"
        case .living: return "Living"
        case .bedroom: return "Bedroom"
        case .bath: return "Bath"
        case .building: return "Building"
        case .outdoor: return "Outdoor"
        case .custom(let name): return name
        }
    }

    var sfSymbol: String {
        switch self {
        case .kitchen: return "frying.pan"
        case .living: return "sofa.fill"
        case .bedroom: return "bed.double.fill"
        case .bath: return "shower.fill"
        case .building: return "building.2.fill"
        case .outdoor: return "tree.fill"
        case .custom: return "square.grid.2x2.fill"
        }
    }

    /// Walkthrough stepper order (PM routes: room_queue = enabled RoomType sequence).
    static var walkthroughQueue: [RoomType] { [.kitchen, .living, .bedroom, .bath, .building, .outdoor] }
}

enum RoomNoteState: String, Codable {
    case pending, scored, skipped
}

struct RoomNote: Codable, Identifiable, Equatable {
    var id: UUID
    var viewingId: UUID
    var roomType: RoomType
    /// criterionId -> 1...5; only scored criteria are stored.
    var criterionScores: [UUID: Int]
    var note: String
    /// Local RELATIVE paths (Photos/<viewingId>/<uuid>.jpg). Never absolute.
    var photoRelativePaths: [String]
    var state: RoomNoteState

    init(id: UUID = UUID(), viewingId: UUID, roomType: RoomType,
         criterionScores: [UUID: Int] = [:], note: String = "",
         photoRelativePaths: [String] = [], state: RoomNoteState = .pending) {
        self.id = id
        self.viewingId = viewingId
        self.roomType = roomType
        self.criterionScores = criterionScores
        self.note = note
        self.photoRelativePaths = photoRelativePaths
        self.state = state
    }
}

// MARK: - Criterion

struct Criterion: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var sfSymbol: String
    var isBuiltIn: Bool
    var isEnabled: Bool
    var sortOrder: Int

    init(id: UUID = UUID(), name: String, sfSymbol: String, isBuiltIn: Bool,
         isEnabled: Bool = true, sortOrder: Int) {
        self.id = id
        self.name = name
        self.sfSymbol = sfSymbol
        self.isBuiltIn = isBuiltIn
        self.isEnabled = isEnabled
        self.sortOrder = sortOrder
    }

    /// PM data-model: 9 built-in seeds. criterion_icons slot = SF Symbol mapping.
    static let builtInSeeds: [(name: String, symbol: String)] = [
        ("Natural Light", "sun.max.fill"),
        ("Noise", "ear.fill"),
        ("Space & Storage", "cube.fill"),
        ("Condition", "wrench.and.screwdriver.fill"),
        ("Kitchen", "frying.pan"),
        ("Bathroom", "shower.fill"),
        ("Location & Commute", "tram.fill"),
        ("Building & Safety", "building.2.fill"),
        ("Price Fit", "dollarsign.circle.fill"),
    ]

    static var seeded: [Criterion] {
        builtInSeeds.enumerated().map { index, seed in
            // Stable UUIDs so reseeds never duplicate.
            Criterion(id: Criterion.stableBuiltInID(index: index), name: seed.name,
                      sfSymbol: seed.symbol, isBuiltIn: true, sortOrder: index)
        }
    }

    static func stableBuiltInID(index: Int) -> UUID {
        // Deterministic UUID from index (namespace-ish; keeps seed idempotent).
        var bytes = [UInt8](repeating: 0, count: 16)
        bytes[0] = 0x54; bytes[1] = 0x57 // "TW"
        withUnsafeBytes(of: UInt32(index).bigEndian) { bytes[12] = $0[0]; bytes[13] = $0[1]; bytes[14] = $0[2]; bytes[15] = $0[3] }
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}

// MARK: - WeightProfile

struct WeightProfile: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    /// criterionId -> 0...100; must validate Σ=100.
    var weights: [UUID: Int]
    var isActive: Bool
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, weights: [UUID: Int], isActive: Bool = false,
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.weights = weights
        self.isActive = isActive
        self.updatedAt = updatedAt
    }

    var total: Int { weights.values.reduce(0, +) }

    /// PM seed: "Balanced" — 9 built-in criteria split to sum 100.
    static func balancedSeed(criteria: [Criterion]) -> WeightProfile {
        let enabled = criteria.filter { $0.isBuiltIn }.sorted { $0.sortOrder < $1.sortOrder }
        let base = 100 / max(enabled.count, 1)
        var weights: [UUID: Int] = [:]
        var remainder = 100 - base * enabled.count
        for criterion in enabled {
            weights[criterion.id] = base + (remainder > 0 ? 1 : 0)
            if remainder > 0 { remainder -= 1 }
        }
        return WeightProfile(id: UUID(uuidString: "54575000-0000-4000-8000-000000000001")!,
                             name: "Balanced", weights: weights, isActive: true)
    }
}

// MARK: - Export credits (yanran consumable balance catalog)

enum CreditTxnKind: String, Codable {
    case grant, purchase, spend
}

struct CreditTxn: Codable, Identifiable, Equatable {
    var id: UUID
    var kind: CreditTxnKind
    /// Signed delta: grant +100, purchase +110/+210, spend -1.
    var amount: Int
    /// purchase(productId ∈ {473900, 473901}) / spend(verdictExport) / grant(seed).
    var reason: String
    var createdAt: Date

    init(id: UUID = UUID(), kind: CreditTxnKind, amount: Int, reason: String, createdAt: Date = Date()) {
        self.id = id
        self.kind = kind
        self.amount = amount
        self.reason = reason
        self.createdAt = createdAt
    }
}

struct ExportCreditLedger: Codable, Equatable {
    var balance: Int
    var transactions: [CreditTxn]
    var updatedAt: Date

    init(balance: Int = 0, transactions: [CreditTxn] = [], updatedAt: Date = Date()) {
        self.balance = balance
        self.transactions = transactions
        self.updatedAt = updatedAt
    }

    /// yanran initial_balance=100 — first-launch seed recorded as grant(+100).
    static var seeded: ExportCreditLedger {
        ExportCreditLedger(balance: 100,
                           transactions: [CreditTxn(kind: .grant, amount: 100, reason: "seed")])
    }
}

// MARK: - ExportRecord

struct ExportRecord: Codable, Identifiable, Equatable {
    var id: UUID
    var viewingIds: [UUID]
    var weightProfileId: UUID
    /// Local rendered-card copy when Save to Photos succeeded.
    var verdictPhotoRelativePath: String?
    var createdAt: Date

    init(id: UUID = UUID(), viewingIds: [UUID], weightProfileId: UUID,
         verdictPhotoRelativePath: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.viewingIds = viewingIds
        self.weightProfileId = weightProfileId
        self.verdictPhotoRelativePath = verdictPhotoRelativePath
        self.createdAt = createdAt
    }
}

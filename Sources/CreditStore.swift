import Foundation
import StoreKit

/// yanran consumable balance catalog (hash-bound data contract):
/// Export Credits. 473900 = +110 ($0.99), 473901 = +210 ($1.99).
/// initial_balance = 100 seeded at first launch by LocalStore as grant(+100).
/// Consumable semantics: NO Restore Purchases, no subscription, no unlock copy.
@MainActor
final class CreditStore: ObservableObject {

    /// yanran catalog entries for this package (product_id → credit amount).
    /// Product IDs are internal-only and never surface in UI copy.
    static let catalog: [String: Int] = ["473900": 110, "473901": 210]
    static let catalogProductIDs: [String] = ["473900", "473901"]

    @Published private(set) var products: [Product] = []
    @Published private(set) var loadFailed: Bool = false
    @Published private(set) var purchaseInFlight: Bool = false

    private let store: LocalStore
    private var updatesTask: Task<Void, Never>?

    init(store: LocalStore) {
        self.store = store
        updatesTask = Task { [weak self] in
            await self?.listenForTransactions()
        }
        Task { await loadProducts() }
    }

    deinit { updatesTask?.cancel() }

    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: Self.catalogProductIDs)
            // Stable order: 110-credit pack first, then 210.
            products = Self.catalogProductIDs.compactMap { id in fetched.first(where: { $0.id == id }) }
            loadFailed = products.isEmpty
        } catch {
            products = []
            loadFailed = true
        }
    }

    // MARK: - Purchase (A9 / ACC-F8-IAP)

    enum PurchaseOutcome: Equatable {
        case purchased(credits: Int)
        case cancelled
        case failed      // toast: balance unchanged
        case unavailable // product not loaded
    }

    /// Credits land ONLY after a verified transaction, and BEFORE finish().
    /// Idempotent per StoreKit transaction id — a redelivered update never
    /// double-credits. Any failure path leaves the balance untouched.
    func purchase(product: Product) async -> PurchaseOutcome {
        guard let amount = Self.catalog[product.id] else { return .unavailable }
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return .failed }
                creditVerifiedTransaction(transaction, amount: amount)
                await transaction.finish()
                return .purchased(credits: amount)
            case .userCancelled:
                return .cancelled
            case .pending:
                return .cancelled
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    private func creditVerifiedTransaction(_ transaction: StoreKit.Transaction, amount: Int) {
        guard !store.creditedStoreKitTransactionIds.contains(transaction.id) else { return }
        store.markStoreKitTransactionCredited(transaction.id)
        store.applyCreditTransaction(CreditTxn(kind: .purchase, amount: amount,
                                               reason: "purchase(\(transaction.productID))"))
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            if let amount = Self.catalog[transaction.productID] {
                creditVerifiedTransaction(transaction, amount: amount)
            }
            await transaction.finish()
        }
    }

    // MARK: - Spend (verdict export; B5 / data-model invariant)

    enum ExportOutcome: Equatable {
        case exported(localCopy: String?)
        case insufficientCredits // CTA becomes "Get Credits"; preview never blocked
        case renderFailed        // refunded: spend and render are one transaction
        case saveFailed
    }

    /// Spend point: verdict_card export. Balance is debited ONLY on export
    /// success (spend −1 with the render in the same transaction — a render
    /// failure refunds before any debit). Records the ExportRecord snapshot.
    @discardableResult
    func performExport(viewingIds: [UUID], weightProfileId: UUID,
                       render: () throws -> Data,
                       save: (Data) async throws -> Void) async -> ExportOutcome {
        guard store.ledger.balance >= 1 else { return .insufficientCredits }
        let pngData: Data
        do {
            pngData = try render()
        } catch {
            return .renderFailed // nothing debited — refund semantics
        }
        do {
            try await save(pngData)
        } catch {
            return .saveFailed // export did not succeed — no debit
        }
        store.applyCreditTransaction(CreditTxn(kind: .spend, amount: -1, reason: "verdictExport"))
        let localCopy = store.saveVerdictCopy(data: pngData)
        store.recordExport(ExportRecord(viewingIds: viewingIds, weightProfileId: weightProfileId,
                                        verdictPhotoRelativePath: localCopy))
        return .exported(localCopy: localCopy)
    }
}

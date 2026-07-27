import SwiftUI
import StoreKit

// MARK: - paywall (sheet)

/// paywall route (F8 / ACC-F8-IAP): balance card + the two yanran catalog
/// tiers (110 credits $0.99 / 210 credits $1.99). Consumable semantics: NO
/// Restore Purchases entry, no subscription/unlock copy, product IDs never
/// surface in UI. Purchase failure → toast, balance untouched.
struct PaywallView: View {
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var credits: CreditStore
    @Environment(\.dismiss) private var dismiss

    @State private var toast: String? = nil
    @State private var showTryAgain = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    balanceCard
                    ForEach(credits.products, id: \.id) { product in
                        productCard(product: product)
                    }
                    if credits.products.isEmpty {
                        productsUnavailableCard
                    }
                    finePrint
                }
                .padding(16)
            }
            .paperBackground()
            .navigationTitle("Export Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    HStack(spacing: 10) {
                        Text(toast)
                            .font(Theme.body())
                            .foregroundStyle(.white)
                        if showTryAgain {
                            Button("Try Again") {
                                self.toast = nil
                                Task { await credits.loadProducts() }
                            }
                            .font(Theme.body().weight(.semibold))
                            .foregroundStyle(Theme.accentBrass)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Theme.inkPrimary.opacity(0.92))
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Balance")
                .font(Theme.body())
                .foregroundStyle(Theme.inkSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(store.ledger.balance)")
                    .font(.system(size: 64, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.inkPrimary)
                Text("credits")
                    .font(Theme.sectionTitle())
                    .foregroundStyle(Theme.inkSecondary)
            }
            Rectangle()
                .fill(Theme.accentBrass)
                .frame(height: 2)
            Text("Starter credits included")
                .font(Theme.caption())
                .foregroundStyle(Theme.inkTertiary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Balance \(store.ledger.balance) credits")
    }

    private func productCard(product: Product) -> some View {
        let creditsAmount = CreditStore.catalog[product.id] ?? 0
        let isBestValue = creditsAmount == 210
        return Button {
            purchase(product)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(creditsAmount) Export Credits")
                        .font(Theme.sectionTitle())
                        .foregroundStyle(Theme.inkPrimary)
                    Spacer()
                    Text(product.displayPrice)
                        .font(Theme.sectionTitle())
                        .foregroundStyle(Theme.inkPrimary)
                }
                Text(isBestValue ? "Best value · twice the exports" : "Stock up for many Verdict exports")
                    .font(Theme.caption())
                    .foregroundStyle(Theme.inkSecondary)
                if isBestValue {
                    Text("Best value")
                        .font(Theme.caption().weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.accentSage)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.bgPanel)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .strokeBorder(isBestValue ? Theme.accentSage : Color.clear, lineWidth: 1.5)
            )
            .opacity(credits.purchaseInFlight ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .disabled(credits.purchaseInFlight)
        .accessibilityLabel("Buy \(creditsAmount) Export Credits for \(product.displayPrice)")
    }

    private var productsUnavailableCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(credits.loadFailed ? "Credit packs are unavailable right now." : "Loading credit packs…")
                .font(Theme.body())
                .foregroundStyle(Theme.inkSecondary)
            if credits.loadFailed {
                Button("Try Again") {
                    Task { await credits.loadProducts() }
                }
                .font(Theme.body().weight(.semibold))
                .foregroundStyle(Theme.accentBrass)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelCard()
    }

    private var finePrint: some View {
        Text("Credits never expire. Each export uses 1 credit. Exports are rendered on-device; nothing leaves your phone.")
            .font(Theme.caption())
            .foregroundStyle(Theme.inkSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.top, 4)
    }

    private func purchase(_ product: Product) {
        Task {
            let outcome = await credits.purchase(product: product)
            await MainActor.run {
                switch outcome {
                case .purchased(let amount):
                    TourWiseHaptics.verdictSuccess()
                    toast = "\(amount) credits added."
                    showTryAgain = false
                case .failed:
                    // purchase_failed toast — balance provably unchanged.
                    toast = "Purchase didn't complete. Your credits were not changed."
                    showTryAgain = true
                case .cancelled:
                    toast = nil
                case .unavailable:
                    toast = "That pack is unavailable right now."
                    showTryAgain = true
                }
            }
        }
    }
}

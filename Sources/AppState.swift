import Foundation
import SwiftUI

/// Root dependency container — one writer for the product state.
@MainActor
final class AppState: ObservableObject {
    let store: LocalStore
    let credits: CreditStore
    let permissions: PermissionCenter

    init(store: LocalStore? = nil, permissions: PermissionCenter = .shared) {
        let resolvedStore = store ?? LocalStore()
        self.store = resolvedStore
        self.credits = CreditStore(store: resolvedStore)
        self.permissions = permissions
    }
}

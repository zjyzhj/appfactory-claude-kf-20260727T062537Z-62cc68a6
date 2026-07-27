import SwiftUI
import WebKit

// MARK: - tab_settings

/// tab_settings route: Export Credit balance + Buy Credits, privacy entry,
/// data export (JSON), legal webviews, about. Secondary utilities stay nested
/// here — they never compete with the primary tabs (A8).
struct SettingsHomeView: View {
    @EnvironmentObject private var store: LocalStore
    @State private var showingPaywall = false
    @State private var shareItems: [Any] = []
    @State private var showingShare = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    creditsCard
                    dataSection
                    legalSection
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .paperBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingShare) {
                ActivityView(items: shareItems) { _ in }
            }
            .navigationDestination(for: String.self) { route in
                switch route {
                case "privacy":
                    PrivacyView()
                case "legal.privacyPolicy":
                    LegalWebView(title: "Privacy Policy", url: URL(string: "https://tourwise.app/privacy")!)
                case "legal.userAgreement":
                    LegalWebView(title: "User Agreement", url: URL(string: "https://tourwise.app/terms")!)
                default:
                    EmptyView()
                }
            }
        }
    }

    private var creditsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Export Credits")
                    .font(Theme.sectionTitle())
                    .foregroundStyle(Theme.inkPrimary)
                Spacer()
                Text("\(store.ledger.balance)")
                    .font(.system(size: 30, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.accentBrass)
            }
            Text("Each Verdict card export uses 1 credit. Credits never expire.")
                .font(Theme.caption())
                .foregroundStyle(Theme.inkSecondary)
            Button { showingPaywall = true } label: {
                Label("Buy Credits", systemImage: "shippingbox.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accentBrass)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .accessibilityLabel("Buy Credits")
        }
        .padding(14)
        .panelCard()
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your data")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)
            NavigationLink(value: "privacy") {
                settingsRow(icon: "hand.raised.fill", title: "Privacy & data boundary",
                            subtitle: "Everything stays on this iPhone")
            }
            Button {
                exportJSON()
            } label: {
                settingsRow(icon: "square.and.arrow.up.fill", title: "Export data (JSON)",
                            subtitle: "Viewings, scores, weights — no photos")
            }
            .buttonStyle(.plain)
        }
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legal")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)
            NavigationLink(value: "legal.privacyPolicy") {
                settingsRow(icon: "doc.text.fill", title: "Privacy Policy", subtitle: nil)
            }
            NavigationLink(value: "legal.userAgreement") {
                settingsRow(icon: "doc.plaintext.fill", title: "User Agreement", subtitle: nil)
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)
            HStack {
                Image(systemName: "house.fill")
                    .foregroundStyle(Theme.accentBrass)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TourWise")
                        .font(Theme.body().weight(.medium))
                        .foregroundStyle(Theme.inkPrimary)
                    Text("Version 1.0 · your evidence board")
                        .font(Theme.caption())
                        .foregroundStyle(Theme.inkTertiary)
                }
                Spacer()
            }
            .padding(12)
            .panelCard()
        }
    }

    private func settingsRow(icon: String, title: String, subtitle: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accentBrass)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.body().weight(.medium))
                    .foregroundStyle(Theme.inkPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.caption())
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkTertiary)
        }
        .padding(12)
        .panelCard()
        .accessibilityElement(children: .combine)
    }

    /// Local JSON export of the data model (photos excluded — paths only).
    private func exportJSON() {
        struct ExportPayload: Codable {
            var viewings: [Viewing]
            var roomNotes: [RoomNote]
            var criteria: [Criterion]
            var weightProfiles: [WeightProfile]
            var ledger: ExportCreditLedger
            var exportRecords: [ExportRecord]
            var exportedAt: Date
        }
        let payload = ExportPayload(viewings: store.viewings, roomNotes: store.roomNotes,
                                    criteria: store.criteria, weightProfiles: store.weightProfiles,
                                    ledger: store.ledger, exportRecords: store.exportRecords,
                                    exportedAt: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("tourwise-export.json")
        try? data.write(to: url)
        shareItems = [url]
        showingShare = true
    }
}

// MARK: - privacy route (B10)

/// privacy route: data boundary statement, live permission status, Delete All
/// Data with double confirmation. No Settings jumps — status is informational.
struct PrivacyView: View {
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var permissions: PermissionCenter
    @Environment(\.dismiss) private var dismiss
    @State private var showingFirstConfirm = false
    @State private var showingSecondConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                boundaryCard
                permissionsCard
                deleteCard
            }
            .padding(16)
        }
        .paperBackground()
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { permissions.refreshAll() }
        .confirmationDialog("Delete all TourWise data?", isPresented: $showingFirstConfirm, titleVisibility: .visible) {
            Button("Continue", role: .destructive) { showingSecondConfirm = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every viewing, room score, photo, weight profile, and credit ledger from this iPhone.")
        }
        .confirmationDialog("Are you sure? This can't be undone.", isPresented: $showingSecondConfirm, titleVisibility: .visible) {
            Button("Delete All Data", role: .destructive) {
                store.deleteAllData()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var boundaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Data boundary", systemImage: "lock.shield.fill")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)
            Text("All TourWise data — viewings, room scores, evidence photos, weight profiles, and your credit ledger — lives only on this iPhone. There is no account, no sync, no analytics, and no tracking. Nothing leaves the device except exports you explicitly share.")
                .font(Theme.body())
                .foregroundStyle(Theme.inkSecondary)
            Text("TourWise never uses the microphone and never asks for tracking permission — those features don't exist in this app.")
                .font(Theme.caption())
                .foregroundStyle(Theme.inkTertiary)
        }
        .padding(14)
        .panelCard()
    }

    private var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Permissions")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.inkPrimary)
            permissionRow(icon: "camera.fill", name: "Camera",
                          detail: "Attaches evidence photos to the room you are scoring",
                          state: permissions.cameraState)
            permissionRow(icon: "photo.on.rectangle", name: "Photo Library (read)",
                          detail: "Lets you attach existing photos to room scores",
                          state: permissions.photosReadState)
            permissionRow(icon: "photo.badge.plus", name: "Photo Library (add)",
                          detail: "Saves your verdict card so you can share it",
                          state: permissions.photosAddState)
            Text("Permissions are asked only at the moment you use them. If you decline, every task keeps working with in-app alternatives.")
                .font(Theme.caption())
                .foregroundStyle(Theme.inkTertiary)
        }
        .padding(14)
        .panelCard()
    }

    private func permissionRow(icon: String, name: String, detail: String, state: PermissionCenter.AccessState) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accentBrass)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(Theme.body().weight(.medium))
                    .foregroundStyle(Theme.inkPrimary)
                Text(detail)
                    .font(Theme.caption())
                    .foregroundStyle(Theme.inkTertiary)
            }
            Spacer()
            Text(stateLabel(state))
                .font(Theme.caption().weight(.semibold))
                .foregroundStyle(stateColor(state))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(stateColor(state).opacity(0.12))
                .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
    }

    private func stateLabel(_ state: PermissionCenter.AccessState) -> String {
        switch state {
        case .authorized: return "On"
        case .limited: return "Limited"
        case .notDetermined: return "Not asked"
        case .denied: return "Off"
        case .restricted: return "Restricted"
        case .unavailable: return "No hardware"
        }
    }

    private func stateColor(_ state: PermissionCenter.AccessState) -> Color {
        switch state {
        case .authorized, .limited: return Theme.accentSage
        case .notDetermined: return Theme.inkTertiary
        case .denied, .restricted: return Theme.warnTerracotta
        case .unavailable: return Theme.inkTertiary
        }
    }

    private var deleteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Delete All Data")
                .font(Theme.sectionTitle())
                .foregroundStyle(Theme.warnTerracotta)
            Text("Removes every viewing, score, photo, profile, and credit record from this iPhone. You'll confirm twice.")
                .font(Theme.caption())
                .foregroundStyle(Theme.inkSecondary)
            Button(role: .destructive) { showingFirstConfirm = true } label: {
                Text("Delete All Data…")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.warnTerracotta)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .accessibilityLabel("Delete All Data")
        }
        .padding(14)
        .panelCard()
    }
}

// MARK: - Legal WebView (A10)

/// In-app legal WebView with a friendly failure state and Retry. Two distinct
/// HTTPS documents back the two Settings entries.
struct LegalWebView: View {
    let title: String
    let url: URL

    @State private var loadFailed = false
    @State private var reloadToken = UUID()

    var body: some View {
        ZStack {
            Theme.bgPaper.ignoresSafeArea()
            WebViewRepresentable(url: url, loadFailed: $loadFailed, reloadToken: reloadToken)
                .opacity(loadFailed ? 0 : 1)
            if loadFailed {
                VStack(spacing: 14) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.inkTertiary)
                    Text("Couldn't load this page.")
                        .font(Theme.sectionTitle())
                        .foregroundStyle(Theme.inkPrimary)
                    Text("Check your connection and try again. \(title) is also available on your next visit.")
                        .font(Theme.body())
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Retry") {
                        loadFailed = false
                        reloadToken = UUID()
                    }
                    .font(Theme.body().weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Theme.accentBrass)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var loadFailed: Bool
    let reloadToken: UUID

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastReloadToken != reloadToken {
            context.coordinator.lastReloadToken = reloadToken
            webView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(loadFailed: $loadFailed) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var loadFailed: Bool
        var lastReloadToken: UUID?

        init(loadFailed: Binding<Bool>) {
            _loadFailed = loadFailed
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            loadFailed = true
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            loadFailed = true
        }
    }
}

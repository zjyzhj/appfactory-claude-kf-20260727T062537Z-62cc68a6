import Foundation
import Photos
import UIKit
import AVFoundation

/// Permission boundary center (PM ai-and-privacy.md): Camera / Photo read /
/// Photo add — all just-in-time, all recoverable in-app. There is intentionally
/// NO "Open Settings" path anywhere in this product: denial keeps the user
/// inside the current task with alternative actions.
///
/// Simulator capture substitute seam (checklist A12): when the launch argument
/// `-syntheticCapture` or env `TOURWISE_SYNTHETIC_CAPTURE=1` is present, the
/// camera flow resolves to a deterministic synthetic photo so UI tests can walk
/// the granted capture → bind-to-RoomNote journey without camera hardware.
@MainActor
final class PermissionCenter: ObservableObject {
    static let shared = PermissionCenter()

    enum AccessState: String {
        case notDetermined, authorized, limited, denied, restricted, unavailable
    }

    @Published private(set) var cameraState: AccessState = .notDetermined
    @Published private(set) var photosReadState: AccessState = .notDetermined
    @Published private(set) var photosAddState: AccessState = .notDetermined

    private init() {
        refreshAll()
    }

    // MARK: - Synthetic capture seam

    nonisolated static var syntheticCaptureEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-syntheticCapture")
            || ProcessInfo.processInfo.environment["TOURWISE_SYNTHETIC_CAPTURE"] == "1"
    }

    var cameraHardwareAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    /// Take Photo stays visible when hardware exists OR the synthetic seam is
    /// injected; otherwise room_capture takes the camera_unavailable branch.
    var takePhotoAvailable: Bool {
        cameraHardwareAvailable || Self.syntheticCaptureEnabled
    }

    // MARK: - Refresh

    func refreshAll() {
        refreshCamera()
        refreshPhotosRead()
        refreshPhotosAdd()
    }

    func refreshCamera() {
        if Self.syntheticCaptureEnabled {
            cameraState = .authorized // seam resolves capture deterministically
            return
        }
        guard cameraHardwareAvailable else {
            cameraState = .unavailable
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: cameraState = .authorized
        case .notDetermined: cameraState = .notDetermined
        case .denied: cameraState = .denied
        case .restricted: cameraState = .restricted
        @unknown default: cameraState = .denied
        }
    }

    func refreshPhotosRead() {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized: photosReadState = .authorized
        case .limited: photosReadState = .limited
        case .notDetermined: photosReadState = .notDetermined
        case .denied: photosReadState = .denied
        case .restricted: photosReadState = .restricted
        @unknown default: photosReadState = .denied
        }
    }

    func refreshPhotosAdd() {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized: photosAddState = .authorized
        case .limited: photosAddState = .limited
        case .notDetermined: photosAddState = .notDetermined
        case .denied: photosAddState = .denied
        case .restricted: photosAddState = .restricted
        @unknown default: photosAddState = .denied
        }
    }

    // MARK: - Just-in-time requests

    /// Called only from room_capture "Take Photo". Returns true when capture may proceed.
    func requestCameraAccessIfNeeded() async -> Bool {
        if Self.syntheticCaptureEnabled { return true }
        refreshCamera()
        switch cameraState {
        case .authorized: return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            refreshCamera()
            return granted
        case .denied, .restricted, .limited, .unavailable:
            return false
        }
    }

    /// Called only from room_capture "Choose Photo". Returns true when the picker may show.
    func requestPhotosReadIfNeeded() async -> Bool {
        refreshPhotosRead()
        switch photosReadState {
        case .authorized, .limited: return true
        case .notDetermined:
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            refreshPhotosRead()
            return photosReadState == .authorized || photosReadState == .limited
        case .denied, .restricted, .unavailable:
            return false
        }
    }

    /// Called only from verdict_card "Save to Photos". Returns true when saving may proceed.
    func requestPhotosAddIfNeeded() async -> Bool {
        refreshPhotosAdd()
        switch photosAddState {
        case .authorized, .limited: return true
        case .notDetermined:
            _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            refreshPhotosAdd()
            return photosAddState == .authorized || photosAddState == .limited
        case .denied, .restricted, .unavailable:
            return false
        }
    }

    // MARK: - Photo writes

    enum PhotoSaveError: Error { case notAuthorized, saveFailed }

    /// Writes the rendered verdict card into the user's library (add-only).
    func saveVerdictImageToPhotos(pngData: Data) async throws {
        guard await requestPhotosAddIfNeeded() else { throw PhotoSaveError.notAuthorized }
        guard let image = UIImage(data: pngData) else { throw PhotoSaveError.saveFailed }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: image.pngData() ?? pngData, options: nil)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoSaveError.saveFailed)
                }
            }
        }
    }

    // MARK: - Synthetic capture (deterministic seam media)

    /// Deterministic synthetic evidence photo for the capture seam — a warm
    /// gradient card labelled with the room, so UI-test assertions can read it.
    nonisolated static func syntheticPhoto(roomName: String) -> UIImage {
        let size = CGSize(width: 900, height: 675)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            // Warm paper gradient.
            let colors = [UIColor(red: 0xE9 / 255, green: 0xDF / 255, blue: 0xC9 / 255, alpha: 1).cgColor,
                          UIColor(red: 0xB4 / 255, green: 0x76 / 255, blue: 0x2A / 255, alpha: 1).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            } else {
                UIColor.systemBackground.setFill()
                context.fill(rect)
            }
            // Window-light rectangles for visual texture.
            UIColor.white.withAlphaComponent(0.35).setFill()
            context.fill(CGRect(x: 60, y: 60, width: 260, height: 360))
            UIColor.white.withAlphaComponent(0.22).setFill()
            context.fill(CGRect(x: 380, y: 120, width: 200, height: 300))
            // Label.
            let label = "SYNTHETIC EVIDENCE — \(roomName.uppercased())"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 34, weight: .bold),
                .foregroundColor: UIColor(red: 0x2B / 255, green: 0x26 / 255, blue: 0x20 / 255, alpha: 1),
            ]
            label.draw(in: CGRect(x: 60, y: size.height - 120, width: size.width - 120, height: 60), withAttributes: attributes)
        }
    }
}

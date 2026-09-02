import Foundation
import UIKit
import AudioToolbox

// MARK: - Feedback helpers (toasts, haptics, system sounds)

extension GameViewModel {
    func showToast(_ text: String) {
        toastWorkItem?.cancel()
        toastMessage = text
        let work = DispatchWorkItem { [weak self] in self?.toastMessage = nil }
        toastWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }

    func hapticPlay() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func hapticError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func hapticSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Short, non-intrusive feedback using built-in iOS system sound IDs — no bundled
    /// audio assets required, keeping the project free of binary sound files.
    private func playSystemSound(_ id: UInt32) {
        AudioServicesPlaySystemSound(SystemSoundID(id))
    }

    func playCardSound() { playSystemSound(1104) }
    func playDrawSound() { playSystemSound(1103) }
    func playWinSound() { playSystemSound(1025) }
}

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
    /// audio assets required, keeping the project free of binary sound files. Respects the
    /// Settings sound toggle; haptics are unaffected since they aren't audible to others.
    private func playSystemSound(_ id: UInt32) {
        guard settings?.soundEnabled ?? true else { return }
        AudioServicesPlaySystemSound(SystemSoundID(id))
    }

    // 1104/1103 were the iOS keyboard-click "Tock" sounds — sharp and repetitive when a card
    // plays or draws every couple of seconds. Tink (1057) and a soft pop (1075) read as light UI
    // feedback instead of typing.
    func playCardSound() { playSystemSound(1057) }
    func playDrawSound() { playSystemSound(1075) }
    func playWinSound() { playSystemSound(1025) }
}

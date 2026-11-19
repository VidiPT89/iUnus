import SwiftUI
import UIKit

/// Wait for the host to join a window before presenting GameKit's authentication UI.
struct GameKitViewControllerPresenter: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> HostController {
        let host = HostController()
        host.pendingController = viewController
        return host
    }

    func updateUIViewController(_ host: HostController, context: Context) {
        host.pendingController = viewController
        host.presentIfReady()
    }

    static func dismantleUIViewController(_ host: HostController, coordinator: ()) {
        host.pendingController = nil
        host.dismiss(animated: false)
    }

    final class HostController: UIViewController {
        var pendingController: UIViewController?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            presentIfReady()
        }

        func presentIfReady() {
            guard viewIfLoaded?.window != nil, presentedViewController == nil,
                  let pendingController, pendingController.presentingViewController == nil else { return }
            present(pendingController, animated: true)
        }
    }
}

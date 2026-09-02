import SwiftUI
import UIKit

/// Presents a UIKit view controller handed to us by GameKit (auth sheet, matchmaker) modally
/// over an otherwise-invisible host controller, since GameKit's own view controllers are not
/// SwiftUI-native and don't come wrapped for direct embedding.
struct GameKitViewControllerPresenter: UIViewControllerRepresentable {
    let viewController: UIViewController
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard uiViewController.presentedViewController == nil else { return }
        uiViewController.present(viewController, animated: true)
    }
}

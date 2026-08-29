//
//  LoadingDialog.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import SwiftUI
import UIKit

// UIViewControllerRepresentable for the loading dialog
struct NativeLoadingDialog: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let message: String?

    class Coordinator: NSObject {
        var parent: NativeLoadingDialog

        init(parent: NativeLoadingDialog) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = LoadingViewController(message: message)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let loadingVC = uiViewController as? LoadingViewController {
            loadingVC.updateMessage(message)
            if isPresented {
                loadingVC.startAnimating()
            } else {
                loadingVC.dismiss(animated: true)
            }
        }
    }
}

// UIKit view controller for the loading dialog
class LoadingViewController: UIViewController {
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    private let message: String?

    init(message: String?) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        let dialogView = UIView()
        dialogView.backgroundColor = UIColor.systemBackground
        dialogView.layer.cornerRadius = 12
        dialogView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dialogView)

        activityIndicator.color = .gray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        dialogView.addSubview(activityIndicator)

        messageLabel.text = message
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        if message != nil {
            dialogView.addSubview(messageLabel)
        }

        // Constraints
        NSLayoutConstraint.activate([
            dialogView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dialogView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dialogView.widthAnchor.constraint(equalToConstant: 120),
            dialogView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),

            activityIndicator.centerXAnchor.constraint(equalTo: dialogView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: dialogView.topAnchor, constant: 20),

            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: dialogView.bottomAnchor, constant: -20)
        ])

        // Adjust dialog width for longer messages
        if message != nil {
            dialogView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8).isActive = true
        }
    }

    func startAnimating() {
        activityIndicator.startAnimating()
    }

    func updateMessage(_ message: String?) {
        messageLabel.text = message
    }
}

// SwiftUI View Modifier to present the dialog
struct LoadingDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String?

    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                NativeLoadingDialog(isPresented: $isPresented, message: message)
                    .ignoresSafeArea() // Explicitly ignore safe areas
            }
        }
    }
}

// Extension for easier usage
extension View {
    func loadingDialog(isPresented: Binding<Bool>, message: String? = nil) -> some View {
        self.modifier(LoadingDialogModifier(isPresented: isPresented, message: message))
    }
}

// Example usage
struct NativeLoadingDialog_Previews: PreviewProvider {
    static var previews: some View {
        Color.gray.opacity(0.2)
            .loadingDialog(isPresented: .constant(true), message: "Loading...")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

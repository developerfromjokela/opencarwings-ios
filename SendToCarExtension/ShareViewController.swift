//
//  ShareViewController.swift
//  SendToCarExtension
//
//  Created by Ruben Mkrtumyan on 28.8.2025.
//

import UIKit
import UniformTypeIdentifiers
import MobileCoreServices
import KeychainAccess
import Get
import RestAPI


class ShareViewController: UIViewController {
        
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ensure access to extensionItem and itemProvider
        guard
            let extensionItem = extensionContext?.inputItems.last as? NSExtensionItem else {
            close()
            return
        }
        
        setupView()
        
        var refreshToken = (try? KeychainConfig.keychain().get("ocw_refresh_token")) ?? ""
        var username = (try? KeychainConfig.keychain().get("ocw_username")) ?? ""
        var accessToken = (try? KeychainConfig.keychain().get("ocw_access_token")) ?? ""
        var serverUrl: String = (try? KeychainConfig.keychain().get("ocw_server")) ?? "https://opencarwings.viaaq.eu"
        var lastActiveCar = (try? KeychainConfig.keychain().get("last_active_car")) ?? ""
        
        if refreshToken.isEmpty {
            showAlert(message: NSLocalizedString("Please sign in before using this function", comment: ""))
            return
        }
        
        Task {
            
            var urlAddress: URL? = nil
            
            for file in extensionItem.attachments ?? [] {
                // Try to determine the primary type
                let typeIdentifiers = file.registeredTypeIdentifiers
                let preferredTypes = [
                    UTType.text.identifier,
                    UTType.plainText.identifier,
                    UTType.url.identifier
                ]
                
                // Find the first matching supported type
                let matchingType = preferredTypes.first { type in
                    typeIdentifiers.contains(type)
                }
                
                guard let selectedType = matchingType else {
                    continue
                }
                                
                let data = try await file.loadItem(forTypeIdentifier: selectedType, options: nil)
                
                // Handle different types of content
                switch selectedType {
                    
                case UTType.url.identifier:
                    if let url = data as? URL {
                        urlAddress = url
                        break
                    }
                    break
                    
                case UTType.text.identifier, UTType.plainText.identifier:
                    if let text = data as? String {
                        let types: NSTextCheckingResult.CheckingType = .link

                        let detector = try? NSDataDetector(types: types.rawValue)

                        guard let detect = detector else {
                           break
                        }

                        let matches = detect.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, text.count))

                        if let firstUri = matches.first?.url {
                            urlAddress = firstUri
                        }
                    } else if let url = data as? URL {
                        do {
                            let text = try String(contentsOf: url)

                            let types: NSTextCheckingResult.CheckingType = .link

                            let detector = try? NSDataDetector(types: types.rawValue)

                            guard let detect = detector else {
                               break
                            }

                            let matches = detect.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, text.count))

                            if let firstUri = matches.first?.url {
                                urlAddress = firstUri
                            }

                        } catch {}
                    }
                    break
                
                    
                default:
                    break
                }
                if urlAddress != nil {
                    break
                }
            }
            
            guard let urlAddress = urlAddress else {
                showAlert(message: NSLocalizedString("Nothing to share", comment: ""))
                return
            }
            
            await sendLocationToCar(urlAddress.absoluteString, lastActiveCar, serverUrl, accessToken, refreshToken)
        
        }
        

    }
    
    private func sendLocationToCar(_ url: String, _ lastActiveCar: String, _ serverUrl: String, _ accessToken: String, _ refreshToken: String) async {
        let client = OCWAPIClientFactory.createAPIClient(serverUrl, accessToken)
        
        
        do {
            let carResp: Response<Car> = try await client.send(Paths.api.car.vin(lastActiveCar).get)
                        
            let mapLinkResolveResult: Response<MapLinkResolverResponse> = try await client.send(Paths.api.maplink.resolve.post(MapLinkResolverInput(url: url)))
            
            
            guard let resolvedLocation = mapLinkResolveResult.value.location else {
                showAlert(message: NSLocalizedString("Could not load location information. Please try again later. \(mapLinkResolveResult.value)", comment: ""))
                return
            }
            
            var carToEdit = CarUpdating()
            let locationName: String = resolvedLocation.name ?? NSLocalizedString("Location from phone", comment: "")
            carToEdit.sendToCarLocation = SendToCarLocation(
                id: nil, lat: String(format: "%.9f", resolvedLocation.lat), lon: String(format: "%.9f", resolvedLocation.lon), name: locationName
            )
            
            try await client.send(Paths.api.car.vin(carResp.value.vin).patch(carToEdit))
            showAlert(message: String(format: NSLocalizedString("%@ sent to car!", comment: ""), locationName))
        } catch let e as OCWAPIError {
            let autCheckResult = await SessionHandler.checkAndRenewSession(client, e, refreshToken, accessToken)
            switch autCheckResult {
            case let .ok(newTokenDat):
                let newToken = newTokenDat?.access ?? ""
                let newRefreshToken = newTokenDat?.refresh ?? ""
                try? KeychainConfig.keychain().set(newToken, key: "ocw_access_token")
                try? KeychainConfig.keychain().set(newRefreshToken, key: "ocw_refresh_token")
                await sendLocationToCar(url, lastActiveCar, serverUrl, newToken, refreshToken)
                break
            case let .error(error):
                var errorMsg = "Cannot connect to server. Please try again later."
                errorMsg = "Cannot connect to server. Please try again later.";
                if let apiErr = error as? OCWAPIError {
                    if apiErr.statusCode == 503 {
                        errorMsg = "Server is unavailable. Please try again later.";
                    } else {
                        errorMsg = apiErr.apiError?.detail ?? apiErr.apiError?.error ?? errorMsg
                    }
                }
                showAlert(message: NSLocalizedString(errorMsg, comment: ""))
                break
            case .invalidRefreshToken:
                showAlert(message: NSLocalizedString("Could not load location information. Please try again later.", comment: ""))
                break
            }
        } catch let e {
            print(e)
            showAlert(message: NSLocalizedString("Cannot connect to server. Please try again later.", comment: ""))
        }
    }
    
    private func setupView() {
        view.backgroundColor = .clear
        view.isOpaque = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        // Dialog background
        let dialogView = UIView()
        dialogView.backgroundColor = UIColor.opaqueSeparator
        dialogView.layer.cornerRadius = 12
        dialogView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dialogView)

        // Activity indicator
        activityIndicator.color = .gray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        dialogView.addSubview(activityIndicator)

        // Message label
        messageLabel.text = NSLocalizedString("Sending location to car...", comment: "")
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        dialogView.addSubview(messageLabel)

        // Constraints
        NSLayoutConstraint.activate([
            dialogView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dialogView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dialogView.widthAnchor.constraint(equalToConstant: 160),
            dialogView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),

            activityIndicator.centerXAnchor.constraint(equalTo: dialogView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: dialogView.topAnchor, constant: 20),

            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: dialogView.bottomAnchor, constant: -20)
        ])

        // Adjust dialog width for longer messages
        dialogView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8).isActive = true
        
        activityIndicator.startAnimating()
    }
    
    // Call this after the view is in the hierarchy (important on iOS 26)
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        clearBackgroundHierarchy()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        clearBackgroundHierarchy()   // sometimes needed again after layout
    }

    private func clearBackgroundHierarchy() {
        var theView: UIView? = self.view
        while theView != nil {
            theView?.backgroundColor = .clear
            theView?.isOpaque = false
            theView = theView?.superview
        }
    }
    
    /// Close the Share Extension
    func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    /// Show error alert
    private func showAlert(message: String) {
        let alert = UIAlertController(title: NSLocalizedString("Share location to car", comment: ""), message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel) { _ in
            self.dismiss(animated: true, completion: nil)
            self.close()
        }
        alert.addAction(action)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}

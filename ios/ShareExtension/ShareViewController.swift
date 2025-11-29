import UIKit
import UniformTypeIdentifiers

private let appGroupId = "group.com.example.linkat"
private let pendingLinksKey = "PendingLinks"

class ShareViewController: UIViewController {

    // UI Elements
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let nameTextField = UITextField()
    private let urlLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    // Data
    private var sharedURL: String = ""
    private var originalTitle: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractSharedContent()
    }

    private func setupUI() {
        // Semi-transparent background
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        // Container view (the dialog)
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Title label
        titleLabel.text = "Save Link"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        // Name text field
        nameTextField.placeholder = "Link name"
        nameTextField.borderStyle = .roundedRect
        nameTextField.font = UIFont.systemFont(ofSize: 16)
        nameTextField.backgroundColor = UIColor.secondarySystemBackground
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameTextField)

        // URL label
        urlLabel.font = UIFont.systemFont(ofSize: 13)
        urlLabel.textColor = .secondaryLabel
        urlLabel.numberOfLines = 2
        urlLabel.lineBreakMode = .byTruncatingMiddle
        urlLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(urlLabel)

        // Button container
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonStack)

        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = UIColor.secondarySystemBackground
        cancelButton.setTitleColor(.label, for: .normal)
        cancelButton.layer.cornerRadius = 10
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(cancelButton)

        // Save button
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        saveButton.backgroundColor = UIColor.systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(saveButton)

        // Activity indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(activityIndicator)

        // Constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),

            urlLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 8),
            urlLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            urlLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            buttonStack.topAnchor.constraint(equalTo: urlLabel.bottomAnchor, constant: 24),
            buttonStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 50),

            activityIndicator.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
        ])

        // Tap outside to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    private func extractSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                // Try URL first
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, error in
                        DispatchQueue.main.async {
                            if let url = data as? URL {
                                self?.handleExtractedURL(url.absoluteString)
                            } else if let urlString = data as? String {
                                self?.handleExtractedURL(urlString)
                            }
                        }
                    }
                    return
                }
                // Try plain text
                else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, error in
                        DispatchQueue.main.async {
                            if let text = data as? String {
                                // Try to extract URL from text
                                self?.extractURLFromText(text)
                            }
                        }
                    }
                    return
                }
            }
        }
    }

    private func extractURLFromText(_ text: String) {
        // Try to find a URL in the text
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        if let match = matches?.first, let range = Range(match.range, in: text) {
            let urlString = String(text[range])
            handleExtractedURL(urlString)
        } else if let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
                  url.scheme == "http" || url.scheme == "https" {
            handleExtractedURL(text.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            // No URL found
            urlLabel.text = "No valid URL found"
            saveButton.isEnabled = false
            saveButton.backgroundColor = .systemGray
        }
    }

    private func handleExtractedURL(_ urlString: String) {
        sharedURL = urlString
        urlLabel.text = urlString

        // Extract title from URL or use domain name
        if let url = URL(string: urlString), let host = url.host {
            // Use domain name as default title
            let domain = host.replacingOccurrences(of: "www.", with: "")
            originalTitle = "Link from \(domain)"
            nameTextField.text = originalTitle
        } else {
            originalTitle = "Shared Link"
            nameTextField.text = originalTitle
        }

        // Try to fetch actual page title
        fetchPageTitle(from: urlString)
    }

    private func fetchPageTitle(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  let html = String(data: data, encoding: .utf8) else {
                return
            }

            // Extract title from HTML
            if let titleRange = html.range(of: "<title>"),
               let endRange = html.range(of: "</title>") {
                let title = String(html[titleRange.upperBound..<endRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: " ")

                if !title.isEmpty {
                    DispatchQueue.main.async {
                        self?.originalTitle = title
                        self?.nameTextField.text = title
                    }
                }
            }
        }.resume()
    }

    @objc private func cancelTapped() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    @objc private func saveTapped() {
        guard !sharedURL.isEmpty else { return }

        // Show loading state
        saveButton.setTitle("", for: .normal)
        activityIndicator.startAnimating()
        saveButton.isEnabled = false
        cancelButton.isEnabled = false

        // Get the name (use original if empty)
        let linkName = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? nameTextField.text!
            : originalTitle

        // Save to shared UserDefaults
        saveLinkToSharedStorage(url: sharedURL, name: linkName)

        // Brief delay to show feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showSuccessAndDismiss()
        }
    }

    private func saveLinkToSharedStorage(url: String, name: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            print("ShareExtension Error: Could not access UserDefaults with app group: \(appGroupId)")
            return
        }

        // Create link data
        let linkData: [String: Any] = [
            "url": url,
            "title": name,
            "createdAt": Date().timeIntervalSince1970
        ]

        // Get existing pending links
        var pendingLinks: [[String: Any]] = []
        if let existingJson = userDefaults.string(forKey: pendingLinksKey),
           let existingData = existingJson.data(using: .utf8),
           let existing = try? JSONSerialization.jsonObject(with: existingData) as? [[String: Any]] {
            pendingLinks = existing
        }

        // Add new link
        pendingLinks.append(linkData)

        // Save as JSON string (more reliable across processes)
        if let jsonData = try? JSONSerialization.data(withJSONObject: pendingLinks),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            userDefaults.set(jsonString, forKey: pendingLinksKey)
            userDefaults.synchronize()
            print("ShareExtension: Saved link to UserDefaults - \(jsonString)")
        } else {
            print("ShareExtension Error: Failed to encode JSON")
        }
    }

    private func showSuccessAndDismiss() {
        // Update UI to show success
        activityIndicator.stopAnimating()
        saveButton.setTitle("✓ Saved", for: .normal)
        saveButton.backgroundColor = UIColor.systemGreen

        // Dismiss after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    @objc private func backgroundTapped() {
        // Dismiss keyboard if open
        nameTextField.resignFirstResponder()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ShareViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only handle taps outside the container view
        return !containerView.frame.contains(touch.location(in: view))
    }
}

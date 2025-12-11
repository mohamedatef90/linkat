import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

private let appGroupId = "group.com.example.linkat"
private let pendingLinksKey = "PendingLinks"
private let appURLScheme = "ShareMedia-com.example.linkat://"

class ShareViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Ensure the view is transparent/minimal
        view.backgroundColor = .clear
        extractSharedContent()
    }

    private func extractSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            self.completeRequest()
            return
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                // Try URL first
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, error in
                        if let url = data as? URL {
                            self?.handleExtractedURL(url.absoluteString)
                        } else if let urlString = data as? String {
                            self?.handleExtractedURL(urlString)
                        } else {
                            self?.completeRequest()
                        }
                    }
                    return
                }
                // Try plain text that might contain a URL
                else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, error in
                        if let text = data as? String {
                            self?.extractURLFromText(text)
                        } else {
                            self?.completeRequest()
                        }
                    }
                    return
                }
            }
        }
        
        // If no providers matched immediately
        self.completeRequest()
    }

    private func extractURLFromText(_ text: String) {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        if let match = matches?.first, let range = Range(match.range, in: text) {
            let urlString = String(text[range])
            handleExtractedURL(urlString)
        } else if let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
                  url.scheme == "http" || url.scheme == "https" {
            handleExtractedURL(text.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            completeRequest()
        }
    }

    private func handleExtractedURL(_ urlString: String) {
        // Save URL with placeholder title - the main app will fetch the proper title
        saveLinkToSharedStorage(url: urlString, title: "")

        // Open the main app
        openMainApp()
    }
    
    private func fetchPageTitle(from urlString: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        // Check if we need platform-specific handling
        let host = url.host?.lowercased() ?? ""

        if host.contains("twitter.com") || host.contains("x.com") {
            fetchTwitterMetadata(urlString: urlString, completion: completion)
            return
        }

        if host.contains("youtube.com") || host.contains("youtu.be") {
            fetchYouTubeMetadata(urlString: urlString, completion: completion)
            return
        }

        // For Instagram, Facebook, and general URLs - try fetching with appropriate headers
        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        // Use a bot user-agent to get OG tags (many sites serve better metadata to bots)
        request.setValue("Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }

            // Try OpenGraph title first (most reliable)
            if let ogTitle = self?.extractMetaContent(from: html, property: "og:title"), !ogTitle.isEmpty {
                completion(self?.decodeHTMLEntities(ogTitle))
                return
            }

            // Try Twitter card title
            if let twitterTitle = self?.extractMetaContent(from: html, property: "twitter:title"), !twitterTitle.isEmpty {
                completion(self?.decodeHTMLEntities(twitterTitle))
                return
            }

            // Fall back to <title> tag
            if let title = self?.extractTitleTag(from: html), !title.isEmpty {
                completion(self?.decodeHTMLEntities(title))
                return
            }

            completion(nil)
        }.resume()
    }

    // MARK: - Twitter/X Metadata

    private func fetchTwitterMetadata(urlString: String, completion: @escaping (String?) -> Void) {
        // Try fxtwitter API first (most reliable)
        if let tweetInfo = extractTweetInfo(from: urlString) {
            let apiUrl = "https://api.fxtwitter.com/\(tweetInfo.username)/status/\(tweetInfo.tweetId)"

            guard let url = URL(string: apiUrl) else {
                fetchWithVxTwitter(urlString: urlString, completion: completion)
                return
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = 4
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tweet = json["tweet"] as? [String: Any],
                      let text = tweet["text"] as? String, !text.isEmpty else {
                    // Fallback to vxtwitter
                    self?.fetchWithVxTwitter(urlString: urlString, completion: completion)
                    return
                }

                let title = text.count > 120 ? String(text.prefix(120)) + "..." : text
                completion(title)
            }.resume()
        } else {
            fetchWithVxTwitter(urlString: urlString, completion: completion)
        }
    }

    private func fetchWithVxTwitter(urlString: String, completion: @escaping (String?) -> Void) {
        let vxUrl = urlString
            .replacingOccurrences(of: "twitter.com", with: "vxtwitter.com")
            .replacingOccurrences(of: "x.com", with: "vxtwitter.com")

        guard let url = URL(string: vxUrl) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        request.setValue("Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }

            // Try og:description for tweets (contains the tweet text)
            if let description = self?.extractMetaContent(from: html, property: "og:description"),
               !description.isEmpty {
                let title = description.count > 120 ? String(description.prefix(120)) + "..." : description
                completion(self?.decodeHTMLEntities(title))
                return
            }

            if let ogTitle = self?.extractMetaContent(from: html, property: "og:title"), !ogTitle.isEmpty {
                completion(self?.decodeHTMLEntities(ogTitle))
                return
            }

            completion(nil)
        }.resume()
    }

    private func extractTweetInfo(from urlString: String) -> (username: String, tweetId: String)? {
        guard let url = URL(string: urlString) else { return nil }
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        // Pattern: /username/status/tweetId
        if pathComponents.count >= 3 && pathComponents[1] == "status" {
            let tweetId = pathComponents[2].components(separatedBy: "?").first ?? pathComponents[2]
            return (pathComponents[0], tweetId)
        }
        return nil
    }

    // MARK: - YouTube Metadata

    private func fetchYouTubeMetadata(urlString: String, completion: @escaping (String?) -> Void) {
        guard let videoId = extractYouTubeVideoId(from: urlString) else {
            completion("YouTube Video")
            return
        }

        let oembedUrl = "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=\(videoId)&format=json"

        guard let url = URL(string: oembedUrl) else {
            completion("YouTube Video")
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 4

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let title = json["title"] as? String, !title.isEmpty else {
                completion("YouTube Video")
                return
            }

            completion(title)
        }.resume()
    }

    private func extractYouTubeVideoId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let host = url.host?.lowercased() ?? ""

        // youtube.com/shorts/VIDEO_ID or youtube.com/watch?v=VIDEO_ID
        if host.contains("youtube.com") {
            if url.path.contains("/shorts/") {
                let pathComponents = url.pathComponents
                if let shortsIndex = pathComponents.firstIndex(of: "shorts"),
                   shortsIndex + 1 < pathComponents.count {
                    return pathComponents[shortsIndex + 1].components(separatedBy: "?").first
                }
            }
            // Regular watch URL
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
               let vParam = queryItems.first(where: { $0.name == "v" })?.value {
                return vParam
            }
        }

        // youtu.be/VIDEO_ID
        if host.contains("youtu.be") {
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let videoId = pathComponents.first {
                return videoId.components(separatedBy: "?").first
            }
        }

        return nil
    }

    // MARK: - HTML Parsing Helpers

    private func extractMetaContent(from html: String, property: String) -> String? {
        // Try property attribute first (OpenGraph style)
        let propertyPattern = "<meta[^>]+property=[\"']\(property)[\"'][^>]+content=[\"']([^\"']*)[\"']"
        if let match = html.range(of: propertyPattern, options: .regularExpression) {
            let matchString = String(html[match])
            if let contentMatch = matchString.range(of: "content=[\"']([^\"']*)[\"']", options: .regularExpression) {
                var content = String(matchString[contentMatch])
                content = content.replacingOccurrences(of: "content=\"", with: "")
                    .replacingOccurrences(of: "content='", with: "")
                if content.hasSuffix("\"") || content.hasSuffix("'") {
                    content = String(content.dropLast())
                }
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Try content before property (some sites use this order)
        let reversePattern = "<meta[^>]+content=[\"']([^\"']*)[\"'][^>]+property=[\"']\(property)[\"']"
        if let match = html.range(of: reversePattern, options: .regularExpression) {
            let matchString = String(html[match])
            if let contentMatch = matchString.range(of: "content=[\"']([^\"']*)[\"']", options: .regularExpression) {
                var content = String(matchString[contentMatch])
                content = content.replacingOccurrences(of: "content=\"", with: "")
                    .replacingOccurrences(of: "content='", with: "")
                if content.hasSuffix("\"") || content.hasSuffix("'") {
                    content = String(content.dropLast())
                }
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Try name attribute (Twitter cards style)
        let namePattern = "<meta[^>]+name=[\"']\(property)[\"'][^>]+content=[\"']([^\"']*)[\"']"
        if let match = html.range(of: namePattern, options: .regularExpression) {
            let matchString = String(html[match])
            if let contentMatch = matchString.range(of: "content=[\"']([^\"']*)[\"']", options: .regularExpression) {
                var content = String(matchString[contentMatch])
                content = content.replacingOccurrences(of: "content=\"", with: "")
                    .replacingOccurrences(of: "content='", with: "")
                if content.hasSuffix("\"") || content.hasSuffix("'") {
                    content = String(content.dropLast())
                }
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return nil
    }

    private func extractTitleTag(from html: String) -> String? {
        // Handle both <title> and <title ...>
        guard let startRange = html.range(of: "<title", options: .caseInsensitive) else { return nil }

        // Find the closing > of the opening tag
        guard let tagEndRange = html.range(of: ">", range: startRange.upperBound..<html.endIndex) else { return nil }

        // Find </title>
        guard let endRange = html.range(of: "</title>", options: .caseInsensitive, range: tagEndRange.upperBound..<html.endIndex) else { return nil }

        let title = String(html[tagEndRange.upperBound..<endRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: "")

        return title.isEmpty ? nil : title
    }

    private func decodeHTMLEntities(_ string: String) -> String {
        var result = string

        // Common HTML entities
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&#39;": "'",
            "&nbsp;": " ",
            "&#x27;": "'",
            "&#x2F;": "/",
            "&#x60;": "`",
            "&mdash;": "—",
            "&ndash;": "–",
            "&hellip;": "…",
            "&copy;": "©",
            "&reg;": "®",
            "&trade;": "™",
            "&lsquo;": "\u{2018}",
            "&rsquo;": "\u{2019}",
            "&ldquo;": "\u{201C}",
            "&rdquo;": "\u{201D}",
        ]

        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Handle numeric entities like &#123; or &#x7B;
        // Decimal
        let decimalPattern = "&#(\\d+);"
        if let regex = try? NSRegularExpression(pattern: decimalPattern) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, range: range).reversed()
            for match in matches {
                if let codeRange = Range(match.range(at: 1), in: result),
                   let code = Int(result[codeRange]),
                   let scalar = Unicode.Scalar(code) {
                    let char = String(Character(scalar))
                    if let fullRange = Range(match.range, in: result) {
                        result.replaceSubrange(fullRange, with: char)
                    }
                }
            }
        }

        // Hexadecimal
        let hexPattern = "&#x([0-9a-fA-F]+);"
        if let regex = try? NSRegularExpression(pattern: hexPattern) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, range: range).reversed()
            for match in matches {
                if let codeRange = Range(match.range(at: 1), in: result),
                   let code = Int(result[codeRange], radix: 16),
                   let scalar = Unicode.Scalar(code) {
                    let char = String(Character(scalar))
                    if let fullRange = Range(match.range, in: result) {
                        result.replaceSubrange(fullRange, with: char)
                    }
                }
            }
        }

        return result
    }
    
    private func saveLinkToSharedStorage(url: String, title: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            return
        }

        // Create link data with the fetched title
        let linkData: [String: Any] = [
            "url": url,
            "title": title,
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

        // Save
        if let jsonData = try? JSONSerialization.data(withJSONObject: pendingLinks),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            userDefaults.set(jsonString, forKey: pendingLinksKey)
            userDefaults.synchronize()
        }
    }

    private func openMainApp() {
        guard let url = URL(string: appURLScheme) else {
            completeRequest()
            return
        }
        
        let selector = sel_registerName("openURL:")
        var responder: UIResponder? = self
        
        while let r = responder {
            if r.responds(to: selector) {
                DispatchQueue.main.async {
                    r.perform(selector, with: url)
                }
                break
            }
            responder = r.next
        }
        
        // Close extension
        completeRequest()
    }
    
    private func completeRequest() {
        DispatchQueue.main.async {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}

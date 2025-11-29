import UIKit
import Social
import MobileCoreServices
import WebKit

class ShareViewController: SLComposeServiceViewController {

    // TODO: REPLACE THIS WITH YOUR ACTUAL APP GROUP ID
    let hostAppBundleIdentifier = "group.com.example.linkat"
    let sharedKey = "ShareKey"
    
    var webView: WKWebView?

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return
        }

        for item in extensionItems {
            if let attachments = item.attachments {
                for provider in attachments {
                    if provider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                        provider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { (data, error) in
                            if let url = data as? URL {
                                self.handleUrl(url.absoluteString)
                            }
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                        provider.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil) { (data, error) in
                            if let text = data as? String {
                                self.handleUrl(text)
                            }
                        }
                    }
                }
            }
        }
        
        // Delay completion slightly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    private func handleUrl(_ content: String) {
        // 1. Save to UserDefaults
        if let userDefaults = UserDefaults(suiteName: hostAppBundleIdentifier) {
            userDefaults.set(content, forKey: sharedKey)
            userDefaults.synchronize()
        }
        
        // 2. Open the main app
        let urlString = "ShareMedia://data?path=\(content)"
        if let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) {
            DispatchQueue.main.async {
                self.openURL(url)
            }
        }
    }
    
    private func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                // Advanced: Call open(_:options:completionHandler:) dynamically to bypass deprecation check
                let selector = sel_registerName("open:options:completionHandler:")
                if application.responds(to: selector) {
                    typealias OpenFunction = @convention(c) (AnyObject, Selector, NSURL, NSDictionary, Any?) -> Void
                    let method = class_getMethodImplementation(type(of: application), selector)
                    if let method = method {
                        let open = unsafeBitCast(method, to: OpenFunction.self)
                        open(application, selector, url as NSURL, [:], nil)
                        return
                    }
                }
            }
            responder = responder?.next
        }
        
        // Fallback: WebView
        webView = WKWebView(frame: .zero)
        webView?.load(URLRequest(url: url))
    }

    override func configurationItems() -> [Any]! {
        return []
    }
}

//
//  WebViewContainer.swift
//  GreenEnvelopes
//

import SwiftUI
import WebKit

struct WebViewContainer: View {
    let url: URL
    var onClose: () -> Void

    var body: some View {
        WebView(url: url, onClose: onClose)
            .ignoresSafeArea()
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    var onClose: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onClose: onClose)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "closeHandler")
        let webView = WKWebView(frame: .zero, configuration: config)
        context.coordinator.userContentController = config.userContentController
        context.coordinator.lastLoadedURL = url
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastLoadedURL != url {
            context.coordinator.lastLoadedURL = url
            webView.load(URLRequest(url: url))
        }
    }
}

extension WebView {
    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onClose: () -> Void
        weak var userContentController: WKUserContentController?
        var lastLoadedURL: URL?

        init(onClose: @escaping () -> Void) {
            self.onClose = onClose
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "closeHandler" else { return }
            DispatchQueue.main.async { [weak self] in
                self?.onClose()
            }
        }

        deinit {
            userContentController?.removeScriptMessageHandler(forName: "closeHandler")
        }
    }
}

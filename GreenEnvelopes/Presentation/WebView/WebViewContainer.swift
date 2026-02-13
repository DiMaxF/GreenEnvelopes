//
//  WebViewContainer.swift
//  GreenEnvelopes
//

import SwiftUI
import WebKit

struct WebViewContainer: View {
    let url: URL
    
    var body: some View {
        WebView(url: url)
            .ignoresSafeArea()
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

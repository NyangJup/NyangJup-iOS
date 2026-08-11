//
//  WebView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI
import WebKit

struct WebView: View {
    let url: URL

    @State private var isLoading = true

    var body: some View {
        WebViewRepresentable(
            url: url,
            isLoading: $isLoading
        )
        .overlay {
            if isLoading {
                ProgressView()
                    .controlSize(.large)
            }
        }
    }
}

// MARK: - Representable

private struct WebViewRepresentable: UIViewRepresentable {
    let url: URL

    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))

        return webView
    }

    func updateUIView(
        _ uiView: WKWebView,
        context: Context
    ) {
        guard uiView.url != url else { return }

        uiView.load(URLRequest(url: url))
    }
}

// MARK: - Coordinator

private extension WebViewRepresentable {
    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding private var isLoading: Bool

        init(isLoading: Binding<Bool>) {
            self._isLoading = isLoading
        }

        func webView(
            _ webView: WKWebView,
            didStartProvisionalNavigation navigation: WKNavigation!
        ) {
            isLoading = true
        }

        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            isLoading = false
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            isLoading = false
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            isLoading = false
        }
    }
}

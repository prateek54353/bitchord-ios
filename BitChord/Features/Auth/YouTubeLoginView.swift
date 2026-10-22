import SwiftUI
import WebKit

/// YouTube Music login with manual cookie option
struct YouTubeLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = true
    @State private var onPageReady = false
    @State private var errorMessage = ""
    @State private var coordinator: WebViewCoordinator?
    @State private var showManualEntry = false
    @State private var manualCookie = ""

    private let musicOrigin = "https://music.youtube.com"
    // Use desktop-only login to prevent app redirects
    private let loginURL = "https://accounts.google.com/ServiceLogin?ltmpl=music&service=youtube&passive=true&continue=https%3A%2F%2Fmusic.youtube.com%2F&hl=en"

    var body: some View {
        NavigationView {
            ZStack {
                if showManualEntry {
                    manualCookieEntry
                } else {
                    webViewLogin
                }

                if isLoading {
                    ProgressView("Loading login...")
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                }

                if !errorMessage.isEmpty {
                    VStack {
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            errorMessage = ""
                            isLoading = true
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if onPageReady && !showManualEntry {
                        Button("Confirm") {
                            coordinator?.captureSession()
                        }
                    }
                }
            }
        }
    }

    private var webViewLogin: some View {
        VStack {
            WebView(
                url: URL(string: loginURL)!,
                coordinator: $coordinator,
                onPageReady: { ready in
                    onPageReady = ready
                    isLoading = false
                },
                onSessionCaptured: { session in
                    handleSession(session)
                },
                onError: { error in
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            )

            Divider()

            Button("Use Manual Cookie Entry") {
                showManualEntry = true
            }
            .padding()
        }
    }

    private var manualCookieEntry: some View {
        VStack(spacing: 20) {
            Text("Manual Cookie Entry")
                .font(.headline)

            Text("If automatic login redirects to the YouTube Music app, you can manually enter your cookie.")
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(.secondary)

            Text("To get your cookie:")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("1. Open music.youtube.com in Safari")
                Text("2. Sign in to your account")
                Text("3. Open Safari settings → Privacy → Manage Website Data")
                Text("4. Find music.youtube.com and tap it")
                Text("5. Copy the cookie value")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Text("Paste your cookie below:")
                .font(.caption)

            TextEditor(text: $manualCookie)
                .frame(height: 150)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )

            Button("Save Cookie") {
                saveManualCookie()
            }
            .buttonStyle(.borderedProminent)
            .disabled(manualCookie.isEmpty)

            Button("Use WebView Login") {
                showManualEntry = false
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func handleSession(_ session: CapturedSession) {
        Task {
            await authManager.saveSession(cookie: session.cookie, dataSyncId: session.dataSyncId)
            dismiss()
        }
    }

    private func saveManualCookie() {
        Task {
            await authManager.saveSession(cookie: manualCookie, dataSyncId: nil)
            dismiss()
        }
    }
}

// MARK: - WebView

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var coordinator: WebViewCoordinator?
    let onPageReady: (Bool) -> Void
    let onSessionCaptured: (CapturedSession) -> Void
    let onError: (Error) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        // Force desktop user agent to prevent mobile app redirects
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true

        // Clear cookies for fresh login
        clearCookies(webView: webView)

        let request = URLRequest(url: url)
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> WebViewCoordinator {
        let coord = WebViewCoordinator(
            onPageReady: onPageReady,
            onSessionCaptured: onSessionCaptured,
            onError: onError
        )
        coordinator = coord
        return coord
    }

    private func clearCookies(webView: WKWebView) {
        let dataStore = webView.configuration.websiteDataStore
        dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date.distantPast) {
            // Completion handler
        }
    }
}

class WebViewCoordinator: NSObject, WKNavigationDelegate {
    let onPageReady: (Bool) -> Void
    let onSessionCaptured: (CapturedSession) -> Void
    let onError: (Error) -> Void
    private var webView: WKWebView?

    init(
        onPageReady: @escaping (Bool) -> Void,
        onSessionCaptured: @escaping (CapturedSession) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onPageReady = onPageReady
        self.onSessionCaptured = onSessionCaptured
        self.onError = onError
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView = webView

        // Check if we're on music.youtube.com
        if let url = webView.url {
            onPageReady(url.absoluteString.hasPrefix("https://music.youtube.com"))
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onError(error)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // Block app deep links and external schemes
        let blockedSchemes = ["itms-apps", "youtube", "vnd.youtube", "ymusic", "youtube-music"]
        if blockedSchemes.contains(url.scheme?.lowercased() ?? "") {
            decisionHandler(.cancel)
            return
        }

        // Allow all HTTPS navigation (including app store links but they won't auto-open)
        if url.scheme == "http" || url.scheme == "https" {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }

    func captureSession() {
        guard let webView = webView else { return }
        
        // Get cookies
        let dataStore = webView.configuration.websiteDataStore
        dataStore.httpCookieStore.getAllCookies { cookies in
            let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            
            // Check for SAPISID
            let hasSAPISID = cookies.contains { $0.name == "SAPISID" || $0.name == "__Secure-3PAPISID" }
            
            guard hasSAPISID else {
                self.onError(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No SAPISID cookie found"]))
                return
            }
            
            // Extract ytcfg via JavaScript
            let js = """
            (function() {
                try {
                    if (!window.ytcfg || !window.ytcfg.get) return null;
                    var get = function(key) {
                        var value = window.ytcfg.get(key);
                        return (value === undefined || value === null || value === '') ? null : String(value);
                    };
                    return {
                        loggedIn: String(!!window.ytcfg.get('LOGGED_IN')),
                        pageId: get('DELEGATED_SESSION_ID'),
                        dataSyncId: get('DATASYNC_ID'),
                        authUser: get('SESSION_INDEX'),
                        visitorData: get('VISITOR_DATA'),
                        clientVersion: get('INNERTUBE_CLIENT_VERSION')
                    };
                } catch (e) {
                    return null;
                }
            })()
            """
            
            webView.evaluateJavaScript(js) { result, error in
                if let error = error {
                    self.onError(error)
                    return
                }
                
                guard let dict = result as? [String: Any],
                      let loggedIn = dict["loggedIn"] as? String,
                      loggedIn == "true" else {
                    self.onError(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"]))
                    return
                }
                
                let session = CapturedSession(
                    cookie: cookieHeader,
                    dataSyncId: dict["dataSyncId"] as? String,
                    pageId: dict["pageId"] as? String,
                    authUser: dict["authUser"] as? String,
                    visitorData: dict["visitorData"] as? String,
                    clientVersion: dict["clientVersion"] as? String
                )
                
                self.onSessionCaptured(session)
            }
        }
    }
}

// MARK: - Captured Session

struct CapturedSession {
    let cookie: String
    let dataSyncId: String?
    let pageId: String?
    let authUser: String?
    let visitorData: String?
    let clientVersion: String?
}

// MARK: - Preview

#Preview {
    YouTubeLoginView()
        .environmentObject(AuthManager.shared)
}

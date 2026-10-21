import SwiftUI
import WebKit

/// WebView-based YouTube Music login
/// Matches the Android implementation in YtMusicLoginScreen.kt
struct YouTubeLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = true
    @State private var onPageReady = false
    @State private var errorMessage: String?
    @State private var coordinator: WebViewCoordinator?

    private let musicOrigin = "https://music.youtube.com"
    private let loginURL = "https://accounts.google.com/ServiceLogin?ltmpl=music&service=youtube&prompt=select_account&continue=https%3A%2F%2Fmusic.youtube.com%2F"

    var body: some View {
        NavigationView {
            ZStack {
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

                if isLoading {
                    ProgressView("Loading login...")
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                }

                if let errorMessage = errorMessage {
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
                    if onPageReady {
                        Button("Confirm") {
                            coordinator?.captureSession()
                        }
                    }
                }
            }
        }
    }

    private func handleSession(_ session: CapturedSession) {
        Task {
            await authManager.saveSession(cookie: session.cookie, dataSyncId: session.dataSyncId)
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
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
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
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                dataStore.removeData(ofTypes: [record.recordType], for: [record])
            }
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

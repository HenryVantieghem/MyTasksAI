//
//  WebViewSheet.swift
//  MyTasksAI
//
//  In-app Safari View Controller wrapper
//  For viewing YouTube videos and articles without leaving the app
//

import SwiftUI
import SafariServices

// MARK: - Resource Type
enum ResourceOpenMode {
    case inApp
    case external
}

// MARK: - Web View Sheet
struct WebViewSheet: View {
    let url: URL
    let title: String
    let resourceType: ResourceType
    @Binding var isPresented: Bool

    enum ResourceType {
        case youtube
        case article
        case documentation
        case tool

        var externalButtonTitle: String {
            switch self {
            case .youtube: return "Open in YouTube"
            case .article, .documentation: return "Open in Safari"
            case .tool: return "Open External"
            }
        }

        var externalIcon: String {
            switch self {
            case .youtube: return "play.rectangle.fill"
            case .article, .documentation: return "safari"
            case .tool: return "arrow.up.right.square"
            }
        }
    }

    var body: some View {
        NavigationStack {
            SafariViewRepresentable(url: url)
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            isPresented = false
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            openInExternalApp()
                        } label: {
                            Label(
                                resourceType.externalButtonTitle,
                                systemImage: resourceType.externalIcon
                            )
                        }
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func openInExternalApp() {
        if resourceType == .youtube {
            // Try YouTube app first
            if let videoId = extractYouTubeVideoId(from: url.absoluteString),
               let appURL = URL(string: "youtube://watch?v=\(videoId)"),
               UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL)
                isPresented = false
                return
            }
        }

        // Fall back to Safari
        UIApplication.shared.open(url)
        isPresented = false
    }

    private func extractYouTubeVideoId(from urlString: String) -> String? {
        let patterns = [
            "v=([a-zA-Z0-9_-]{11})",
            "youtu.be/([a-zA-Z0-9_-]{11})",
            "embed/([a-zA-Z0-9_-]{11})",
            "shorts/([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(
                   in: urlString,
                   range: NSRange(urlString.startIndex..., in: urlString)
               ),
               let range = Range(match.range(at: 1), in: urlString) {
                return String(urlString[range])
            }
        }
        return nil
    }
}

// MARK: - Safari View Representable
struct SafariViewRepresentable: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        config.barCollapsingEnabled = true

        let viewController = SFSafariViewController(url: url, configuration: config)
        // iOS 26: preferredControlTintColor and preferredBarTintColor are deprecated
        // System handles tinting automatically for Liquid Glass effects

        return viewController
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Web View Modifier
struct WebViewModifier: ViewModifier {
    @Binding var url: URL?
    let title: String
    let resourceType: WebViewSheet.ResourceType

    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .onChange(of: url) { _, newValue in
                isPresented = newValue != nil
            }
            .sheet(isPresented: $isPresented) {
                if let url {
                    WebViewSheet(
                        url: url,
                        title: title,
                        resourceType: resourceType,
                        isPresented: $isPresented
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
    }
}

extension View {
    /// Present a web view sheet when URL is set
    func webViewSheet(
        url: Binding<URL?>,
        title: String = "Resource",
        resourceType: WebViewSheet.ResourceType = .article
    ) -> some View {
        modifier(WebViewModifier(
            url: url,
            title: title,
            resourceType: resourceType
        ))
    }
}

// MARK: - YouTube Thumbnail Helper
struct YouTubeThumbnail {
    static func thumbnailURL(for videoId: String, quality: Quality = .medium) -> URL? {
        URL(string: "https://img.youtube.com/vi/\(videoId)/\(quality.rawValue).jpg")
    }

    enum Quality: String {
        case small = "default"          // 120x90
        case medium = "mqdefault"       // 320x180
        case high = "hqdefault"         // 480x360
        case standard = "sddefault"     // 640x480
        case max = "maxresdefault"      // 1280x720
    }

    static func extractVideoId(from urlString: String) -> String? {
        let patterns = [
            "v=([a-zA-Z0-9_-]{11})",
            "youtu.be/([a-zA-Z0-9_-]{11})",
            "embed/([a-zA-Z0-9_-]{11})",
            "shorts/([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(
                   in: urlString,
                   range: NSRange(urlString.startIndex..., in: urlString)
               ),
               let range = Range(match.range(at: 1), in: urlString) {
                return String(urlString[range])
            }
        }
        return nil
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var isPresented = true

    if let url = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ") {
        WebViewSheet(
            url: url,
            title: "Tutorial Video",
            resourceType: .youtube,
            isPresented: $isPresented
        )
    }
}

import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.appearance = NSAppearance(named: .aqua)
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let iconImage = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = iconImage
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        AppState.shared.appendURLs(urls)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc func showAboutPanel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 4

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11.5),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]

        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]

        let credits = NSMutableAttributedString()
        credits.append(NSAttributedString(string: "Developer: ", attributes: baseAttributes))
        credits.append(NSAttributedString(string: "Sinan Eldem\n", attributes: boldAttributes))

        let webAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11.5),
            .link: URL(string: "https://sinaneldem.tr")!,
            .paragraphStyle: paragraphStyle
        ]
        credits.append(NSAttributedString(string: "https://sinaneldem.tr\n", attributes: webAttr))

        let mailAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11.5),
            .link: URL(string: "mailto:sinan@sinaneldem.tr")!,
            .paragraphStyle: paragraphStyle
        ]
        credits.append(NSAttributedString(string: "sinan@sinaneldem.tr\n\n", attributes: mailAttr))

        credits.append(
            NSAttributedString(
                string: "Free and open source under the MIT License.\nUniversal rewrite of the original Show Hidden Files by GoToes.org.",
                attributes: baseAttributes
            )
        )

        // Name, version and copyright come from Info.plist.
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }
}

@main
struct ShowHiddenFilesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        // Single window; files dropped on the Dock icon arrive via AppDelegate.application(_:open:).
        Window("Show Hidden Files", id: "main") {
            ContentView(appState: appState)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Show Hidden Files") {
                    appDelegate.showAboutPanel()
                }
            }
        }
    }
}

import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var loadedPathsText: String = ""
    @Published var isDropTargeted: Bool = false
    @Published var alertMessage: String?

    var loadedPaths: [String] {
        loadedPathsText
            .components(separatedBy: .newlines)
            // Not trimmed: file names may legitimately start or end with spaces.
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    func appendURLs(_ urls: [URL]) {
        var current = loadedPaths
        for url in urls {
            let path = url.path(percentEncoded: false).hasSuffix("/") && url.path(percentEncoded: false) != "/"
                ? String(url.path(percentEncoded: false).dropLast())
                : url.path(percentEncoded: false)
            if !path.isEmpty && !current.contains(path) {
                current.append(path)
            }
        }
        loadedPathsText = current.joined(separator: "\n")
    }

    func clearList() {
        loadedPathsText = ""
    }

    func showSpecialFiles() {
        do {
            try FileVisibilityService.setSpecialFilesVisible(true)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func hideSpecialFiles() {
        do {
            try FileVisibilityService.setSpecialFilesVisible(false)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func makeLoadedItemsInvisible() {
        let paths = loadedPaths
        guard !paths.isEmpty else { return }
        let errors = FileVisibilityService.setItemsVisibility(paths: paths, visible: false)
        if !errors.isEmpty {
            alertMessage = errors.joined(separator: "\n")
        }
    }

    func makeLoadedItemsVisible() {
        let paths = loadedPaths
        guard !paths.isEmpty else { return }
        let errors = FileVisibilityService.setItemsVisibility(paths: paths, visible: true)
        if !errors.isEmpty {
            alertMessage = errors.joined(separator: "\n")
        }
    }

    func chooseFolders() {
        let panel = NSOpenPanel()
        panel.title = "Choose Folders"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.showsHiddenFiles = true
        panel.treatsFilePackagesAsDirectories = true

        if panel.runModal() == .OK {
            appendURLs(panel.urls)
        }
    }

    func chooseFiles() {
        let panel = NSOpenPanel()
        panel.title = "Choose Files"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.showsHiddenFiles = true
        panel.treatsFilePackagesAsDirectories = true

        if panel.runModal() == .OK {
            appendURLs(panel.urls)
        }
    }
}

/// Classic rounded white macOS push button matching the screenshot.
struct ClassicPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(.black.opacity(0.88))
            .frame(maxWidth: .infinity)
            .frame(height: 25)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(configuration.isPressed ? Color(white: 0.90) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.black.opacity(0.18), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 1, x: 0, y: 0.8)
    }
}

/// Small rectangular joined button used for Add Folders / Add Files / Clear List.
struct SmallJoinedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .regular))
            .foregroundColor(.black.opacity(0.88))
            .padding(.horizontal, 9)
            .frame(height: 19)
            .background(configuration.isPressed ? Color(white: 0.88) : Color(white: 0.97))
            .overlay(
                Rectangle()
                    .stroke(Color(white: 0.62), lineWidth: 1)
            )
    }
}

struct ContentView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section label
            Text("Toggle Between Show / Hide of special Files:")
                .font(.system(size: 12.5, weight: .regular))
                .foregroundColor(.black.opacity(0.88))
                .padding(.leading, 12)
                .padding(.bottom, 5)

            // Top group box
            HStack(spacing: 22) {
                Button("Show Special Files") {
                    appState.showSpecialFiles()
                }
                .buttonStyle(ClassicPillButtonStyle())

                Button("Hide Special Files") {
                    appState.hideSpecialFiles()
                }
                .buttonStyle(ClassicPillButtonStyle())
            }
            .padding(.horizontal, 26)
            .padding(.top, 11)
            .padding(.bottom, 22)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(white: 0.89))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .padding(.bottom, 16)

            // Bottom section label
            Text("Drag Files / Folders into this box to make them invisible:")
                .font(.system(size: 12.5, weight: .regular))
                .foregroundColor(.black.opacity(0.88))
                .padding(.leading, 12)
                .padding(.bottom, 5)

            // Bottom group box
            VStack(spacing: 0) {
                // White drag-and-drop list box + attached small buttons
                VStack(alignment: .trailing, spacing: 0) {
                    DropTextView(
                        text: $appState.loadedPathsText,
                        isTargeted: $appState.isDropTargeted,
                        onDropURLs: { urls in
                            appState.appendURLs(urls)
                        }
                    )
                    .frame(height: 132)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(
                                appState.isDropTargeted ? Color.accentColor : Color.black.opacity(0.08),
                                lineWidth: appState.isDropTargeted ? 2 : 0.5
                            )
                    )

                    HStack(spacing: -1) {
                        Button("Add Folders") {
                            appState.chooseFolders()
                        }
                        .buttonStyle(SmallJoinedButtonStyle())

                        Button("Add Files") {
                            appState.chooseFiles()
                        }
                        .buttonStyle(SmallJoinedButtonStyle())

                        Button("Clear List") {
                            appState.clearList()
                        }
                        .buttonStyle(SmallJoinedButtonStyle())
                    }
                    .offset(y: -1)
                }
                .padding(.horizontal, 19)
                .padding(.top, 11)

                // Action buttons
                VStack(spacing: 11) {
                    Button("Make Loaded Files / Folders Invisible") {
                        appState.makeLoadedItemsInvisible()
                    }
                    .buttonStyle(ClassicPillButtonStyle())

                    Button("Make Loaded Files / Folders Visible") {
                        appState.makeLoadedItemsVisible()
                    }
                    .buttonStyle(ClassicPillButtonStyle())
                }
                .padding(.horizontal, 36)
                .padding(.top, 8)
                .padding(.bottom, 11)
            }
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(white: 0.89))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.horizontal, 15)
        .padding(.top, 7)
        .padding(.bottom, 10)
        .frame(width: 400)
        .background(Color(white: 0.925))
        .preferredColorScheme(.light)
        .alert(
            "Show Hidden Files",
            isPresented: Binding(
                get: { appState.alertMessage != nil },
                set: { if !$0 { appState.alertMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    appState.alertMessage = nil
                }
            },
            message: {
                Text(appState.alertMessage ?? "")
            }
        )
    }
}

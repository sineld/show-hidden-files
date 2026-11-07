import AppKit
import SwiftUI

/// An NSTextView subclass that intercepts file/folder drag-and-drop operations from Finder
/// and forwards the dropped URLs to a callback instead of inserting file attachments.
final class FileDropNSTextView: NSTextView {
    var onDropURLs: (([URL]) -> Void)?
    var onDragStateChange: ((Bool) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        registerForDraggedTypes([.fileURL])
    }

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if hasFileURLs(in: sender.draggingPasteboard) {
            onDragStateChange?(true)
            return .copy
        }
        return []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if hasFileURLs(in: sender.draggingPasteboard) {
            return .copy
        }
        return []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onDragStateChange?(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        onDragStateChange?(false)
        let urls = extractFileURLs(from: sender.draggingPasteboard)
        guard !urls.isEmpty else { return false }
        onDropURLs?(urls)
        return true
    }

    private func hasFileURLs(in pasteboard: NSPasteboard) -> Bool {
        !extractFileURLs(from: pasteboard).isEmpty
    }

    private func extractFileURLs(from pasteboard: NSPasteboard) -> [URL] {
        guard let items = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] else {
            return []
        }
        return items
    }
}

struct DropTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var isTargeted: Bool
    var onDropURLs: ([URL]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .white

        let contentSize = scrollView.contentSize
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(
            containerSize: NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        )
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        let textView = FileDropNSTextView(
            frame: NSRect(origin: .zero, size: contentSize),
            textContainer: textContainer
        )
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: 12)
        textView.textColor = .black
        textView.backgroundColor = .white
        textView.drawsBackground = true
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.delegate = context.coordinator

        textView.onDropURLs = { urls in
            DispatchQueue.main.async {
                self.onDropURLs(urls)
            }
        }
        textView.onDragStateChange = { targeted in
            DispatchQueue.main.async {
                self.isTargeted = targeted
            }
        }

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? FileDropNSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: DropTextView

        init(_ parent: DropTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

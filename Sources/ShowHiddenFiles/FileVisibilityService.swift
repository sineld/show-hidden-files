import AppKit
import Darwin
import Foundation

enum FileVisibilityError: LocalizedError {
    case commandFailed(String)
    case fileNotFound(String)
    case operationFailed(String, String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return message
        case .fileNotFound(let path):
            return "File or folder not found: \(path)"
        case .operationFailed(let path, let reason):
            return "Failed to update '\(path)': \(reason)"
        }
    }
}

struct FileVisibilityService {
    /// Toggles Finder's `AppleShowAllFiles` preference and restarts Finder.
    static func setSpecialFilesVisible(_ visible: Bool) throws {
        let value = visible ? "true" : "false"
        try runProcess(
            executablePath: "/usr/bin/defaults",
            arguments: ["write", "com.apple.finder", "AppleShowAllFiles", "-bool", value]
        )
        // killall exits 1 when Finder isn't running; the setting is already saved, so that's not an error.
        try? runProcess(
            executablePath: "/usr/bin/killall",
            arguments: ["Finder"]
        )
    }

    /// Sets the visibility of each file/folder path in the list.
    /// - Parameters:
    ///   - paths: Array of POSIX paths.
    ///   - visible: `true` to make items visible, `false` to make them invisible.
    /// - Returns: Array of error messages for any paths that failed.
    @discardableResult
    static func setItemsVisibility(paths: [String], visible: Bool) -> [String] {
        var errors: [String] = []

        for path in paths {
            do {
                try setItemVisibility(atPath: path, visible: visible)
                NSWorkspace.shared.noteFileSystemChanged(path)
            } catch {
                errors.append(error.localizedDescription)
            }
        }

        return errors
    }

    private static func setItemVisibility(atPath path: String, visible: Bool) throws {
        // 1. Update BSD UF_HIDDEN flag (same as `chflags -h hidden` / `chflags -h nohidden`).
        // lstat + lchflags act on a symlink itself, never on its target.
        var fileStat = stat()
        guard lstat(path, &fileStat) == 0 else {
            if errno == ENOENT { throw FileVisibilityError.fileNotFound(path) }
            throw FileVisibilityError.operationFailed(path, String(cString: strerror(errno)))
        }
        var newFlags = fileStat.st_flags
        if visible {
            newFlags &= ~UInt32(UF_HIDDEN)
        } else {
            newFlags |= UInt32(UF_HIDDEN)
        }
        if lchflags(path, newFlags) != 0 {
            throw FileVisibilityError.operationFailed(path, String(cString: strerror(errno)))
        }

        // 2. Also update legacy FinderInfo kIsInvisible bit (SetFile -a V / -a v compatibility)
        updateFinderInfoInvisibleBit(atPath: path, invisible: !visible)
    }

    /// Updates or clears the legacy `kIsInvisible` bit (0x40 in byte 8) of `com.apple.FinderInfo`
    /// so files hidden with old `SetFile -a V` can also be made visible again.
    private static func updateFinderInfoInvisibleBit(atPath path: String, invisible: Bool) {
        let attrName = "com.apple.FinderInfo"
        var buffer = [UInt8](repeating: 0, count: 32)
        let size = getxattr(path, attrName, &buffer, buffer.count, 0, XATTR_NOFOLLOW)

        if size == 32 {
            if invisible {
                buffer[8] |= 0x40
            } else {
                buffer[8] &= ~0x40
            }

            let allZero = buffer.allSatisfy { $0 == 0 }
            if allZero {
                removexattr(path, attrName, XATTR_NOFOLLOW)
            } else {
                _ = setxattr(path, attrName, &buffer, 32, 0, XATTR_NOFOLLOW)
            }
        }
    }

    private static func runProcess(executablePath: String, arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: errorData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Command failed"
            throw FileVisibilityError.commandFailed(message)
        }
    }
}

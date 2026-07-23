import AppKit
import Foundation
import UniformTypeIdentifiers

final class InMemoryLog: @unchecked Sendable {
    enum Level: String {
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    static let shared = InMemoryLog()

    private struct Entry {
        let timestamp: String
        let level: Level
        let category: String
        let message: String
    }

    private let lock = NSLock()
    private let maximumEntryCount = 2_000
    private var entries: [Entry] = []

    private let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private init() {}

    func info(_ message: String, category: String) {
        append(level: .info, message: message, category: category)
    }

    func warning(_ message: String, category: String) {
        append(level: .warning, message: message, category: category)
    }

    func error(_ message: String, category: String) {
        append(level: .error, message: message, category: category)
    }

    func exportText() -> String {
        lock.lock()
        let snapshot = entries
        let generatedAt = timestampFormatter.string(from: Date())
        lock.unlock()

        let release = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        let lines = snapshot.map { entry in
            "[\(entry.timestamp)] [\(entry.level.rawValue)] [\(entry.category)] \(entry.message)"
        }

        return ([
            "ContentCam diagnostic log",
            "Version: \(release) (\(build))",
            "Generated: \(generatedAt)",
            "Entries are kept in memory and written to disk only when exported.",
            "Camera frames are never included.",
            ""
        ] + lines).joined(separator: "\n") + "\n"
    }

    private func append(level: Level, message: String, category: String) {
        lock.lock()
        entries.append(
            Entry(
                timestamp: timestampFormatter.string(from: Date()),
                level: level,
                category: normalized(category),
                message: normalized(message)
            )
        )

        if entries.count > maximumEntryCount {
            entries.removeFirst(entries.count - maximumEntryCount)
        }
        lock.unlock()
    }

    private func normalized(_ value: String) -> String {
        value.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }
}

@MainActor
enum ContentCamHelp {
    static func exportLogs() {
        InMemoryLog.shared.info("Log export requested", category: "Help")

        let panel = NSSavePanel()
        panel.title = "Export ContentCam Logs"
        panel.prompt = "Export"
        panel.nameFieldStringValue = defaultLogFileName
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        panel.directoryURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first

        guard panel.runModal() == .OK, let destination = panel.url else {
            InMemoryLog.shared.info("Log export canceled", category: "Help")
            return
        }

        InMemoryLog.shared.info("Log export destination selected", category: "Help")
        let isAccessingDestination = destination.startAccessingSecurityScopedResource()
        defer {
            if isAccessingDestination {
                destination.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try InMemoryLog.shared.exportText().write(
                to: destination,
                atomically: false,
                encoding: .utf8
            )
            InMemoryLog.shared.info("Log export completed", category: "Help")
        } catch {
            InMemoryLog.shared.error("Log export failed: \(error.localizedDescription)", category: "Help")
            showError(message: "ContentCam couldn’t export the log file.\n\n\(error.localizedDescription)")
        }
    }

    private static var defaultLogFileName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return "ContentCam-Logs-\(formatter.string(from: Date())).txt"
    }

    private static func showError(message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "ContentCam"
        alert.informativeText = message
        alert.runModal()
    }
}

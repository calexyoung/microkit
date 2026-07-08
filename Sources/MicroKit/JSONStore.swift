import Foundation
import os

/// Generic single-value JSON persistence with the suite's two hard-won safety
/// properties, generalized from Catch's `ThoughtStore` / Hold's `HoldStorage`:
///
/// 1. **Atomic writes** — a crash mid-save can never leave a half-written file
///    that fails to decode on relaunch.
/// 2. **Corruption backup** — an undecodable file is *moved aside*, never
///    silently overwritten, so the bytes stay recoverable. (Catch's original
///    data-loss bug was a decode failure that let the next save clobber the
///    only copy of every record.)
///
/// Dates use Foundation's default `Double`-based encoding, not ISO8601:
/// ISO8601 truncates sub-second precision, so a persisted-then-reloaded value
/// wouldn't be `Equatable`-equal to the original. Losslessness matters more
/// than timestamp readability in these transient internal files.
///
/// `Value` is a single `Codable` — use `JSONStore<Hold>` for "zero or one" (a
/// missing file means nil) or `JSONStore<[Run]>` for a collection.
public struct JSONStore<Value: Codable>: Sendable {
    private let fileURL: URL
    private let corruptionLabel: String
    private let logger: Logger

    /// - Parameters:
    ///   - fileURL: where the JSON lives. Its parent directory is created if needed.
    ///   - corruptionLabel: prefix for the moved-aside backup file. Defaults to
    ///     the file's base name (e.g. `hold` → `hold-corrupt-<uuid>.json`).
    ///   - subsystem/category: os.Logger identity for diagnosing persist failures.
    public init(
        fileURL: URL,
        corruptionLabel: String? = nil,
        subsystem: String = "com.calexyoung.MicroKit",
        category: String = "JSONStore"
    ) {
        self.fileURL = fileURL
        self.corruptionLabel = corruptionLabel
            ?? fileURL.deletingPathExtension().lastPathComponent
        self.logger = Logger(subsystem: subsystem, category: category)
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    /// The stored value, or nil if there's no file (a fresh install) or the
    /// file was corrupt (in which case it's moved aside first).
    public func load() -> Value? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        do {
            return try JSONCoders.decoder.decode(Value.self, from: data)
        } catch {
            let backup = fileURL.deletingLastPathComponent()
                .appendingPathComponent("\(corruptionLabel)-corrupt-\(UUID().uuidString).json")
            try? FileManager.default.moveItem(at: fileURL, to: backup)
            logger.error(
                "\(fileURL.lastPathComponent, privacy: .public) was undecodable (\(error.localizedDescription, privacy: .public)); moved aside to \(backup.lastPathComponent, privacy: .public)"
            )
            return nil
        }
    }

    /// Atomically replace the stored value.
    public func save(_ value: Value) {
        do {
            let data = try JSONCoders.encoder.encode(value)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error(
                "Failed to persist \(fileURL.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    /// Remove the stored file. Idempotent — clearing when nothing exists is a
    /// no-op, not an error.
    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

/// Shared coders. A generic type can't hold stored static properties, so they
/// live here.
private enum JSONCoders {
    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    static let decoder = JSONDecoder()
}

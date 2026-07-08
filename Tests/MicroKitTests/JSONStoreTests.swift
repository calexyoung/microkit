import XCTest
@testable import MicroKit

final class JSONStoreTests: XCTestCase {
    private var dir: URL!
    private var fileURL: URL { dir.appendingPathComponent("store.json") }

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("microkit-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private struct Sample: Codable, Equatable {
        var id: UUID
        var when: Date
        var text: String
    }

    func testSaveThenLoadRoundTrips() {
        let store = JSONStore<Sample>(fileURL: fileURL)
        let value = Sample(id: UUID(), when: .now, text: "hello")
        store.save(value)
        XCTAssertEqual(JSONStore<Sample>(fileURL: fileURL).load(), value)
    }

    /// The reason we don't use ISO8601: dates must round-trip to the exact same
    /// Double, or Equatable breaks after a reload.
    func testDatesRoundTripLosslessly() {
        let store = JSONStore<Sample>(fileURL: fileURL)
        let when = Date(timeIntervalSinceReferenceDate: 800_123_456.789012)
        let value = Sample(id: UUID(), when: when, text: "x")
        store.save(value)
        let reloaded = JSONStore<Sample>(fileURL: fileURL).load()
        XCTAssertEqual(reloaded?.when.timeIntervalSinceReferenceDate,
                       when.timeIntervalSinceReferenceDate)
    }

    func testNoFileLoadsNil() {
        XCTAssertNil(JSONStore<Sample>(fileURL: fileURL).load())
    }

    func testCorruptFileMovedAsideNotDiscarded() throws {
        try Data("{ not valid json".utf8).write(to: fileURL)
        let loaded = JSONStore<Sample>(fileURL: fileURL).load()
        XCTAssertNil(loaded)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        let contents = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        XCTAssertTrue(contents.contains { $0.lastPathComponent.hasPrefix("store-corrupt-") })
    }

    func testClearRemovesFile() {
        let store = JSONStore<Sample>(fileURL: fileURL)
        store.save(Sample(id: UUID(), when: .now, text: "x"))
        store.clear()
        XCTAssertNil(JSONStore<Sample>(fileURL: fileURL).load())
    }

    func testWorksWithCollectionValue() {
        let store = JSONStore<[Int]>(fileURL: fileURL)
        store.save([1, 2, 3])
        XCTAssertEqual(JSONStore<[Int]>(fileURL: fileURL).load(), [1, 2, 3])
    }

    func testCustomCorruptionLabel() throws {
        let store = JSONStore<Sample>(fileURL: fileURL, corruptionLabel: "runs")
        store.save(Sample(id: UUID(), when: .now, text: "x"))
        try Data("garbage".utf8).write(to: fileURL)  // corrupt it
        _ = JSONStore<Sample>(fileURL: fileURL, corruptionLabel: "runs").load()
        let contents = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        XCTAssertTrue(contents.contains { $0.lastPathComponent.hasPrefix("runs-corrupt-") })
    }
}

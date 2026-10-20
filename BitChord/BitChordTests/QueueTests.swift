import XCTest
@testable import BitChord

final class QueueTests: XCTestCase {
    var playbackManager: PlaybackManager!

    override func setUp() {
        super.setUp()
        playbackManager = PlaybackManager()
    }

    override func tearDown() {
        playbackManager = nil
        super.tearDown()
    }

    // MARK: - Queue Operations

    func testSetQueue() {
        let songs = createTestSongs(count: 5)
        playbackManager.setQueue(songs, startIndex: 0)

        XCTAssertEqual(playbackManager.queue.count, 5)
        XCTAssertEqual(playbackManager.queueIndex, 0)
    }

    func testAddToQueue() {
        let initialSongs = createTestSongs(count: 3)
        playbackManager.setQueue(initialSongs)

        let newSongs = createTestSongs(count: 2, offset: 3)
        playbackManager.addToQueue(newSongs)

        XCTAssertEqual(playbackManager.queue.count, 5)
    }

    func testAddToQueueAtIndex() {
        let initialSongs = createTestSongs(count: 3)
        playbackManager.setQueue(initialSongs)

        let newSong = createTestSongs(count: 1, offset: 3).first!
        playbackManager.addToQueue([newSong], at: 1)

        XCTAssertEqual(playbackManager.queue.count, 4)
        XCTAssertEqual(playbackManager.queue[1].id, newSong.id)
    }

    func testRemoveFromQueue() {
        let songs = createTestSongs(count: 5)
        playbackManager.setQueue(songs)

        playbackManager.removeFromQueue(at: 2)

        XCTAssertEqual(playbackManager.queue.count, 4)
        XCTAssertEqual(playbackManager.queue[2].id, songs[3].id)
    }

    func testRemoveFromQueueAdjustsIndex() {
        let songs = createTestSongs(count: 5)
        playbackManager.setQueue(songs, startIndex: 3)

        playbackManager.removeFromQueue(at: 1)

        XCTAssertEqual(playbackManager.queueIndex, 2)
    }

    func testClearQueue() {
        let songs = createTestSongs(count: 5)
        playbackManager.setQueue(songs)

        playbackManager.clearQueue()

        XCTAssertEqual(playbackManager.queue.count, 0)
        XCTAssertEqual(playbackManager.queueIndex, 0)
    }

    // MARK: - Queue Navigation

    func testNextTrack() {
        let songs = createTestSongs(count: 5)
        playbackManager.setQueue(songs, startIndex: 0)

        playbackManager.next()

        XCTAssertEqual(playbackManager.queueIndex, 1)
    }

    func testNextTrackWrapsAround() {
        let songs = createTestSongs(count: 5)
        playbackManager.setQueue(songs, startIndex: 4)

        playbackManager.next()

        XCTAssertEqual(playbackManager.queueIndex, 0)
    }

    func testPreviousTrack() {
        let songs = createTestSongs(count: 5)
        playbackManager.setQueue(songs, startIndex: 2)

        playbackManager.previous()

        XCTAssertEqual(playbackManager.queueIndex, 1)
    }

    func testPreviousTrackWrapsAround() {
        let songs = createTestSongs(count: 5)
        playbackManager.setQueue(songs, startIndex: 0)

        playbackManager.previous()

        XCTAssertEqual(playbackManager.queueIndex, 4)
    }

    func testPlayAtIndex() {
        let songs = createTestSongs(count: 5)
        playbackManager.setQueue(songs)

        playbackManager.play(at: 3)

        XCTAssertEqual(playbackManager.queueIndex, 3)
    }

    // MARK: - Shuffle

    func testShuffleMode() {
        playbackManager.isShuffled = true
        XCTAssertTrue(playbackManager.isShuffled)

        playbackManager.isShuffled = false
        XCTAssertFalse(playbackManager.isShuffled)
    }

    // MARK: - Helpers

    private func createTestSongs(count: Int, offset: Int = 0) -> [Song] {
        return (0..<count).map { index in
            Song(
                videoId: "video_\(offset + index)",
                title: "Track \(offset + index)",
                artist: "Artist \(offset + index)",
                thumbnailUrl: nil
            )
        }
    }
}

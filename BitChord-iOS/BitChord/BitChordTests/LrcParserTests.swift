import XCTest
@testable import BitChord

final class LrcParserTests: XCTestCase {

    // MARK: - Basic Parsing

    func testParseSimpleLrc() {
        let lrcString = """
        [00:12.50]First line
        [00:15.00]Second line
        [00:18.75]Third line
        """

        let parsed = LrcLyrics.parse(lrcString)

        XCTAssertEqual(parsed.lines.count, 3)
        XCTAssertEqual(parsed.lines[0].text, "First line")
        XCTAssertEqual(parsed.lines[0].startTime, 12.5, accuracy: 0.01)
        XCTAssertEqual(parsed.lines[1].text, "Second line")
        XCTAssertEqual(parsed.lines[1].startTime, 15.0, accuracy: 0.01)
        XCTAssertEqual(parsed.lines[2].text, "Third line")
        XCTAssertEqual(parsed.lines[2].startTime, 18.75, accuracy: 0.01)
    }

    func testParseEmptyLines() {
        let lrcString = """
        [00:12.50]First line

        [00:15.00]Second line

        """

        let parsed = LrcLyrics.parse(lrcString)

        XCTAssertEqual(parsed.lines.count, 2)
    }

    func testParseWithMinutesAndSeconds() {
        let lrcString = """
        [01:23.45]Line with minutes
        """

        let parsed = LrcLyrics.parse(lrcString)

        XCTAssertEqual(parsed.lines.count, 1)
        XCTAssertEqual(parsed.lines[0].startTime, 83.45, accuracy: 0.01)
    }

    func testParseWithInvalidFormat() {
        let lrcString = """
        Invalid line without timestamp
        [invalid]Another invalid line
        """

        let parsed = LrcLyrics.parse(lrcString)

        XCTAssertEqual(parsed.lines.count, 0)
    }

    // MARK: - Edge Cases

    func testParseEmptyString() {
        let lrcString = ""
        let parsed = LrcLyrics.parse(lrcString)

        XCTAssertEqual(parsed.lines.count, 0)
    }

    func testParseOnlyWhitespace() {
        let lrcString = "   \n   \n   "
        let parsed = LrcLyrics.parse(lrcString)

        XCTAssertEqual(parsed.lines.count, 0)
    }

    func testParseWithMilliseconds() {
        let lrcString = """
        [00:12.123]Line with precise timing
        """

        let parsed = LrcLyrics.parse(lrcString)

        XCTAssertEqual(parsed.lines.count, 1)
        XCTAssertEqual(parsed.lines[0].startTime, 12.123, accuracy: 0.001)
    }

    func testParseWithSpecialCharacters() {
        let lrcString = """
        [00:12.50]Line with "quotes" and 'apostrophes'
        [00:15.00]Line with - dashes and / slashes
        """

        let parsed = LrcLyrics.parse(lrcString)

        XCTAssertEqual(parsed.lines.count, 2)
        XCTAssertEqual(parsed.lines[0].text, #"Line with "quotes" and 'apostrophes'"#)
        XCTAssertEqual(parsed.lines[1].text, "Line with - dashes and / slashes")
    }

    // MARK: - Lyrics Model

    func testLyricsActiveLine() {
        let lines = [
            LyricLine(text: "First", startTime: 10.0),
            LyricLine(text: "Second", startTime: 20.0),
            LyricLine(text: "Third", startTime: 30.0)
        ]

        let lyrics = Lyrics(lines: lines, provider: .lrclib, isSynced: true)

        XCTAssertNil(lyrics.activeLine(at: 5.0))
        XCTAssertEqual(lyrics.activeLine(at: 10.0)?.text, "First")
        XCTAssertEqual(lyrics.activeLine(at: 15.0)?.text, "First")
        XCTAssertEqual(lyrics.activeLine(at: 20.0)?.text, "Second")
        XCTAssertEqual(lyrics.activeLine(at: 25.0)?.text, "Second")
        XCTAssertEqual(lyrics.activeLine(at: 30.0)?.text, "Third")
        XCTAssertEqual(lyrics.activeLine(at: 35.0)?.text, "Third")
    }

    func testLyricsWithOffset() {
        let lines = [
            LyricLine(text: "First", startTime: 10.0),
            LyricLine(text: "Second", startTime: 20.0)
        ]

        let lyrics = Lyrics(lines: lines, provider: .lrclib, isSynced: true, offset: 5.0)

        XCTAssertEqual(lyrics.activeLine(at: 5.0)?.text, "First")
        XCTAssertEqual(lyrics.activeLine(at: 15.0)?.text, "Second")
    }

    func testLyricsWordSync() {
        let words = [
            LyricWord(text: "Hello", startTime: 10.0, duration: 0.5),
            LyricWord(text: "World", startTime: 10.5, duration: 0.5)
        ]

        let line = LyricLine(text: "Hello World", startTime: 10.0, duration: 1.0, words: words)

        XCTAssertNotNil(line.words)
        XCTAssertEqual(line.words?.count, 2)
        XCTAssertEqual(line.words?[0].text, "Hello")
        XCTAssertEqual(line.words?[1].text, "World")
    }

    func testLyricsActiveWord() {
        let words = [
            LyricWord(text: "Hello", startTime: 10.0, duration: 0.5),
            LyricWord(text: "World", startTime: 10.5, duration: 0.5)
        ]

        let line = LyricLine(text: "Hello World", startTime: 10.0, duration: 1.0, words: words)
        let lyrics = Lyrics(lines: [line], provider: .lrclib, isSynced: true)

        XCTAssertNil(lyrics.activeWord(at: 9.5))
        XCTAssertEqual(lyrics.activeWord(at: 10.0)?.text, "Hello")
        XCTAssertEqual(lyrics.activeWord(at: 10.25)?.text, "Hello")
        XCTAssertEqual(lyrics.activeWord(at: 10.5)?.text, "World")
        XCTAssertEqual(lyrics.activeWord(at: 10.75)?.text, "World")
        XCTAssertNil(lyrics.activeWord(at: 11.0))
    }
}

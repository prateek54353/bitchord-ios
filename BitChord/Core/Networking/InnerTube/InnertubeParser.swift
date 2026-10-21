import Foundation

/// Null-safe JSON navigation helpers matching Android's `InnertubeParser.kt`
extension Dictionary where Key == String, Value == Any {
    func o(_ key: String) -> [String: Any]? {
        self[key] as? [String: Any]
    }

    func a(_ key: String) -> [[String: Any]]? {
        self[key] as? [[String: Any]]
    }

    func arrayAny(_ key: String) -> [Any]? {
        self[key] as? [Any]
    }

    func s(_ key: String) -> String? {
        self[key] as? String
    }

    func i(_ key: String) -> Int? {
        if let intVal = self[key] as? Int { return intVal }
        if let strVal = self[key] as? String { return Int(strVal) }
        return nil
    }

    func b(_ key: String) -> Bool? {
        self[key] as? Bool
    }
}

/// Parses raw InnerTube JSON responses into BitChord domain models.
/// Ported from `InnertubeParser.kt`.
enum InnertubeParser {

    // MARK: - Text & Thumbnail Helpers

    /// Extracts joined string from a runs array or plain text node
    static func runsText(_ node: [String: Any]?) -> String {
        guard let node = node else { return "" }
        if let simpleText = node.s("text"), !simpleText.isEmpty {
            return simpleText
        }
        if let runs = node.a("runs") {
            return runs.compactMap { $0.s("text") }.joined()
        }
        return ""
    }

    /// Extracts the highest-resolution thumbnail URL
    static func bestThumbnailUrl(_ node: [String: Any]?) -> String? {
        guard let node = node else { return nil }

        // Cases: direct thumbnail object, or wrapped in musicThumbnailRenderer
        let thumbContainer = node.o("musicThumbnailRenderer") ?? node
        let thumbnails = thumbContainer.o("thumbnail")?.a("thumbnails")
            ?? node.a("thumbnails")

        // Pick the last entry (highest resolution)
        guard let last = thumbnails?.last else { return nil }
        var url = last.s("url")
        if let u = url, u.hasPrefix("//") {
            url = "https:" + u
        }
        return url
    }

    // MARK: - Home Feed Parsing

    /// Parses the FEmusic_home browse response
    static func parseHomeFeed(from response: [String: Any]) -> HomeFeed {
        var shelves: [HomeShelf] = []
        var continuationToken: String?

        // Path: contents.singleColumnBrowseResultsRenderer.tabs[0].tabRenderer.content.sectionListRenderer.contents
        let contents = response.o("contents")?
            .o("singleColumnBrowseResultsRenderer")?
            .a("tabs")?.first?
            .o("tabRenderer")?
            .o("content")?
            .o("sectionListRenderer")?
            .a("contents") ?? []

        for section in contents {
            // Check for continuation
            if let token = extractContinuationToken(from: section) {
                continuationToken = token
                continue
            }

            if let shelf = parseShelf(from: section) {
                shelves.append(shelf)
            }
        }

        // Fallback continuation path: sectionListRenderer.continuations
        if continuationToken == nil {
            continuationToken = extractSectionListContinuation(from: response)
        }

        return HomeFeed(shelves: shelves, continuation: continuationToken)
    }

    /// Parses a single shelf (carousel, musicShelf, tastebreaker)
    static func parseShelf(from dict: [String: Any]) -> HomeShelf? {
        let shelfRenderer = dict.o("musicCarouselShelfRenderer")
            ?? dict.o("musicShelfRenderer")
            ?? dict.o("musicTastebreakerShelfRenderer")
            ?? dict.o("musicCardShelfRenderer")

        guard let shelf = shelfRenderer else { return nil }

        // Extract header
        let header = shelf.o("header")?.o("musicCarouselShelfBasicHeaderRenderer")
            ?? shelf.o("header")?.o("musicShelfBasicHeaderRenderer")
        let title = runsText(header?.o("title"))
        let subtitle = runsText(header?.o("strapline"))

        let moreBrowseId = header?.o("title")?
            .a("runs")?.first?
            .o("navigationEndpoint")?
            .o("browseEndpoint")?
            .s("browseId")
        let moreParams = header?.o("title")?
            .a("runs")?.first?
            .o("navigationEndpoint")?
            .o("browseEndpoint")?
            .s("params")

        // Extract items
        let contents = shelf.a("contents") ?? []
        var items: [ShelfItem] = []

        for itemDict in contents {
            if let item = parseTwoRowItem(from: itemDict.o("musicTwoRowItemRenderer")) {
                items.append(item)
            } else if let item = parseResponsiveListItemAsShelfItem(from: itemDict.o("musicResponsiveListItemRenderer")) {
                items.append(item)
            }
        }

        guard !items.isEmpty else { return nil }
        return HomeShelf(
            title: title.isEmpty ? "Featured" : title,
            items: items,
            subtitle: subtitle,
            moreBrowseId: moreBrowseId,
            moreParams: moreParams
        )
    }

    /// Parses a musicTwoRowItemRenderer into a ShelfItem
    static func parseTwoRowItem(from dict: [String: Any]?) -> ShelfItem? {
        guard let dict = dict else { return nil }

        let title = runsText(dict.o("title"))
        let subtitle = runsText(dict.o("subtitle"))
        let thumbnail = bestThumbnailUrl(dict.o("thumbnailRenderer"))

        // Extract navigation endpoint
        let navEndpoint = dict.o("navigationEndpoint")
        let watchEndpoint = navEndpoint?.o("watchEndpoint")
        let browseEndpoint = navEndpoint?.o("browseEndpoint")

        let videoId = watchEndpoint?.s("videoId")
        var browseId = browseEndpoint?.s("browseId")

        // If watchEndpoint has playlistId starting with VL, treat as browseId
        if browseId == nil, let plId = watchEndpoint?.s("playlistId"), plId.hasPrefix("VL") {
            browseId = plId
        }

        guard !title.isEmpty else { return nil }

        return ShelfItem(
            title: title,
            subtitle: subtitle,
            thumbnailUrl: thumbnail,
            videoId: videoId,
            browseId: browseId
        )
    }

    /// Parses a musicResponsiveListItemRenderer into a ShelfItem
    static func parseResponsiveListItemAsShelfItem(from dict: [String: Any]?) -> ShelfItem? {
        guard let dict = dict else { return nil }

        let flexColumns = dict.a("flexColumns") ?? []
        guard !flexColumns.isEmpty else { return nil }

        let title = runsText(flexColumns.first?.o("musicResponsiveFlexColumnRenderer")?.o("text"))
        var subtitle = ""
        if flexColumns.count > 1 {
            subtitle = runsText(flexColumns[1].o("musicResponsiveFlexColumnRenderer")?.o("text"))
        }

        let thumbnail = bestThumbnailUrl(dict.o("thumbnail"))
        let videoId = dict.o("playlistItemData")?.s("videoId")
            ?? dict.o("overlay")?
                .o("musicItemThumbnailOverlayRenderer")?
                .o("content")?
                .o("musicPlayButtonRenderer")?
                .o("playNavigationEndpoint")?
                .o("watchEndpoint")?
                .s("videoId")
        let browseId = dict.o("navigationEndpoint")?.o("browseEndpoint")?.s("browseId")

        guard !title.isEmpty else { return nil }

        return ShelfItem(
            title: title,
            subtitle: subtitle,
            thumbnailUrl: thumbnail,
            videoId: videoId,
            browseId: browseId
        )
    }

    // MARK: - Search Parsing

    /// Parses a search response into heterogenous SearchResult rows
    static func parseSearchResults(from response: [String: Any]) -> [SearchResult] {
        var results: [SearchResult] = []

        // Path: contents.tabbedSearchResultsRenderer.tabs[0].tabRenderer.content.sectionListRenderer.contents
        let contents = response.o("contents")?
            .o("tabbedSearchResultsRenderer")?
            .a("tabs")?.first?
            .o("tabRenderer")?
            .o("content")?
            .o("sectionListRenderer")?
            .a("contents")
            ?? response.o("contents")?
                .o("sectionListRenderer")?
                .a("contents")
            ?? []

        for section in contents {
            // 1. Top result: musicCardShelfRenderer
            if let card = section.o("musicCardShelfRenderer") {
                if let topResult = parseTopResultCard(from: card) {
                    results.append(topResult)
                }
            }

            // 2. Shelf contents: musicShelfRenderer
            if let shelf = section.o("musicShelfRenderer") {
                let items = shelf.a("contents") ?? []
                for itemDict in items {
                    if let row = itemDict.o("musicResponsiveListItemRenderer") {
                        if let parsed = parseSearchRow(from: row) {
                            results.append(parsed)
                        }
                    }
                }
            }
        }

        return results
    }

    /// Parses a top card result (musicCardShelfRenderer)
    private static func parseTopResultCard(from dict: [String: Any]) -> SearchResult? {
        let title = runsText(dict.o("title"))
        let subtitle = runsText(dict.o("subtitle"))
        let thumbnail = bestThumbnailUrl(dict.o("thumbnail"))

        // Extract video ID or browse ID
        let navEndpoint = dict.o("title")?
            .a("runs")?.first?
            .o("navigationEndpoint")
            ?? dict.o("onTap")
        let videoId = navEndpoint?.o("watchEndpoint")?.s("videoId")
            ?? dict.a("buttons")?.first?
                .o("buttonRenderer")?
                .o("navigationEndpoint")?
                .o("watchEndpoint")?
                .s("videoId")
        let browseId = navEndpoint?.o("browseEndpoint")?.s("browseId")

        guard !title.isEmpty else { return nil }

        if let videoId = videoId {
            let song = Song(
                videoId: videoId,
                title: title,
                artist: subtitle,
                thumbnailUrl: thumbnail,
                queueTier: .context
            )
            return .topTrack(song)
        } else if let browseId = browseId {
            let type = inferBrowseType(browseId: browseId, subtitle: subtitle)
            let item = BrowseItem(
                browseId: browseId,
                title: title,
                subtitle: subtitle,
                thumbnailUrl: thumbnail,
                type: type
            )
            return .browse(item)
        }

        return nil
    }

    /// Parses a single row from a search shelf (musicResponsiveListItemRenderer)
    static func parseSearchRow(from dict: [String: Any]) -> SearchResult? {
        let flexColumns = dict.a("flexColumns") ?? []
        guard !flexColumns.isEmpty else { return nil }

        // Column 0 = Title
        let titleNode = flexColumns.first?.o("musicResponsiveFlexColumnRenderer")?.o("text")
        let title = runsText(titleNode)
        guard !title.isEmpty else { return nil }

        // Column 1 = Subtitle / Metadata runs
        let subtitleNode = flexColumns.count > 1
            ? flexColumns[1].o("musicResponsiveFlexColumnRenderer")?.o("text")
            : nil
        let subtitle = runsText(subtitleNode)
        let subtitleRuns = subtitleNode?.a("runs") ?? []

        // Fixed columns: duration
        let fixedColumns = dict.a("fixedColumns") ?? []
        let durationText = runsText(fixedColumns.first?.o("musicResponsiveFlexColumnRenderer")?.o("text"))

        // Thumbnail
        let thumbnail = bestThumbnailUrl(dict.o("thumbnail"))

        // Video ID
        let videoId = dict.o("playlistItemData")?.s("videoId")
            ?? dict.o("overlay")?
                .o("musicItemThumbnailOverlayRenderer")?
                .o("content")?
                .o("musicPlayButtonRenderer")?
                .o("playNavigationEndpoint")?
                .o("watchEndpoint")?
                .s("videoId")
            ?? titleNode?.a("runs")?.first?.o("navigationEndpoint")?.o("watchEndpoint")?.s("videoId")

        // Browse ID
        let browseId = dict.o("navigationEndpoint")?.o("browseEndpoint")?.s("browseId")
            ?? titleNode?.a("runs")?.first?.o("navigationEndpoint")?.o("browseEndpoint")?.s("browseId")

        // Explicit badge check
        let isExplicit = dict.a("badges")?.contains { badge in
            badge.o("musicInlineBadgeRenderer")?
                .o("accessibilityData")?
                .o("accessibilityData")?
                .s("label")?
                .lowercased()
                .contains("explicit") == true
        }

        // Determine if it's a song or browse item
        if let videoId = videoId {
            // Extract artist and album from subtitle runs
            let (artistName, artistId, albumName, albumId) = parseArtistAndAlbum(from: subtitleRuns)
            let song = Song(
                videoId: videoId,
                title: title,
                artist: artistName.isEmpty ? subtitle : artistName,
                thumbnailUrl: thumbnail,
                durationText: durationText.isEmpty ? nil : durationText,
                artistId: artistId,
                albumId: albumId,
                albumName: albumName,
                isExplicit: isExplicit
            )
            return .track(song)
        } else if let browseId = browseId {
            let type = inferBrowseType(browseId: browseId, subtitle: subtitle)
            let item = BrowseItem(
                browseId: browseId,
                title: title,
                subtitle: subtitle,
                thumbnailUrl: thumbnail,
                type: type
            )
            return .browse(item)
        }

        return nil
    }

    // MARK: - Browse Page Parsing

    /// Flattens a browse page response (e.g. category/mood/album) into ShelfItems
    static func parseBrowseItems(from response: [String: Any]) -> [ShelfItem] {
        var items: [ShelfItem] = []

        // 1. Check sectionListRenderer
        let sections = response.o("contents")?
            .o("singleColumnBrowseResultsRenderer")?
            .a("tabs")?.first?
            .o("tabRenderer")?
            .o("content")?
            .o("sectionListRenderer")?
            .a("contents")
            ?? response.o("contents")?
                .o("sectionListRenderer")?
                .a("contents")
            ?? []

        for section in sections {
            if let shelf = parseShelf(from: section) {
                items.append(contentsOf: shelf.items)
            }

            // Grid renderer (common on Moods & Genres)
            if let grid = section.o("gridRenderer") {
                let gridItems = grid.a("items") ?? []
                for itemDict in gridItems {
                    if let item = parseTwoRowItem(from: itemDict.o("musicTwoRowItemRenderer")) {
                        items.append(item)
                    } else if let button = itemDict.o("musicNavigationButtonRenderer") {
                        let title = runsText(button.o("buttonText"))
                        let browseId = button.o("clickCommand")?.o("browseEndpoint")?.s("browseId")
                        let params = button.o("clickCommand")?.o("browseEndpoint")?.s("params")
                        if !title.isEmpty {
                            items.append(ShelfItem(
                                title: title,
                                subtitle: params ?? "",
                                thumbnailUrl: nil,
                                videoId: nil,
                                browseId: browseId
                            ))
                        }
                    }
                }
            }
        }

        return items
    }

    // MARK: - Continuations

    /// Extracts continuation token from a shelf or section item
    static func extractContinuationToken(from dict: [String: Any]) -> String? {
        if let token = dict.o("continuationItemRenderer")?
            .o("continuationEndpoint")?
            .o("continuationCommand")?
            .s("token") {
            return token
        }
        return nil
    }

    /// Extracts continuation token from the sectionListRenderer continuations array
    static func extractSectionListContinuation(from response: [String: Any]) -> String? {
        let continuations = response.o("contents")?
            .o("singleColumnBrowseResultsRenderer")?
            .a("tabs")?.first?
            .o("tabRenderer")?
            .o("content")?
            .o("sectionListRenderer")?
            .a("continuations")

        if let first = continuations?.first {
            return first.o("nextContinuationData")?.s("continuation")
                ?? first.o("reloadContinuationData")?.s("continuation")
        }
        return nil
    }

    // MARK: - Metadata Extraction Helpers

    private static func inferBrowseType(browseId: String, subtitle: String) -> BrowseType {
        let lower = subtitle.lowercased()
        if lower.contains("album") || browseId.hasPrefix("MPREb_") {
            return .album
        }
        if lower.contains("artist") || browseId.hasPrefix("UC") {
            return .artist
        }
        if lower.contains("playlist") || browseId.hasPrefix("VL") || browseId.hasPrefix("PL") {
            return .playlist
        }
        return .other
    }

    private static func parseArtistAndAlbum(
        from runs: [[String: Any]]
    ) -> (artistName: String, artistId: String?, albumName: String?, albumId: String?) {
        var artistName = ""
        var artistId: String?
        var albumName: String?
        var albumId: String?

        for run in runs {
            let text = run.s("text") ?? ""
            if text == " • " || text.isEmpty { continue }

            let browseEndpoint = run.o("navigationEndpoint")?.o("browseEndpoint")
            let browseId = browseEndpoint?.s("browseId")

            if let bId = browseId {
                if bId.hasPrefix("UC") && artistId == nil {
                    artistName = text
                    artistId = bId
                } else if (bId.hasPrefix("MPREb_") || bId.hasPrefix("FEmusic_library_privately_owned_release_detail")) && albumId == nil {
                    albumName = text
                    albumId = bId
                }
            } else if artistName.isEmpty {
                artistName = text
            }
        }

        return (artistName, artistId, albumName, albumId)
    }

    // MARK: - Additional Parser Methods

    /// Parse home feed (shelves only, no continuation)
    static func parseHome(from response: [String: Any]) -> [HomeShelf] {
        let contents = response.o("contents")?
            .o("singleColumnBrowseResultsRenderer")?
            .a("tabs")?.first?
            .o("tabRenderer")?
            .o("content")?
            .o("sectionListRenderer")?
            .a("contents") ?? []

        var shelves: [HomeShelf] = []
        for section in contents {
            if let shelf = parseShelf(from: section) {
                shelves.append(shelf)
            }
        }
        return shelves
    }

    /// Parse home continuation response
    static func parseHomeContinuation(from response: [String: Any]) -> [HomeShelf] {
        let contents = response.o("continuationContents")?
            .o("sectionListContinuation")?
            .a("contents") ?? []

        var shelves: [HomeShelf] = []
        for section in contents {
            if let shelf = parseShelf(from: section) {
                shelves.append(shelf)
            }
        }
        return shelves
    }

    /// Parse search page with continuation
    static func parseSearchPage(from response: [String: Any], includeVideos: Bool) -> (rows: [SearchResult], continuation: String?) {
        let results = parseSearchResults(from: response)
        let continuation = extractSearchContinuation(from: response)

        if !includeVideos {
            let filtered = results.filter { result in
                if case .track(let song) = result {
                    return !song.isVideo
                }
                return true
            }
            return (filtered, continuation)
        }

        return (results, continuation)
    }

    /// Extract search continuation token
    private static func extractSearchContinuation(from response: [String: Any]) -> String? {
        return response.o("contents")?
            .o("sectionListRenderer")?
            .a("continuations")?.first?
            .o("nextContinuationData")?
            .s("continuation")
    }

    /// Parse search suggestions
    static func parseSearchSuggestions(from response: [String: Any]) -> [String] {
        let contents = response.a("contents") ?? []
        var suggestions: [String] = []

        for item in contents {
            if let text = item.o("searchSuggestionRenderer")?.s("suggestion") {
                suggestions.append(text)
            }
        }

        return suggestions
    }

    /// Collect all songs from a browse response (deep traversal)
    static func collectSongsDeep(from response: [String: Any]) -> [Song] {
        var songs: [Song] = []

        let contents = response.o("contents")?
            .o("singleColumnBrowseResultsRenderer")?
            .a("tabs")?.first?
            .o("tabRenderer")?
            .o("content")?
            .o("sectionListRenderer")?
            .a("contents") ?? []

        for section in contents {
            // Parse shelf
            if let shelf = section.o("musicShelfRenderer") {
                let items = shelf.a("contents") ?? []
                for itemDict in items {
                    if let row = itemDict.o("musicResponsiveListItemRenderer") {
                        if let song = parseSongFromResponsiveListItem(from: row) {
                            songs.append(song)
                        }
                    }
                }
            }

            // Parse carousel
            if let carousel = section.o("musicCarouselShelfRenderer") {
                let items = carousel.a("contents") ?? []
                for itemDict in items {
                    if let item = parseTwoRowItem(from: itemDict.o("musicTwoRowItemRenderer")),
                       let videoId = item.videoId {
                        songs.append(Song(
                            videoId: videoId,
                            title: item.title,
                            artist: item.subtitle,
                            thumbnailUrl: item.thumbnailUrl
                        ))
                    }
                }
            }
        }

        return songs.deduplicated(by: \.videoId)
    }

    /// Parse song from musicResponsiveListItemRenderer
    private static func parseSongFromResponsiveListItem(from dict: [String: Any]) -> Song? {
        let flexColumns = dict.a("flexColumns") ?? []
        guard !flexColumns.isEmpty else { return nil }

        let titleNode = flexColumns.first?.o("musicResponsiveFlexColumnRenderer")?.o("text")
        let title = runsText(titleNode)
        guard !title.isEmpty else { return nil }

        let subtitleNode = flexColumns.count > 1
            ? flexColumns[1].o("musicResponsiveFlexColumnRenderer")?.o("text")
            : nil
        let subtitle = runsText(subtitleNode)
        let subtitleRuns = subtitleNode?.a("runs") ?? []

        let fixedColumns = dict.a("fixedColumns") ?? []
        let durationText = runsText(fixedColumns.first?.o("musicResponsiveFlexColumnRenderer")?.o("text"))

        let thumbnail = bestThumbnailUrl(dict.o("thumbnail"))
        let videoId = dict.o("playlistItemData")?.s("videoId")
            ?? dict.o("overlay")?
                .o("musicItemThumbnailOverlayRenderer")?
                .o("content")?
                .o("musicPlayButtonRenderer")?
                .o("playNavigationEndpoint")?
                .o("watchEndpoint")?
                .s("videoId")

        guard let videoId = videoId else { return nil }

        let (artistName, artistId, albumName, albumId) = parseArtistAndAlbum(from: subtitleRuns)

        return Song(
            videoId: videoId,
            title: title,
            artist: artistName.isEmpty ? subtitle : artistName,
            thumbnailUrl: thumbnail,
            durationText: durationText.isEmpty ? nil : durationText,
            artistId: artistId,
            albumId: albumId,
            albumName: albumName
        )
    }

    /// Parse library playlists
    static func parseLibraryPlaylists(from response: [String: Any]) -> [BrowseItem] {
        var items: [BrowseItem] = []

        let contents = response.o("contents")?
            .o("singleColumnBrowseResultsRenderer")?
            .a("tabs")?.first?
            .o("tabRenderer")?
            .o("content")?
            .o("sectionListRenderer")?
            .a("contents") ?? []

        for section in contents {
            if let grid = section.o("gridRenderer") {
                let gridItems = grid.a("items") ?? []
                for itemDict in gridItems {
                    if let item = parseTwoRowItem(from: itemDict.o("musicTwoRowItemRenderer")),
                       let browseId = item.browseId {
                        items.append(BrowseItem(
                            browseId: browseId,
                            title: item.title,
                            subtitle: item.subtitle,
                            thumbnailUrl: item.thumbnailUrl,
                            type: .playlist
                        ))
                    }
                }
            }
        }

        return items
    }

    /// Parse mood and genre sections
    static func parseMoodAndGenres(from response: [String: Any]) -> [MoodGenreSection] {
        var sections: [MoodGenreSection] = []

        let contents = response.o("contents")?
            .o("singleColumnBrowseResultsRenderer")?
            .a("tabs")?.first?
            .o("tabRenderer")?
            .o("content")?
            .o("sectionListRenderer")?
            .a("contents") ?? []

        for section in contents {
            if let header = section.o("musicHeaderRenderer") {
                let title = runsText(header.o("title"))
                let browseItems = parseBrowseItems(from: section).compactMap { item -> BrowseItem? in
                    guard let browseId = item.browseId else { return nil }
                    return BrowseItem(
                        browseId: browseId,
                        title: item.title,
                        subtitle: item.subtitle,
                        thumbnailUrl: item.thumbnailUrl,
                        type: .playlist
                    )
                }

                if !browseItems.isEmpty {
                    sections.append(MoodGenreSection(title: title, items: browseItems))
                }
            }
        }

        return sections
    }

    /// Parse artist page
    static func parseArtistPage(from response: [String: Any]) -> (songs: [Song], albums: [BrowseItem], singles: [BrowseItem]) {
        var songs: [Song] = []
        var albums: [BrowseItem] = []
        var singles: [BrowseItem] = []

        let contents = response.o("contents")?
            .o("singleColumnBrowseResultsRenderer")?
            .a("tabs")?.first?
            .o("tabRenderer")?
            .o("content")?
            .o("sectionListRenderer")?
            .a("contents") ?? []

        for section in contents {
            // Parse songs shelf
            if let shelf = section.o("musicShelfRenderer") {
                let title = runsText(shelf.o("header")?.o("musicShelfBasicHeaderRenderer")?.o("title"))
                let items = shelf.a("contents") ?? []

                if title.localizedCaseInsensitiveContains("song") || title.localizedCaseInsensitiveContains("popular") {
                    for itemDict in items {
                        if let row = itemDict.o("musicResponsiveListItemRenderer") {
                            if let song = parseSongFromResponsiveListItem(from: row) {
                                songs.append(song)
                            }
                        }
                    }
                }
            }

            // Parse albums
            if let grid = section.o("gridRenderer") {
                let title = runsText(grid.o("header")?.o("musicGridHeaderRenderer")?.o("title"))
                let gridItems = grid.a("items") ?? []

                for itemDict in gridItems {
                    if let item = parseTwoRowItem(from: itemDict.o("musicTwoRowItemRenderer")),
                       let browseId = item.browseId {
                        let browseItem = BrowseItem(
                            browseId: browseId,
                            title: item.title,
                            subtitle: item.subtitle,
                            thumbnailUrl: item.thumbnailUrl,
                            type: .album
                        )

                        if title.localizedCaseInsensitiveContains("album") {
                            albums.append(browseItem)
                        } else if title.localizedCaseInsensitiveContains("single") {
                            singles.append(browseItem)
                        }
                    }
                }
            }
        }

        return (songs, albums, singles)
    }

    /// Parse album metadata
    static func parseAlbumMetadata(from response: [String: Any]) -> [String: Any] {
        var metadata: [String: Any] = [:]

        let header = response.o("contents")?
            .o("singleColumnBrowseResultsRenderer")?
            .a("tabs")?.first?
            .o("tabRenderer")?
            .o("content")?
            .o("sectionListRenderer")?
            .a("contents")?.first?
            .o("musicResponsiveHeaderRenderer")

        if let header = header {
            metadata["title"] = runsText(header.o("title"))
            metadata["subtitle"] = runsText(header.o("subtitle"))
            metadata["thumbnail"] = bestThumbnailUrl(header.o("thumbnail"))
        }

        return metadata
    }
}

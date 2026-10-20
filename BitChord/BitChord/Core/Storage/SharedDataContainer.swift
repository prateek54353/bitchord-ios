import Foundation
import SwiftData

@MainActor
let SharedDataContainer = {
    let schema = Schema([
        Song.self,
        UserPlaylist.self,
        BrowseItem.self
    ])

    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false
    )

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()

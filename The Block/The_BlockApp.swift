import SwiftUI

@main
struct The_BlockApp: App {
    @StateObject private var bidStore = BidStore()
    @StateObject private var watchlistStore = WatchlistStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bidStore)
                .environmentObject(watchlistStore)
        }
    }
}

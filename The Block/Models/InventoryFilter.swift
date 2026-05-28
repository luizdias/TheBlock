import Foundation

struct InventoryFilter: Equatable {
    var bodyStyle: String?
    var province: String?
    var onlyWatchlist = false

    var hasActiveFilters: Bool {
        bodyStyle != nil || province != nil || onlyWatchlist
    }
}

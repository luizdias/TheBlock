import Foundation

struct BidSnapshot: Equatable {
    let vehicleID: Vehicle.ID
    let currentBid: Int?
    let bidCount: Int
    let lastBidPlacedAt: Date?

    var hasBids: Bool {
        currentBid != nil
    }
}

import Foundation
import Combine

@MainActor
final class BidStore: ObservableObject {
    enum BidError: LocalizedError, Equatable {
        case amountTooLow(minimum: Int)

        var errorDescription: String? {
            switch self {
            case .amountTooLow(let minimum):
                return "Enter a bid of at least \(CurrencyFormatter.string(from: minimum))."
            }
        }
    }

    // Bids are local-only for this exercise, but centralized state keeps list/detail screens in sync.
    @Published private var snapshots: [Vehicle.ID: BidSnapshot] = [:]

    func snapshot(for vehicle: Vehicle) -> BidSnapshot {
        snapshots[vehicle.id] ?? BidSnapshot(
            vehicleID: vehicle.id,
            currentBid: vehicle.bidding.currentBid,
            bidCount: vehicle.bidding.bidCount,
            lastBidPlacedAt: nil
        )
    }

    func minimumBid(for vehicle: Vehicle) -> Int {
        let currentBid = snapshot(for: vehicle).currentBid ?? vehicle.auction.startingBid
        return currentBid + 100
    }

    @discardableResult
    func placeBid(_ amount: Int, on vehicle: Vehicle) throws -> BidSnapshot {
        let minimum = minimumBid(for: vehicle)
        guard amount >= minimum else {
            throw BidError.amountTooLow(minimum: minimum)
        }

        let existing = snapshot(for: vehicle)
        let updated = BidSnapshot(
            vehicleID: vehicle.id,
            currentBid: amount,
            bidCount: existing.bidCount + 1,
            lastBidPlacedAt: Date()
        )
        snapshots[vehicle.id] = updated
        return updated
    }
}

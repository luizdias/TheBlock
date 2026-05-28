import Foundation
import Combine

@MainActor
final class BidSheetViewModel: ObservableObject {
    enum State: Equatable {
        case editing
        case submitting
        case confirmed
    }

    @Published var bidAmountText: String
    @Published var state: State = .editing
    @Published var validationMessage: String?

    private let vehicle: Vehicle
    private let bidStore: BidStore

    init(vehicle: Vehicle, bidStore: BidStore) {
        self.vehicle = vehicle
        self.bidStore = bidStore
        self.bidAmountText = String(bidStore.minimumBid(for: vehicle))
    }

    var minimumBid: Int {
        bidStore.minimumBid(for: vehicle)
    }

    var canSubmit: Bool {
        state != .submitting && parsedAmount != nil
    }

    func submit() {
        guard let amount = parsedAmount else {
            validationMessage = "Enter a valid whole-dollar bid."
            return
        }

        state = .submitting
        validationMessage = nil

        do {
            try bidStore.placeBid(amount, on: vehicle)
            state = .confirmed
        } catch {
            validationMessage = error.localizedDescription
            state = .editing
        }
    }

    private var parsedAmount: Int? {
        let digits = bidAmountText.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        return Int(digits)
    }
}

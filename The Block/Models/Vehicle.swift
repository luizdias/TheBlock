import Foundation

struct Vehicle: Identifiable, Hashable, Codable {
    let id: UUID
    let lotNumber: String
    let vin: String
    let make: String
    let model: String
    let year: Int
    let trim: String
    let bodyStyle: String
    let exteriorColor: String
    let interiorColor: String
    let specs: Specs
    let condition: Condition
    let auction: Auction
    let location: Location
    let sellingDealership: String
    let images: [URL]
    let bidding: Bidding

    var displayName: String {
        "\(year) \(make) \(model)"
    }

    struct Specs: Hashable, Codable {
        let engine: String
        let transmission: String
        let drivetrain: String
        let fuelType: String
        let odometerKilometers: Int
    }

    struct Condition: Hashable, Codable {
        let grade: Double
        let report: String
        let damageNotes: [String]
        let titleStatus: String
    }

    struct Auction: Hashable, Codable {
        let startingBid: Int
        let reservePrice: Int?
        let buyNowPrice: Int?
        let startTime: Date
    }

    struct Location: Hashable, Codable {
        let city: String
        let province: String

        var displayName: String {
            "\(city), \(province)"
        }
    }

    struct Bidding: Hashable, Codable {
        let currentBid: Int?
        let bidCount: Int
    }
}

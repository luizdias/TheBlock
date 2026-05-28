import Foundation

struct VehicleDTO: Decodable {
    let id: UUID
    let vin: String
    let year: Int
    let make: String
    let model: String
    let trim: String
    let bodyStyle: String
    let exteriorColor: String
    let interiorColor: String
    let engine: String
    let transmission: String
    let drivetrain: String
    let odometerKilometers: Int
    let fuelType: String
    let conditionGrade: Double
    let conditionReport: String
    let damageNotes: [String]
    let titleStatus: String
    let province: String
    let city: String
    let auctionStart: Date
    let startingBid: Int
    let reservePrice: Int?
    let buyNowPrice: Int?
    let images: [URL]
    let sellingDealership: String
    let lot: String
    let currentBid: Int?
    let bidCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case vin
        case year
        case make
        case model
        case trim
        case bodyStyle = "body_style"
        case exteriorColor = "exterior_color"
        case interiorColor = "interior_color"
        case engine
        case transmission
        case drivetrain
        case odometerKilometers = "odometer_km"
        case fuelType = "fuel_type"
        case conditionGrade = "condition_grade"
        case conditionReport = "condition_report"
        case damageNotes = "damage_notes"
        case titleStatus = "title_status"
        case province
        case city
        case auctionStart = "auction_start"
        case startingBid = "starting_bid"
        case reservePrice = "reserve_price"
        case buyNowPrice = "buy_now_price"
        case images
        case sellingDealership = "selling_dealership"
        case lot
        case currentBid = "current_bid"
        case bidCount = "bid_count"
    }

    func toDomain() -> Vehicle {
        // Keep API decoding separate from the app's domain model so JSON changes stay isolated.
        Vehicle(
            id: id,
            lotNumber: lot,
            vin: vin,
            make: make,
            model: model,
            year: year,
            trim: trim,
            bodyStyle: bodyStyle,
            exteriorColor: exteriorColor,
            interiorColor: interiorColor,
            specs: .init(
                engine: engine,
                transmission: transmission,
                drivetrain: drivetrain,
                fuelType: fuelType,
                odometerKilometers: odometerKilometers
            ),
            condition: .init(
                grade: conditionGrade,
                report: conditionReport,
                damageNotes: damageNotes,
                titleStatus: titleStatus
            ),
            auction: .init(
                startingBid: startingBid,
                reservePrice: reservePrice,
                buyNowPrice: buyNowPrice,
                startTime: auctionStart
            ),
            location: .init(city: city, province: province),
            sellingDealership: sellingDealership,
            images: images,
            bidding: .init(currentBid: currentBid, bidCount: bidCount)
        )
    }
}

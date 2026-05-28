import Foundation

nonisolated enum CurrencyFormatter {
    static let short: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static func string(from amount: Int?) -> String {
        guard let amount else { return "No bids" }
        return short.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

nonisolated enum VehicleFormatters {
    static func kilometers(_ value: Int) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter.string(from: Measurement(value: Double(value), unit: UnitLength.kilometers))
    }

    static func titleCase(_ value: String) -> String {
        value.replacingOccurrences(of: "-", with: " ").capitalized
    }

    static func auctionStatus(for date: Date, now: Date = Date()) -> String {
        if date > now {
            return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: now)
        }
        return "Live auction"
    }

    static func dateTime(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}

import Foundation

extension JSONDecoder {
    static var vehicleAPI: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = DateFormatter.vehicleAPIDate.date(from: value) {
                return date
            }

            if let date = ISO8601DateFormatter().date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected ISO-like date string, got \(value)."
            )
        }
        return decoder
    }
}

extension DateFormatter {
    static let vehicleAPIDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = .current
        return formatter
    }()
}

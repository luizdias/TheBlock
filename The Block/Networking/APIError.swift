import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .httpStatus(let statusCode):
            return "The server returned status code \(statusCode)."
        case .decoding(let message):
            return "The inventory response could not be read. \(message)"
        case .transport(let message):
            return "Network request failed. \(message)"
        }
    }
}

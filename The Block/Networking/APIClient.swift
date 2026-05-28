import Foundation

protocol APIClientProtocol {
    func send<Response: Decodable>(_ endpoint: Endpoint<Response>) async throws -> Response
}

struct URLSessionAPIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    // Injecting URLSession and JSONDecoder keeps networking deterministic in tests.
    init(session: URLSession = .shared, decoder: JSONDecoder = .vehicleAPI) {
        self.session = session
        self.decoder = decoder
    }

    func send<Response: Decodable>(_ endpoint: Endpoint<Response>) async throws -> Response {
        do {
            let (data, response) = try await session.data(from: endpoint.url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpStatus(httpResponse.statusCode)
            }

            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw APIError.decoding(error.localizedDescription)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
    }
}

import Foundation

protocol VehicleServiceProtocol {
    func fetchInventory() async throws -> [Vehicle]
}

struct RemoteVehicleService: VehicleServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = URLSessionAPIClient()) {
        self.apiClient = apiClient
    }

    func fetchInventory() async throws -> [Vehicle] {
        let response = try await apiClient.send(Endpoint<[VehicleDTO]>.vehicleInventory)
        return response.map { $0.toDomain() }
    }
}

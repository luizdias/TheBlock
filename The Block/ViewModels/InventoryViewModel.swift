import Foundation
import Combine

@MainActor
final class InventoryViewModel: ObservableObject {
    @Published private(set) var vehicles: [Vehicle] = []
    @Published var loadState: LoadState = .idle
    @Published var searchText = ""
    @Published var filter = InventoryFilter()

    private let vehicleService: VehicleServiceProtocol

    // A protocol dependency lets previews/tests swap the remote service for fixtures.
    init(vehicleService: VehicleServiceProtocol? = nil) {
        self.vehicleService = vehicleService ?? RemoteVehicleService()
    }

    var filteredVehicles: [Vehicle] {
        vehicles.filter { vehicle in
            matchesSearch(vehicle) && matchesFilter(vehicle)
        }
        .sorted { lhs, rhs in
            lhs.auction.startTime < rhs.auction.startTime
        }
    }

    var bodyStyles: [String] {
        uniqueValues(vehicles.map(\.bodyStyle))
    }

    var provinces: [String] {
        uniqueValues(vehicles.map { $0.location.province })
    }

    func loadInventory(forceRefresh: Bool = false) async {
        guard forceRefresh || vehicles.isEmpty else { return }

        loadState = .loading
        do {
            vehicles = try await vehicleService.fetchInventory()
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    private func matchesSearch(_ vehicle: Vehicle) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        return [
            vehicle.displayName,
            vehicle.trim,
            vehicle.vin,
            vehicle.lotNumber,
            vehicle.location.displayName,
            vehicle.sellingDealership
        ]
        .joined(separator: " ")
        .localizedCaseInsensitiveContains(query)
    }

    private func matchesFilter(_ vehicle: Vehicle) -> Bool {
        if let bodyStyle = filter.bodyStyle, vehicle.bodyStyle != bodyStyle {
            return false
        }

        if let province = filter.province, vehicle.location.province != province {
            return false
        }

        return true
    }

    private func uniqueValues(_ values: [String]) -> [String] {
        Array(Set(values)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

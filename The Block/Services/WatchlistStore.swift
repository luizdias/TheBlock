import Foundation
import Combine

@MainActor
final class WatchlistStore: ObservableObject {
    @Published private var watchedVehicleIDs: Set<Vehicle.ID> = []

    func contains(_ vehicle: Vehicle) -> Bool {
        watchedVehicleIDs.contains(vehicle.id)
    }

    func toggle(_ vehicle: Vehicle) {
        if watchedVehicleIDs.contains(vehicle.id) {
            watchedVehicleIDs.remove(vehicle.id)
        } else {
            watchedVehicleIDs.insert(vehicle.id)
        }
    }
}

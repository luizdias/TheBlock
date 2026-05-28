import Foundation

struct Endpoint<Response: Decodable> {
    let url: URL

    static var vehicleInventory: Endpoint<[VehicleDTO]> {
        Endpoint<[VehicleDTO]>(url: URL(string: "https://raw.githubusercontent.com/kar-dmp/the-block/refs/heads/main/data/vehicles.json")!)
    }
}

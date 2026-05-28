import Foundation
import Testing
@testable import The_Block

struct VehicleModelTests {
    @Test func decodesVehicleInventoryShapeAndMapsToDomainModel() throws {
        let vehicle = try TestFixtures.decodedVehicle()

        #expect(vehicle.lotNumber == "A-0001")
        #expect(vehicle.displayName == "2025 Mazda CX-5")
        #expect(vehicle.specs.odometerKilometers == 24_534)
        #expect(vehicle.condition.grade == 4)
        #expect(vehicle.condition.damageNotes.isEmpty)
        #expect(vehicle.auction.reservePrice == 29_000)
        #expect(vehicle.bidding.currentBid == 21_000)
        #expect(vehicle.location.displayName == "Mississauga, Ontario")
        #expect(vehicle.images.count == 1)
    }

    @Test func vehicleAPIDecoderAcceptsISO8601Dates() throws {
        let json = #""2026-04-05T19:00:00Z""#

        let date = try JSONDecoder.vehicleAPI.decode(Date.self, from: Data(json.utf8))

        #expect(ISO8601DateFormatter().string(from: date) == "2026-04-05T19:00:00Z")
    }

    @Test func vehicleAPIDecoderRejectsInvalidDates() {
        let json = #""not-a-date""#

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder.vehicleAPI.decode(Date.self, from: Data(json.utf8))
        }
    }

    @Test func valueObjectsExposeDerivedState() {
        let filter = InventoryFilter(bodyStyle: "SUV", province: nil, onlyWatchlist: false)
        let emptyFilter = InventoryFilter()
        let activeBid = BidSnapshot(vehicleID: UUID(), currentBid: 10_000, bidCount: 3, lastBidPlacedAt: nil)
        let inactiveBid = BidSnapshot(vehicleID: UUID(), currentBid: nil, bidCount: 0, lastBidPlacedAt: nil)

        #expect(filter.hasActiveFilters)
        #expect(!emptyFilter.hasActiveFilters)
        #expect(LoadState.loading.isLoading)
        #expect(!LoadState.loaded.isLoading)
        #expect(activeBid.hasBids)
        #expect(!inactiveBid.hasBids)
    }

    @Test func vehicleDisplayNameCombinesYearMakeModel() {
        let vehicle = TestFixtures.vehicle(make: "Ford", model: "Bronco", year: 2023)
        #expect(vehicle.displayName == "2023 Ford Bronco")
    }

    @Test func vehicleLocationDisplayNameCombinesCityProvince() {
        let vehicle = TestFixtures.vehicle(province: "Alberta", city: "Calgary")
        #expect(vehicle.location.displayName == "Calgary, Alberta")
    }

    @Test func vehicleDTOToDomainMapsAllFields() throws {
        let dto = try TestFixtures.decodedDTO()
        let vehicle = dto.toDomain()

        #expect(vehicle.vin == dto.vin)
        #expect(vehicle.specs.engine == dto.engine)
        #expect(vehicle.specs.transmission == dto.transmission)
        #expect(vehicle.specs.drivetrain == dto.drivetrain)
        #expect(vehicle.specs.fuelType == dto.fuelType)
        #expect(vehicle.specs.odometerKilometers == dto.odometerKilometers)
        #expect(vehicle.condition.grade == dto.conditionGrade)
        #expect(vehicle.condition.report == dto.conditionReport)
        #expect(vehicle.condition.titleStatus == dto.titleStatus)
        #expect(vehicle.auction.startingBid == dto.startingBid)
        #expect(vehicle.auction.reservePrice == dto.reservePrice)
        #expect(vehicle.auction.buyNowPrice == dto.buyNowPrice)
        #expect(vehicle.sellingDealership == dto.sellingDealership)
        #expect(vehicle.bidding.bidCount == dto.bidCount)
    }

    @Test func vehicleAPIDecoderAcceptsCustomDateFormat() throws {
        let json = #""2026-04-05T19:00:00""#
        let date = try JSONDecoder.vehicleAPI.decode(Date.self, from: Data(json.utf8))
        #expect(date.timeIntervalSince1970 > 0)
    }
}

struct FormatterTests {
    @Test func currencyFormatterHandlesNilAndAmounts() {
        #expect(CurrencyFormatter.string(from: nil) == "No bids")
        #expect(CurrencyFormatter.string(from: 12_345).contains("12"))
        #expect(CurrencyFormatter.string(from: 12_345).contains("345"))
    }

    @Test func vehicleFormattersProduceBuyerFriendlyStrings() {
        let now = Date(timeIntervalSince1970: 100)
        let future = Date(timeIntervalSince1970: 160)

        #expect(VehicleFormatters.titleCase("plug-in-hybrid") == "Plug In Hybrid")
        #expect(VehicleFormatters.auctionStatus(for: now, now: future) == "Live auction")
        #expect(VehicleFormatters.auctionStatus(for: future, now: now) != "Live auction")
        #expect(VehicleFormatters.kilometers(12_000).contains("12"))
    }

    @Test func dateTimeFormatsANonEmptyString() {
        let date = Date(timeIntervalSince1970: 0)
        let result = VehicleFormatters.dateTime(date)
        #expect(!result.isEmpty)
    }

    @Test func titleCaseHandlesAlreadyUppercase() {
        #expect(VehicleFormatters.titleCase("plug-in") == "Plug In")
        #expect(VehicleFormatters.titleCase("gasoline") == "Gasoline")
        #expect(VehicleFormatters.titleCase("all-wheel-drive") == "All Wheel Drive")
    }

    @Test func kilometersIncludesUnit() {
        let result = VehicleFormatters.kilometers(1_000)
        #expect(result.lowercased().contains("km") || result.contains("kilometer"))
    }
}

@MainActor
struct StoreTests {
    @Test func bidStoreReturnsInitialSnapshotAndMinimumBidFromCurrentBid() {
        let vehicle = TestFixtures.vehicle(currentBid: 10_000, bidCount: 2)
        let store = BidStore()
        let snapshot = store.snapshot(for: vehicle)

        #expect(snapshot.currentBid == 10_000)
        #expect(snapshot.bidCount == 2)
        #expect(store.minimumBid(for: vehicle) == 10_100)
    }

    @Test func bidStoreUsesStartingBidWhenVehicleHasNoBids() {
        let vehicle = TestFixtures.vehicle(currentBid: nil, bidCount: 0, startingBid: 9_000)
        let store = BidStore()

        #expect(store.snapshot(for: vehicle).currentBid == nil)
        #expect(store.minimumBid(for: vehicle) == 9_100)
    }

    @Test func bidStoreRejectsLowBidsAndUpdatesAcceptedBid() throws {
        let vehicle = TestFixtures.vehicle(currentBid: 10_000, bidCount: 2)
        let store = BidStore()

        #expect(throws: BidStore.BidError.amountTooLow(minimum: 10_100)) {
            try store.placeBid(10_050, on: vehicle)
        }

        let snapshot = try store.placeBid(10_250, on: vehicle)

        #expect(snapshot.currentBid == 10_250)
        #expect(snapshot.bidCount == 3)
        #expect(snapshot.lastBidPlacedAt != nil)
        #expect(store.snapshot(for: vehicle).currentBid == 10_250)
        #expect(store.minimumBid(for: vehicle) == 10_350)
    }

    @Test func watchlistStoreTogglesMembership() {
        let vehicle = TestFixtures.vehicle()
        let store = WatchlistStore()

        #expect(!store.contains(vehicle))

        store.toggle(vehicle)
        #expect(store.contains(vehicle))

        store.toggle(vehicle)
        #expect(!store.contains(vehicle))
    }

    @Test func watchlistStoreTracksMultipleVehiclesIndependently() {
        let a = TestFixtures.vehicle(id: UUID())
        let b = TestFixtures.vehicle(id: UUID())
        let store = WatchlistStore()

        store.toggle(a)
        #expect(store.contains(a))
        #expect(!store.contains(b))

        store.toggle(b)
        #expect(store.contains(a))
        #expect(store.contains(b))
    }

    @Test func bidStoreSequentialBidsUpdateMinimum() throws {
        let vehicle = TestFixtures.vehicle(currentBid: nil, bidCount: 0, startingBid: 5_000)
        let store = BidStore()

        // minimumBid = startingBid + 100 = 5_100
        try store.placeBid(5_100, on: vehicle)
        #expect(store.minimumBid(for: vehicle) == 5_200)

        try store.placeBid(5_200, on: vehicle)
        #expect(store.minimumBid(for: vehicle) == 5_300)
        #expect(store.snapshot(for: vehicle).bidCount == 2)
    }

    @Test func loadStateEquality() {
        #expect(LoadState.idle == .idle)
        #expect(LoadState.loading == .loading)
        #expect(LoadState.loaded == .loaded)
        #expect(LoadState.failed("err") == .failed("err"))
        #expect(LoadState.failed("a") != .failed("b"))
        #expect(LoadState.idle != .loading)
    }

    @Test func inventoryFilterOnlyWatchlistSetsActiveFilters() {
        let filter = InventoryFilter(bodyStyle: nil, province: nil, onlyWatchlist: true)
        #expect(filter.hasActiveFilters)
    }
}

@MainActor
@Suite(.serialized)
struct NetworkingTests {
    @Test func apiClientDecodesSuccessfulResponses() async throws {
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.absoluteString == "https://example.com/vehicles.json")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }

        let client = URLSessionAPIClient(session: .mocked, decoder: JSONDecoder())
        let result = try await client.send(Endpoint<TestResponse>(url: URL(string: "https://example.com/vehicles.json")!))

        #expect(result.value == "ok")
    }

    @Test func apiClientMapsHTTPStatusFailures() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let client = URLSessionAPIClient(session: .mocked, decoder: JSONDecoder())

        await #expect(throws: APIError.httpStatus(503)) {
            _ = try await client.send(Endpoint<TestResponse>(url: URL(string: "https://example.com/failure.json")!))
        }
    }

    @Test func apiClientMapsDecodingFailures() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"unexpected":"shape"}"#.utf8))
        }

        let client = URLSessionAPIClient(session: .mocked, decoder: JSONDecoder())

        await #expect(throws: APIError.self) {
            _ = try await client.send(Endpoint<TestResponse>(url: URL(string: "https://example.com/bad-json.json")!))
        }
    }

    @Test func apiClientMapsTransportFailures() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let client = URLSessionAPIClient(session: .mocked, decoder: JSONDecoder())

        await #expect(throws: APIError.self) {
            _ = try await client.send(Endpoint<TestResponse>(url: URL(string: "https://example.com/offline.json")!))
        }
    }

    @Test func endpointTargetsRemoteInventoryFeed() {
        #expect(Endpoint<[VehicleDTO]>.vehicleInventory.url.absoluteString == "https://raw.githubusercontent.com/kar-dmp/the-block/refs/heads/main/data/vehicles.json")
    }

    @Test func apiErrorsHaveReadableDescriptions() {
        #expect(APIError.invalidURL.errorDescription == "The request URL is invalid.")
        #expect(APIError.invalidResponse.errorDescription == "The server returned an unexpected response.")
        #expect(APIError.httpStatus(500).errorDescription?.contains("500") == true)
        #expect(APIError.decoding("Missing field").errorDescription?.contains("Missing field") == true)
        #expect(APIError.transport("Offline").errorDescription?.contains("Offline") == true)
    }

    @Test func apiErrorEquality() {
        #expect(APIError.invalidURL == .invalidURL)
        #expect(APIError.invalidResponse == .invalidResponse)
        #expect(APIError.httpStatus(404) == .httpStatus(404))
        #expect(APIError.httpStatus(404) != .httpStatus(500))
        #expect(APIError.decoding("x") == .decoding("x"))
        #expect(APIError.transport("y") == .transport("y"))
    }

}

@MainActor
struct VehicleServiceTests {
    @Test func remoteVehicleServiceMapsDTOsToDomainVehicles() async throws {
        let dto = try TestFixtures.decodedDTO()
        let service = RemoteVehicleService(apiClient: StubAPIClient(result: [dto]))

        let vehicles = try await service.fetchInventory()

        #expect(vehicles.count == 1)
        #expect(vehicles[0].lotNumber == dto.lot)
        let expectedDisplayName = "\(dto.year) \(dto.make) \(dto.model)"
        #expect(vehicles[0].displayName == expectedDisplayName)
    }

    @Test func remoteVehicleServicePropagatesAPIClientFailures() async {
        let service = RemoteVehicleService(apiClient: StubAPIClient<[VehicleDTO]>(error: APIError.transport("No connection")))

        await #expect(throws: APIError.transport("No connection")) {
            _ = try await service.fetchInventory()
        }
    }
}

@MainActor
struct InventoryViewModelTests {
    @Test func loadInventoryPublishesVehiclesAndLoadedState() async {
        let vehicles = [
            TestFixtures.vehicle(make: "Toyota", model: "RAV4", bodyStyle: "SUV", province: "Ontario"),
            TestFixtures.vehicle(make: "Honda", model: "Civic", bodyStyle: "Sedan", province: "Quebec")
        ]
        let service = StubVehicleService(result: .success(vehicles))
        let viewModel = InventoryViewModel(vehicleService: service)

        await viewModel.loadInventory()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.filteredVehicles.map(\.make) == ["Toyota", "Honda"])
        #expect(viewModel.bodyStyles == ["Sedan", "SUV"])
        #expect(viewModel.provinces == ["Ontario", "Quebec"])
        #expect(service.callCount == 1)
    }

    @Test func loadInventoryDoesNotRefetchWithoutForceRefresh() async {
        let service = StubVehicleService(result: .success([TestFixtures.vehicle()]))
        let viewModel = InventoryViewModel(vehicleService: service)

        await viewModel.loadInventory()
        await viewModel.loadInventory()
        await viewModel.loadInventory(forceRefresh: true)

        #expect(service.callCount == 2)
    }

    @Test func loadInventoryPublishesFailedStateWhenServiceThrows() async {
        let service = StubVehicleService(result: .failure(APIError.transport("Offline")))
        let viewModel = InventoryViewModel(vehicleService: service)

        await viewModel.loadInventory()

        guard case .failed(let message) = viewModel.loadState else {
            Issue.record("Expected failed load state")
            return
        }

        #expect(message.contains("Offline"))
        #expect(viewModel.filteredVehicles.isEmpty)
    }

    @Test func searchMatchesVehicleIdentityFields() async {
        let vehicle = TestFixtures.vehicle(
            lotNumber: "LOT-42",
            vin: "VIN123",
            make: "Subaru",
            model: "Outback",
            trim: "Wilderness",
            dealership: "Northline Auto"
        )
        let viewModel = InventoryViewModel(vehicleService: StubVehicleService(result: .success([vehicle])))
        await viewModel.loadInventory()

        viewModel.searchText = "wilderness"
        #expect(viewModel.filteredVehicles.map(\.id) == [vehicle.id])

        viewModel.searchText = "northline"
        #expect(viewModel.filteredVehicles.map(\.id) == [vehicle.id])

        viewModel.searchText = "missing"
        #expect(viewModel.filteredVehicles.isEmpty)
    }

    @Test func filtersByBodyStyleAndProvince() async {
        let suvOntario = TestFixtures.vehicle(bodyStyle: "SUV", province: "Ontario")
        let sedanOntario = TestFixtures.vehicle(bodyStyle: "Sedan", province: "Ontario")
        let suvQuebec = TestFixtures.vehicle(bodyStyle: "SUV", province: "Quebec")
        let viewModel = InventoryViewModel(vehicleService: StubVehicleService(result: .success([sedanOntario, suvQuebec, suvOntario])))
        await viewModel.loadInventory()

        viewModel.filter = InventoryFilter(bodyStyle: "SUV", province: "Ontario")

        #expect(viewModel.filteredVehicles.map(\.id) == [suvOntario.id])
    }

    @Test func filteredVehiclesSortedByAuctionStartTime() async {
        let earlier = TestFixtures.vehicle(startTime: Date(timeIntervalSince1970: 100))
        let later = TestFixtures.vehicle(startTime: Date(timeIntervalSince1970: 200))
        let viewModel = InventoryViewModel(vehicleService: StubVehicleService(result: .success([later, earlier])))
        await viewModel.loadInventory()

        #expect(viewModel.filteredVehicles.map(\.id) == [earlier.id, later.id])
    }

    @Test func searchMatchesByLocationCity() async {
        let vehicle = TestFixtures.vehicle(city: "Vancouver")
        let viewModel = InventoryViewModel(vehicleService: StubVehicleService(result: .success([vehicle])))
        await viewModel.loadInventory()

        viewModel.searchText = "vancouver"
        #expect(viewModel.filteredVehicles.map(\.id) == [vehicle.id])
    }

    @Test func searchMatchesByVIN() async {
        let vehicle = TestFixtures.vehicle(vin: "UNIQUE9VIN0123456")
        let viewModel = InventoryViewModel(vehicleService: StubVehicleService(result: .success([vehicle])))
        await viewModel.loadInventory()

        viewModel.searchText = "UNIQUE9VIN"
        #expect(viewModel.filteredVehicles.map(\.id) == [vehicle.id])
    }

    @Test func emptySearchReturnsAllVehicles() async {
        let vehicles = [TestFixtures.vehicle(), TestFixtures.vehicle()]
        let viewModel = InventoryViewModel(vehicleService: StubVehicleService(result: .success(vehicles)))
        await viewModel.loadInventory()

        viewModel.searchText = ""
        #expect(viewModel.filteredVehicles.count == 2)
    }

    @Test func filterByProvinceOnly() async {
        let ontario = TestFixtures.vehicle(province: "Ontario")
        let quebec = TestFixtures.vehicle(province: "Quebec")
        let viewModel = InventoryViewModel(vehicleService: StubVehicleService(result: .success([ontario, quebec])))
        await viewModel.loadInventory()

        viewModel.filter = InventoryFilter(province: "Ontario")
        #expect(viewModel.filteredVehicles.map(\.id) == [ontario.id])
    }

    @Test func initialLoadStateIsIdle() {
        let viewModel = InventoryViewModel(vehicleService: StubVehicleService(result: .success([])))
        #expect(viewModel.loadState == .idle)
    }
}

@MainActor
struct BidSheetViewModelTests {
    @Test func initializesWithMinimumBidAndAllowsValidSubmission() {
        let vehicle = TestFixtures.vehicle(currentBid: 10_000, bidCount: 2)
        let store = BidStore()
        let viewModel = BidSheetViewModel(vehicle: vehicle, bidStore: store)

        #expect(viewModel.minimumBid == 10_100)
        #expect(viewModel.bidAmountText == "10100")
        #expect(viewModel.canSubmit)

        viewModel.submit()

        #expect(viewModel.state == .confirmed)
        #expect(viewModel.validationMessage == nil)
        #expect(store.snapshot(for: vehicle).currentBid == 10_100)
        #expect(store.snapshot(for: vehicle).bidCount == 3)
    }

    @Test func rejectsEmptyAndLowBidAmounts() {
        let vehicle = TestFixtures.vehicle(currentBid: 10_000)
        let store = BidStore()
        let viewModel = BidSheetViewModel(vehicle: vehicle, bidStore: store)

        viewModel.bidAmountText = " "
        #expect(!viewModel.canSubmit)
        viewModel.submit()
        #expect(viewModel.validationMessage == "Enter a valid whole-dollar bid.")
        #expect(viewModel.state == .editing)

        viewModel.bidAmountText = "$10,050"
        #expect(viewModel.canSubmit)
        viewModel.submit()
        #expect(viewModel.validationMessage?.contains("at least") == true)
        #expect(viewModel.state == .editing)
        #expect(store.snapshot(for: vehicle).currentBid == 10_000)
    }

    @Test func successfulBidClearsValidationMessage() {
        let vehicle = TestFixtures.vehicle(currentBid: 5_000, bidCount: 1)
        let store = BidStore()
        let viewModel = BidSheetViewModel(vehicle: vehicle, bidStore: store)

        viewModel.bidAmountText = "invalid"
        viewModel.submit()
        #expect(viewModel.validationMessage != nil)

        viewModel.bidAmountText = "5100"
        viewModel.submit()
        #expect(viewModel.state == .confirmed)
        #expect(viewModel.validationMessage == nil)
    }

    @Test func canSubmitIsFalseWhenAmountIsEmpty() {
        let vehicle = TestFixtures.vehicle()
        let viewModel = BidSheetViewModel(vehicle: vehicle, bidStore: BidStore())

        viewModel.bidAmountText = ""
        #expect(!viewModel.canSubmit)
    }

    @Test func bidSheetViewModelReflectsMinimumBidForVehicleWithNoBids() {
        let vehicle = TestFixtures.vehicle(currentBid: nil, bidCount: 0, startingBid: 8_000)
        let viewModel = BidSheetViewModel(vehicle: vehicle, bidStore: BidStore())

        #expect(viewModel.minimumBid == 8_100)
        #expect(viewModel.bidAmountText == "8100")
    }
}

private struct TestResponse: Decodable, Equatable {
    let value: String
}

private struct StubAPIClient<Response: Decodable>: APIClientProtocol {
    let result: Response?
    let error: Error?

    init(result: Response) {
        self.result = result
        self.error = nil
    }

    init(error: Error) {
        self.result = nil
        self.error = error
    }

    func send<EndpointResponse>(_ endpoint: Endpoint<EndpointResponse>) async throws -> EndpointResponse where EndpointResponse: Decodable {
        if let error {
            throw error
        }

        guard let typedResult = result as? EndpointResponse else {
            throw APIError.decoding("Stub response type mismatch.")
        }

        return typedResult
    }
}

@MainActor
private final class StubVehicleService: VehicleServiceProtocol {
    private let result: Result<[Vehicle], Error>
    private(set) var callCount = 0

    init(result: Result<[Vehicle], Error>) {
        self.result = result
    }

    func fetchInventory() async throws -> [Vehicle] {
        callCount += 1
        return try result.get()
    }
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private extension URLSession {
    static var mocked: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private enum TestFixtures {
    static func decodedDTO() throws -> VehicleDTO {
        let dtos = try JSONDecoder.vehicleAPI.decode([VehicleDTO].self, from: Data(vehicleJSON.utf8))
        return try #require(dtos.first)
    }

    static func decodedVehicle() throws -> Vehicle {
        try decodedDTO().toDomain()
    }

    static func vehicle(
        id: UUID = UUID(),
        lotNumber: String = "A-TEST",
        vin: String = "TESTVIN1234567890",
        make: String = "Toyota",
        model: String = "RAV4",
        year: Int = 2024,
        trim: String = "XLE",
        bodyStyle: String = "SUV",
        province: String = "Ontario",
        city: String = "Toronto",
        dealership: String = "Test Dealer",
        currentBid: Int? = 10_000,
        bidCount: Int = 2,
        startingBid: Int = 9_000,
        startTime: Date = Date()
    ) -> Vehicle {
        Vehicle(
            id: id,
            lotNumber: lotNumber,
            vin: vin,
            make: make,
            model: model,
            year: year,
            trim: trim,
            bodyStyle: bodyStyle,
            exteriorColor: "Silver",
            interiorColor: "Black",
            specs: .init(
                engine: "2.5L I4",
                transmission: "automatic",
                drivetrain: "AWD",
                fuelType: "gasoline",
                odometerKilometers: 12_000
            ),
            condition: .init(
                grade: 4.1,
                report: "Clean test vehicle.",
                damageNotes: [],
                titleStatus: "clean"
            ),
            auction: .init(
                startingBid: startingBid,
                reservePrice: 13_000,
                buyNowPrice: nil,
                startTime: startTime
            ),
            location: .init(city: city, province: province),
            sellingDealership: dealership,
            images: [],
            bidding: .init(currentBid: currentBid, bidCount: bidCount)
        )
    }

    private static let vehicleJSON = """
    [
      {
        "id": "4e3cd74f-bb88-4efe-b234-bcb2f7474b40",
        "vin": "CG2UAF4T8LRBBVWJY",
        "year": 2025,
        "make": "Mazda",
        "model": "CX-5",
        "trim": "Turbo",
        "body_style": "SUV",
        "exterior_color": "Blue",
        "interior_color": "Light Grey",
        "engine": "2.5L I4",
        "transmission": "automatic",
        "drivetrain": "FWD",
        "odometer_km": 24534,
        "fuel_type": "gasoline",
        "condition_grade": 4,
        "condition_report": "Very clean vehicle inside and out.",
        "damage_notes": [],
        "title_status": "clean",
        "province": "Ontario",
        "city": "Mississauga",
        "auction_start": "2026-04-05T19:00:00",
        "starting_bid": 20500,
        "reserve_price": 29000,
        "buy_now_price": null,
        "images": ["https://placehold.co/800x600/1a1a2e/eaeaea?text=Photo"],
        "selling_dealership": "Highway 7 Auto Sales",
        "lot": "A-0001",
        "current_bid": 21000,
        "bid_count": 11
      }
    ]
    """
}

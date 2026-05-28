import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle

    @EnvironmentObject private var bidStore: BidStore
    @EnvironmentObject private var watchlistStore: WatchlistStore
    @State private var selectedImageIndex = 0
    @State private var showingBidSheet = false

    private var bidSnapshot: BidSnapshot {
        bidStore.snapshot(for: vehicle)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                gallery
                header
                bidSummary
                specsSection
                conditionSection
                auctionSection
                dealershipSection
            }
            .padding(.bottom, 110)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(vehicle.lotNumber)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.snappy) {
                        watchlistStore.toggle(vehicle)
                    }
                } label: {
                    Image(systemName: watchlistStore.contains(vehicle) ? "star.fill" : "star")
                }
                .accessibilityLabel(watchlistStore.contains(vehicle) ? "Remove from watchlist" : "Add to watchlist")
            }
        }
        .safeAreaInset(edge: .bottom) {
            bidBar
        }
        .sheet(isPresented: $showingBidSheet) {
            BidSheetView(vehicle: vehicle, bidStore: bidStore)
                .presentationDetents([.medium])
        }
    }

    private var gallery: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(Array(vehicle.images.enumerated()), id: \.offset) { index, image in
                AsyncVehicleImage(url: image)
                    .tag(index)
                    .frame(maxWidth: .infinity)
                    .clipped()
            }
        }
        .frame(height: 290)
        .tabViewStyle(.page)
        .background(.quaternary)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(vehicle.displayName)
                        .font(.title2.bold())
                    Text(vehicle.trim)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Grade \(vehicle.condition.grade, specifier: "%.1f")")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(gradeColor.opacity(0.14), in: Capsule())
                    .foregroundStyle(gradeColor)
            }

            HStack(spacing: 14) {
                Label(vehicle.location.displayName, systemImage: "mappin.and.ellipse")
                Label(vehicle.vin, systemImage: "number")
                    .textSelection(.enabled)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var bidSummary: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            MetricTile(title: "Highest Bid", value: CurrencyFormatter.string(from: bidSnapshot.currentBid), systemImage: "dollarsign.circle")
            MetricTile(title: "Bid Count", value: "\(bidSnapshot.bidCount)", systemImage: "chart.line.uptrend.xyaxis")
            MetricTile(title: "Reserve", value: reserveStatus, systemImage: "lock")
            MetricTile(title: "Starts", value: VehicleFormatters.auctionStatus(for: vehicle.auction.startTime), systemImage: "clock")
        }
        .padding(.horizontal)
    }

    private var specsSection: some View {
        SectionCard(title: "Vehicle Specs") {
            InfoRow(title: "Engine", value: vehicle.specs.engine)
            InfoRow(title: "Transmission", value: VehicleFormatters.titleCase(vehicle.specs.transmission))
            InfoRow(title: "Drivetrain", value: vehicle.specs.drivetrain)
            InfoRow(title: "Fuel", value: VehicleFormatters.titleCase(vehicle.specs.fuelType))
            InfoRow(title: "Odometer", value: VehicleFormatters.kilometers(vehicle.specs.odometerKilometers))
            InfoRow(title: "Exterior", value: vehicle.exteriorColor)
            InfoRow(title: "Interior", value: vehicle.interiorColor)
        }
        .padding(.horizontal)
    }

    private var conditionSection: some View {
        SectionCard(title: "Condition") {
            InfoRow(title: "Title", value: VehicleFormatters.titleCase(vehicle.condition.titleStatus))

            Text(vehicle.condition.report)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if vehicle.condition.damageNotes.isEmpty {
                Label("No damage notes reported", systemImage: "checkmark.seal")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Damage Notes")
                        .font(.subheadline.weight(.semibold))
                    ForEach(vehicle.condition.damageNotes, id: \.self) { note in
                        Label(note, systemImage: "exclamationmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var auctionSection: some View {
        SectionCard(title: "Auction Details") {
            InfoRow(title: "Starting bid", value: CurrencyFormatter.string(from: vehicle.auction.startingBid))
            InfoRow(title: "Current high bid", value: CurrencyFormatter.string(from: bidSnapshot.currentBid))
            InfoRow(title: "Minimum next bid", value: CurrencyFormatter.string(from: bidStore.minimumBid(for: vehicle)))
            InfoRow(title: "Reserve price", value: vehicle.auction.reservePrice.map(CurrencyFormatter.string(from:)) ?? "No reserve")
            InfoRow(title: "Buy now", value: vehicle.auction.buyNowPrice.map(CurrencyFormatter.string(from:)) ?? "Not available")
            InfoRow(title: "Auction start", value: VehicleFormatters.dateTime(vehicle.auction.startTime))
            InfoRow(title: "Bid history", value: bidHistorySummary)
        }
        .padding(.horizontal)
    }

    private var dealershipSection: some View {
        SectionCard(title: "Selling Dealership") {
            Label(vehicle.sellingDealership, systemImage: "building.2")
                .font(.subheadline.weight(.medium))
            Text(vehicle.location.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var bidBar: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Current high bid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.string(from: bidSnapshot.currentBid))
                        .font(.headline.monospacedDigit())
                }
                Spacer()
                Button("Bid") {
                    showingBidSheet = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .background(.bar)
    }

    private var reserveStatus: String {
        guard let reservePrice = vehicle.auction.reservePrice else { return "No reserve" }
        guard let currentBid = bidSnapshot.currentBid else { return "Not met" }
        return currentBid >= reservePrice ? "Met" : "Not met"
    }

    private var bidHistorySummary: String {
        if let lastBidPlacedAt = bidSnapshot.lastBidPlacedAt {
            return "Your bid placed \(RelativeDateTimeFormatter().localizedString(for: lastBidPlacedAt, relativeTo: Date()))"
        }
        return bidSnapshot.bidCount == 0 ? "No bids yet" : "\(bidSnapshot.bidCount) bids submitted"
    }

    private var gradeColor: Color {
        switch vehicle.condition.grade {
        case 4...:
            return .green
        case 3..<4:
            return .orange
        default:
            return .red
        }
    }
}

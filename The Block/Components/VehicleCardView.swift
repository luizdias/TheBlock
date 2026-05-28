import SwiftUI

struct VehicleCardView: View {
    let vehicle: Vehicle

    @EnvironmentObject private var bidStore: BidStore
    @EnvironmentObject private var watchlistStore: WatchlistStore

    private var bidSnapshot: BidSnapshot {
        bidStore.snapshot(for: vehicle)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncVehicleImage(url: vehicle.images.first)
                    .frame(height: 180)
                    .clipped()

                HStack(spacing: 8) {
                    statusPill

                    Button {
                        withAnimation(.snappy) {
                            watchlistStore.toggle(vehicle)
                        }
                    } label: {
                        Image(systemName: watchlistStore.contains(vehicle) ? "star.fill" : "star")
                            .font(.headline)
                            .foregroundStyle(watchlistStore.contains(vehicle) ? .yellow : .primary)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(watchlistStore.contains(vehicle) ? "Remove from watchlist" : "Add to watchlist")
                }
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(vehicle.trim)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Label(CurrencyFormatter.string(from: bidSnapshot.currentBid), systemImage: "dollarsign.circle.fill")
                        .fontWeight(.semibold)
                    Spacer(minLength: 10)
                    Text("\(bidSnapshot.bidCount) bids")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                HStack(spacing: 10) {
                    Label(vehicle.location.displayName, systemImage: "mappin.and.ellipse")
                        .lineLimit(1)
                    Spacer(minLength: 10)
                    Text("Lot \(vehicle.lotNumber)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(14)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var statusPill: some View {
        Text(VehicleFormatters.auctionStatus(for: vehicle.auction.startTime))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

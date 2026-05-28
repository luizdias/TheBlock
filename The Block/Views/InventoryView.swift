import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @EnvironmentObject private var watchlistStore: WatchlistStore
    @State private var showingFilters = false

    private var visibleVehicles: [Vehicle] {
        if viewModel.filter.onlyWatchlist {
            return viewModel.filteredVehicles.filter { watchlistStore.contains($0) }
        }
        return viewModel.filteredVehicles
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle where viewModel.vehicles.isEmpty,
                     .loading where viewModel.vehicles.isEmpty:
                    InventoryLoadingView()
                case .failed(let message) where viewModel.vehicles.isEmpty:
                    ContentUnavailableMessage(
                        systemImage: "wifi.exclamationmark",
                        title: "Inventory unavailable",
                        message: message,
                        retryTitle: "Retry"
                    ) {
                        Task { await viewModel.loadInventory(forceRefresh: true) }
                    }
                default:
                    inventoryContent
                }
            }
            .navigationTitle("The Block")
            .searchable(text: $viewModel.searchText, prompt: "Search make, model, VIN, lot")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: viewModel.filter.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter inventory")
                }
            }
            .task {
                await viewModel.loadInventory()
            }
            .refreshable {
                await viewModel.loadInventory(forceRefresh: true)
            }
            .sheet(isPresented: $showingFilters) {
                InventoryFilterSheet(
                    filter: $viewModel.filter,
                    bodyStyles: viewModel.bodyStyles,
                    provinces: viewModel.provinces
                )
                .presentationDetents([.medium])
            }
        }
    }

    private var inventoryContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if visibleVehicles.isEmpty {
                    ContentUnavailableMessage(
                        systemImage: "car.side",
                        title: "No vehicles found",
                        message: "Adjust search or filters to see more inventory."
                    )
                    .padding(.top, 80)
                } else {
                    ForEach(visibleVehicles) { vehicle in
                        NavigationLink(value: vehicle) {
                            VehicleCardView(vehicle: vehicle)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(for: Vehicle.self) { vehicle in
            VehicleDetailView(vehicle: vehicle)
        }
        .overlay(alignment: .top) {
            if case .loading = viewModel.loadState, !viewModel.vehicles.isEmpty {
                ProgressView()
                    .padding(10)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 8)
            }
        }
    }
}

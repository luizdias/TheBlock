import SwiftUI

struct BidSheetView: View {
    let vehicle: Vehicle

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bidStore: BidStore
    @StateObject private var viewModel: BidSheetViewModel

    init(vehicle: Vehicle, bidStore: BidStore) {
        self.vehicle = vehicle
        _viewModel = StateObject(wrappedValue: BidSheetViewModel(vehicle: vehicle, bidStore: bidStore))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(vehicle.displayName)
                        .font(.title3.bold())
                    Text("Lot \(vehicle.lotNumber) · Minimum bid \(CurrencyFormatter.string(from: viewModel.minimumBid))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                TextField("Bid amount", text: $viewModel.bidAmountText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3.monospacedDigit())
                    .disabled(viewModel.state == .submitting || viewModel.state == .confirmed)

                if let validationMessage = viewModel.validationMessage {
                    Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                switch viewModel.state {
                case .editing, .submitting:
                    Button {
                        viewModel.submit()
                    } label: {
                        HStack {
                            if viewModel.state == .submitting {
                                ProgressView()
                            }
                            Text("Place Bid")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!viewModel.canSubmit)
                case .confirmed:
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Bid placed", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.green)

                        Text("Your bid is now reflected across inventory and vehicle details.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Submit Bid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

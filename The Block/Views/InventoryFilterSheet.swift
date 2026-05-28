import SwiftUI

struct InventoryFilterSheet: View {
    @Binding var filter: InventoryFilter
    let bodyStyles: [String]
    let provinces: [String]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    Picker("Body style", selection: bodyStyleBinding) {
                        Text("Any").tag(String?.none)
                        ForEach(bodyStyles, id: \.self) { style in
                            Text(VehicleFormatters.titleCase(style)).tag(String?.some(style))
                        }
                    }
                }

                Section("Location") {
                    Picker("Province", selection: provinceBinding) {
                        Text("Any").tag(String?.none)
                        ForEach(provinces, id: \.self) { province in
                            Text(province).tag(String?.some(province))
                        }
                    }
                }

                Section("Buying") {
                    Toggle("Watchlist only", isOn: $filter.onlyWatchlist)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        filter = InventoryFilter()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var bodyStyleBinding: Binding<String?> {
        Binding(
            get: { filter.bodyStyle },
            set: { filter.bodyStyle = $0 }
        )
    }

    private var provinceBinding: Binding<String?> {
        Binding(
            get: { filter.province },
            set: { filter.province = $0 }
        )
    }
}

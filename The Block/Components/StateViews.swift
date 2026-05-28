import SwiftUI

struct InventoryLoadingView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.quaternary)
                        .frame(height: 230)
                        .overlay(alignment: .bottomLeading) {
                            VStack(alignment: .leading, spacing: 10) {
                                Capsule().fill(.tertiary).frame(width: 180, height: 16)
                                Capsule().fill(.tertiary).frame(width: 120, height: 12)
                            }
                            .padding()
                        }
                        .redacted(reason: .placeholder)
                }
            }
            .padding()
        }
    }
}

struct ContentUnavailableMessage: View {
    let systemImage: String
    let title: String
    let message: String
    var retryTitle: String?
    var retryAction: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let retryTitle, let retryAction {
                Button(retryTitle, action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

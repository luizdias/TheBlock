import SwiftUI

struct AsyncVehicleImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Rectangle().fill(.quaternary)
                    ProgressView()
                }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                ZStack {
                    Rectangle().fill(.quaternary)
                    Image(systemName: "car.side")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            @unknown default:
                EmptyView()
            }
        }
    }
}

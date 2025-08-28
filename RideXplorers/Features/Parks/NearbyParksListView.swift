import SwiftUI

struct NearbyParksListView: View {
    @StateObject private var viewModel = NearbyParksViewModel()
    @State private var currentPage: Int = 0

    var body: some View {
        VStack(alignment: .leading) {
            // Header matching the mockup
            HStack(alignment: .firstTextBaseline) {
                Text("Parcs à proximité")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)

            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text("Impossible de charger les parcs à proximité")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            } else if viewModel.nearbyParks.isEmpty {
                Text("Aucun parc trouvé à proximité")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            } else {
                let items = Array(viewModel.nearbyParks.prefix(15))
                let pages: [[NearbyPark]] = Self.chunk(items, size: 3)

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 12) {
                            ForEach(page) { park in
                                NearbyParkRow(park: park)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 360)
            }
        }
        .task { await viewModel.loadTopNearestParks(limit: 15) }
    }

    private static func chunk<T>(_ array: [T], size: Int) -> [[T]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: array.count, by: size).map { start in
            Array(array[start ..< min(start + size, array.count)])
        }
    }
}

private struct NearbyParkRow: View {
    let park: NearbyPark

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 50, height: 50)

            VStack(alignment: .leading) {
                Text(park.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let country = park.country {
                    Text(country)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(park.country != nil ? "\(park.name), \(park.country!)" : park.name)
    }
}

struct NearbyParksListView_Previews: PreviewProvider {
    static var previews: some View {
        NearbyParksListView()
    }
}



import SwiftUI
import UIKit

struct NearbyParksListView: View {
    @StateObject private var viewModel = NearbyParksViewModel()
    @State private var currentPage: Int = 0
    // For iOS 17 ScrollView paging with scrollPosition (expects Optional<some Hashable>)
    @State private var currentPageID: Int? = 0

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

                if #available(iOS 16.0, *) {
                    ParksPeekPager(pages: pages, currentPage: $currentPage)
                        .frame(height: 360)
                } else {
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
    @State private var imageURL: URL?
    @State private var isLoadingImage = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .center) {
                if let url = imageURL {
                    if url.isFileURL, let img = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            default:
                                // Loading or failure: show placeholder
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(placeholderColor(for: park))
                                Text(initials(from: park.name))
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundColor(.white)
                                    .opacity(0.85)
                            }
                        }
                    }
                } else {
                    // No image URL: placeholder
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(placeholderColor(for: park))
                    Text(initials(from: park.name))
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)
                        .opacity(0.85)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

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
            if let distanceText = formattedDistanceKM() {
                Text(distanceText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 12)
                    .accessibilityLabel("Distance \(distanceText)")
            }
        }
        // Ensure each row has a consistent minimum height even if the
        // name wraps to 2 lines, keeping page heights uniform.
        .frame(minHeight: 60, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(park.country != nil ? "\(park.name), \(park.country!)" : park.name)
        .task(id: park.id) {
            // Load main picture once; uses disk cache afterwards
            guard imageURL == nil, !isLoadingImage else { return }
            isLoadingImage = true
            defer { isLoadingImage = false }
            let url = await ImageCacheService.shared.localMainImageURL(for: park.name)
            if let url { imageURL = url }
        }
    }

    private func formattedDistanceKM() -> String? {
        let meters = park.distanceMeters
        guard meters.isFinite && meters >= 0 else { return nil }
        let km = meters / 1000.0
        return String(format: "%.1f km", km)
    }

    private func initials(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "?" }

        // Split by non-alphanumeric separators to get words
        let parts = trimmed.split { !$0.isLetter && !$0.isNumber }.map { String($0) }
        if parts.count >= 2 {
            let first = parts[0].first.map { String($0).uppercased() } ?? ""
            let second = parts[1].first.map { String($0).uppercased() } ?? ""
            let result = (first + second)
            return String(result.prefix(2))
        }

        // Single token: attempt to extract from CamelCase (e.g. PanoraMagique -> PM)
        let uppers = trimmed.filter { $0.isUppercase }
        if uppers.count >= 2 {
            let firstTwo = uppers.prefix(2)
            return String(firstTwo)
        }

        // Fallback: first two letters uppercased
        let letters = trimmed.filter { $0.isLetter || $0.isNumber }
        if letters.isEmpty { return "?" }
        return String(letters.prefix(2)).uppercased()
    }

    private func placeholderColor(for park: NearbyPark) -> Color {
        // Stable color based on park id
        let palette: [Color] = [
            .blue, .orange, .green, .purple, .pink, .teal, .indigo, .red, .yellow
        ]
        let idx = abs(park.id) % max(palette.count, 1)
        return palette[idx]
    }
}


// MARK: - UIKit-based Pager with Peek (iOS 16+)
@available(iOS 16.0, *)
private struct ParksPeekPager: UIViewRepresentable {
    let pages: [[NearbyPark]]
    @Binding var currentPage: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UICollectionView {
        let layout = Self.makeLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.delegate = context.coordinator
        context.coordinator.configure(collectionView: collectionView)
        return collectionView
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.applySnapshot(pages: pages)
        // Scroll to current page if needed
        let indexPath = IndexPath(item: min(max(currentPage, 0), max(pages.count - 1, 0)), section: 0)
        if let visible = uiView.indexPathsForVisibleItems.sorted().first, visible == indexPath { return }
        if pages.indices.contains(currentPage) {
            uiView.scrollToItem(at: indexPath, at: .left, animated: false)
        }
    }

    private static func makeLayout() -> UICollectionViewLayout {
        // Peek with leading alignment: fixed absolute peek in points, no inter-group spacing
        return UICollectionViewCompositionalLayout { _, environment in
            let containerWidth = environment.container.effectiveContentSize.width
            let leading: CGFloat = 16
            let trailing: CGFloat = 16
            let peek: CGFloat = 56 // visible portion of next page
            let trailingEffective = trailing + peek // ensure last page can align left

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(360)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(max(containerWidth - leading - trailingEffective, 0)),
                heightDimension: .absolute(360)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPaging // align to leading
            section.interGroupSpacing = 0 // show next content immediately (no empty gap)
            // Align pages with header padding on both sides
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: leading, bottom: 0, trailing: trailingEffective)
            return section
        }
    }

    final class Coordinator: NSObject, UICollectionViewDelegate {
        private let parent: ParksPeekPager
        private var dataSource: UICollectionViewDiffableDataSource<Int, Int>!

        init(_ parent: ParksPeekPager) {
            self.parent = parent
        }

        func configure(collectionView: UICollectionView) {
            collectionView.contentInsetAdjustmentBehavior = .never
            let registration = UICollectionView.CellRegistration<UICollectionViewCell, Int> { cell, indexPath, itemIdentifier in
                // itemIdentifier is the page index
                let pageIndex = itemIdentifier
                if self.parent.pages.indices.contains(pageIndex) {
                    let page = self.parent.pages[pageIndex]
                    cell.contentConfiguration = UIHostingConfiguration {
                        VStack(spacing: 12) {
                            ForEach(page) { park in
                                NearbyParkRow(park: park)
                            }
                            Spacer(minLength: 0)
                        }
                        // Horizontal padding handled by section.contentInsets (leading/trailing: 16)
                    }
                    .margins(.all, 0)
                    cell.contentView.directionalLayoutMargins = .zero
                    cell.backgroundConfiguration = nil
                }
            }

            dataSource = UICollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
                collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: itemIdentifier)
            }
        }

        func applySnapshot(pages: [[NearbyPark]]) {
            var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
            snapshot.appendSections([0])
            snapshot.appendItems(Array(pages.indices), toSection: 0)
            dataSource.apply(snapshot, animatingDifferences: false)
        }

        // Update currentPage when paging stops
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { updateCurrentPage(scrollView) }
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate { updateCurrentPage(scrollView) }
        }
        func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { updateCurrentPage(scrollView) }

        private func updateCurrentPage(_ scrollView: UIScrollView) {
            guard let collectionView = scrollView as? UICollectionView else { return }
            let center = CGPoint(x: collectionView.bounds.midX + collectionView.contentOffset.x,
                                 y: collectionView.bounds.midY + collectionView.contentOffset.y)
            if let indexPath = collectionView.indexPathForItem(at: center) {
                let newIndex = indexPath.item
                if newIndex != self.parent.currentPage {
                    DispatchQueue.main.async { self.parent.currentPage = newIndex }
                }
            }
        }
    }
}

struct NearbyParksListView_Previews: PreviewProvider {
    static var previews: some View {
        NearbyParksListView()
    }
}

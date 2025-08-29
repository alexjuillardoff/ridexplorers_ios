import SwiftUI

struct NewsDetailView: View {
    /// Élément de news présenté en détail.
    let newsItem: NewsItem
    @Environment(\.dismiss) private var dismiss
    /// Données d’image préchargées pour un affichage fluide.
    @State private var imageData: Data?
    /// Indicateur d’état de chargement initial de la vue.
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    // Écran de chargement avec les informations de base
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(newsItem.headline.uppercased())
                                .font(.caption)
                                .fontWeight(.heavy)
                                .foregroundColor(.blue)
                            
                            Text(newsItem.park)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(newsItem.city), \(newsItem.country)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    // Contenu principal une fois chargé
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Image principale en grand avec préchargement optimisé
                            ZStack(alignment: .topTrailing) {
                                if let urlString = newsItem.imageURL, let url = URL(string: urlString) {
                                    Group {
                                        if let imageData = imageData, let uiImage = imageData.toUIImage() {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        } else {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ZStack { 
                                                        Color.gray.opacity(0.2)
                                                        ProgressView()
                                                            .scaleEffect(1.5)
                                                    }
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                case .failure:
                                                    ZStack { 
                                                        Color.gray.opacity(0.2)
                                                        Image(systemName: "photo")
                                                            .font(.system(size: 60))
                                                            .foregroundColor(.secondary)
                                                    }
                                                @unknown default:
                                                    Color.gray.opacity(0.2)
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    ZStack { 
                                        Color.gray.opacity(0.2)
                                        Image(systemName: "photo")
                                            .font(.system(size: 60))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Bouton fermer amélioré avec liquid glass
                                Button(action: { dismiss() }) {
                                    Image(systemName: "xmark")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .frame(width: 30, height: 30)
                                }
                                .buttonStyle(.glass)
                                .padding(24)
                            }
                            .frame(maxWidth: .infinity, maxHeight: 300)
                            .clipped()
                            
                            // Contenu de la news
                            VStack(alignment: .leading, spacing: 16) {
                                // Headline
                                Text(newsItem.headline.uppercased())
                                    .font(.caption)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 16)
                                
                                // Titre du parc
                                Text(newsItem.park)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, 16)
                                
                                // Localisation
                                HStack(spacing: 8) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text("\(newsItem.city), \(newsItem.country)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 16)
                                
                                // Séparateur
                                Divider()
                                    .padding(.horizontal, 16)
                                
                                // Nom de l'attraction
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Attraction")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(newsItem.rideName)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.horizontal, 16)
                                
                                // Description
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Description")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(newsItem.summary)
                                        .font(.body)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineSpacing(2)
                                }
                                .padding(.horizontal, 16)
                                
                                Spacer(minLength: 20)
                            }
                            .padding(.top, 16)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(.container, edges: .top)
        }
        .task {
            // Précharger l'image et marquer comme chargé
            if let urlString = newsItem.imageURL, let url = URL(string: urlString) {
                await preloadImage(from: url)
            }
            
            // Marquer la vue comme chargée après un court délai pour assurer la fluidité
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconde
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    /// Précharge l’image distante et stocke les données pour accélérer l’affichage.
    private func preloadImage(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            await MainActor.run {
                self.imageData = data
            }
        } catch {
            // En cas d'erreur, on continue sans bloquer l'UI
            print("Erreur de préchargement d'image: \(error)")
        }
    }
}

#Preview {
    NewsDetailView(newsItem: NewsItem(
        id: 1,
        visible: true,
        headline: "Nouvelle attraction",
        park: "Disneyland Paris",
        city: "Marne-la-Vallée",
        country: "France",
        rideName: "Space Mountain",
        summary: "Une attraction de montagnes russes spatiales qui vous emmène dans l'espace à travers des tunnels et des virages serrés.",
        imageURL: nil
    ))
}

import SwiftUI

struct HeaderView: View {
    /// Titre principal affiché dans l’en-tête de page.
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
            Button(action: {
                // Action placeholder: pourrait ouvrir un profil ou un menu.
            }) {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(title: "Sample Title")
    }
}

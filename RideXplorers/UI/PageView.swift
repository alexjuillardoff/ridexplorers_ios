import SwiftUI

struct PageView<Content: View>: View {
    /// Titre affiché dans l’en-tête de la page.
    let title: String
    /// Contenu principal de la page.
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(title: title)
            content
        }
    }
}

struct PageView_Previews: PreviewProvider {
    static var previews: some View {
        PageView(title: "Sample Page") {
            Spacer()
        }
    }
}

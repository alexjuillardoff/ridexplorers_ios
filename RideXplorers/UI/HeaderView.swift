import SwiftUI

struct HeaderView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
            Button(action: {
                // Profile action placeholder
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

import SwiftUI

struct PageView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: -20) {
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

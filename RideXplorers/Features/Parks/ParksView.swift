import SwiftUI

struct ParksView: View {
    var body: some View {
        PageView(title: "Parks") {
            VStack(spacing: 0) {
                NewsSliderView()
                    .padding(.top, -20)
                Spacer()
            }
        }
    }
}

struct ParksView_Previews: PreviewProvider {
    static var previews: some View {
        ParksView()
    }
}

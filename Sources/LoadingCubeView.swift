import SwiftUI

struct LoadingCubeView: View {
    @State private var pulse: Bool = false

    var body: some View {
        LogoView(size: 120)
            .scaleEffect(pulse ? 1.15 : 0.85)
            .opacity(pulse ? 1.0 : 0.7)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

#Preview {
    LoadingCubeView()
        .frame(width: 200, height: 200)
}

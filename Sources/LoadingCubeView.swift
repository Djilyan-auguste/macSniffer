import SwiftUI

struct LoadingCubeView: View {
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.86, blue: 0.40),
                            Color(red: 0.95, green: 0.70, blue: 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: Color(red: 0.75, green: 0.50, blue: 0.10).opacity(0.35), radius: 24, x: 0, y: 12)
                .scaleEffect(pulse ? 1.15 : 0.85)
                .opacity(pulse ? 1.0 : 0.7)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(red: 0.75, green: 0.50, blue: 0.10).opacity(0.4), lineWidth: 1)
                .frame(width: 100, height: 100)
                .scaleEffect(pulse ? 1.15 : 0.85)
        }
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

import SwiftUI

struct LogoView: View {
    let size: CGFloat

    var body: some View {
        Image(nsImage: Bundle.main.image(forResource: "Logo") ?? NSImage())
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(Color(red: 0.95, green: 0.70, blue: 0.18))
                    .frame(width: size, height: size)
            )
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: size * 0.06, x: 0, y: size * 0.04)
    }
}

#Preview {
    LogoView(size: 128)
}

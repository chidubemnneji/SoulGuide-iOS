import SwiftUI
import WebKit
import AVFoundation

import SwiftUI
import WebKit
import AVFoundation

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 1)
        }
        self.init(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }
    static let brand = Color(hex: "7C6AC7")
    static let gold = Color(hex: "C8A96E")
    // Adaptive accent: purple in light mode, gold in dark mode
    static let accent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 200/255, green: 169/255, blue: 110/255, alpha: 1) // gold
            : UIColor(red: 124/255, green: 106/255, blue: 199/255, alpha: 1) // purple
    })
}

// MARK: - Splash
struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                FlameLogo(size: 64)
                Text("SoulGuide")
                    .font(.custom("Georgia", size: 28))
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Flame Logo
struct FlameLogo: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(Color.brand)
                .frame(width: size, height: size)
            Image(systemName: "flame.fill")
                .resizable().scaledToFit()
                .frame(width: size * 0.45, height: size * 0.55)
                .foregroundColor(.white)
        }
    }
}


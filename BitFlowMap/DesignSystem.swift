import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary
    static let bfmDeepNavy     = Color(hex: "#0A0E1A")
    static let bfmMidnight     = Color(hex: "#111827")
    static let bfmSurface      = Color(hex: "#1A2235")
    static let bfmCard         = Color(hex: "#1E2D45")

    // Accent
    static let bfmCyan         = Color(hex: "#00E5FF")
    static let bfmCyanDim      = Color(hex: "#00B8CC")
    static let bfmPurple       = Color(hex: "#7C3AED")
    static let bfmPurpleLight  = Color(hex: "#A855F7")
    static let bfmGold         = Color(hex: "#F59E0B")
    static let bfmGreen        = Color(hex: "#10B981")
    static let bfmRed          = Color(hex: "#EF4444")

    // Text
    static let bfmTextPrimary  = Color(hex: "#F1F5F9")
    static let bfmTextSecondary = Color(hex: "#94A3B8")
    static let bfmTextTertiary = Color(hex: "#475569")

    // Gradients base
    static let bfmGradientStart = Color(hex: "#0D1B2A")
    static let bfmGradientEnd   = Color(hex: "#162032")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let bfmBackground = LinearGradient(
        colors: [Color.bfmDeepNavy, Color.bfmGradientEnd],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let bfmCyanGlow = LinearGradient(
        colors: [Color.bfmCyan, Color.bfmPurpleLight],
        startPoint: .leading, endPoint: .trailing
    )
    static let bfmCardGrad = LinearGradient(
        colors: [Color.bfmCard, Color.bfmSurface],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let bfmGoldGrad = LinearGradient(
        colors: [Color.bfmGold, Color(hex: "#F97316")],
        startPoint: .leading, endPoint: .trailing
    )
    static let bfmGreenGrad = LinearGradient(
        colors: [Color.bfmGreen, Color(hex: "#059669")],
        startPoint: .leading, endPoint: .trailing
    )
    static let bfmPurpleGrad = LinearGradient(
        colors: [Color.bfmPurple, Color.bfmPurpleLight],
        startPoint: .leading, endPoint: .trailing
    )
}

// MARK: - BFM Button Style
struct BFMPrimaryButton: ButtonStyle {
    var gradient: LinearGradient = .bfmCyanGlow
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(.bfmDeepNavy)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isDisabled ? LinearGradient(colors: [Color.bfmTextTertiary], startPoint: .leading, endPoint: .trailing) : gradient)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: Color.bfmCyan.opacity(configuration.isPressed ? 0.2 : 0.4), radius: configuration.isPressed ? 4 : 12, x: 0, y: 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct BFMSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(.bfmCyan)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.bfmSurface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.bfmCyan.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Card View
struct BFMCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 20

    init(padding: CGFloat = 20, cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient.bfmCardGrad)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.bfmCyan.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
            )
    }
}

// MARK: - Glowing Circle
struct GlowCircle: View {
    var color: Color = .bfmCyan
    var size: CGFloat = 80
    var opacity: Double = 0.15

    var body: some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: size, height: size)
            .blur(radius: size * 0.4)
    }
}

// MARK: - BFM Text Field
struct BFMTextField: View {
    var placeholder: String
    @Binding var text: String
    var icon: String = ""
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.bfmCyan.opacity(0.7))
                    .frame(width: 24)
            }
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.bfmTextPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.bfmTextPrimary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.bfmSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.bfmCyan.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Score Badge
struct ScoreBadge: View {
    var score: Int
    var maxScore: Int = 100

    var color: Color {
        let ratio = Double(score) / Double(maxScore)
        if ratio > 0.7 { return .bfmGreen }
        if ratio > 0.4 { return .bfmGold }
        return .bfmRed
    }

    var body: some View {
        Text("\(score)")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.15), .clear],
                    startPoint: .init(x: phase - 0.3, y: 0),
                    endPoint: .init(x: phase + 0.3, y: 0)
                )
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
            )
            .onAppear { phase = 1.5 }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    func bfmBackground() -> some View {
        self.background(LinearGradient.bfmBackground.ignoresSafeArea())
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String
    var color: Color = .bfmCyan

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }
}

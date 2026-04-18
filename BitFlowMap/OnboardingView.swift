import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage: Int = 0

    var body: some View {
        ZStack {
            Color.bfmDeepNavy.ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingPage1()
                    .tag(0)
                OnboardingPage2()
                    .tag(1)
                OnboardingPage3(onStart: {
                    appState.hasCompletedOnboarding = true
                })
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

            // Overlay controls
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < 2 {
                        Button("Skip") {
                            withAnimation {
                                appState.hasCompletedOnboarding = true
                            }
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.bfmTextSecondary)
                        .padding()
                    }
                }

                Spacer()

                // Page dots + Next
                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.bfmCyan : Color.bfmTextTertiary)
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    if currentPage < 2 {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        }) {
                            Label("Next", systemImage: "arrow.right")
                        }
                        .buttonStyle(BFMPrimaryButton())
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Page 1
struct OnboardingPage1: View {
    @State private var appeared = false
    @State private var linesProgress: [CGFloat] = [0, 0, 0]

    var body: some View {
        ZStack {
            GlowCircle(color: .bfmCyan, size: 400, opacity: 0.06).offset(x: 80, y: -100)

            VStack(spacing: 0) {
                Spacer()

                // Illustration
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        BranchLine(index: i, progress: linesProgress[i])
                    }
                }
                .frame(width: 260, height: 200)
                .scaleEffect(appeared ? 1.0 : 0.7)
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 48)

                VStack(spacing: 12) {
                    Text("Every Choice")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                    Text("Creates a Path")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient.bfmCyanGlow)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer().frame(height: 20)

                Text("Map your decisions like a flow chart.\nSee every branch before you leap.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.bfmTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
            for i in 0..<3 {
                withAnimation(.easeOut(duration: 0.8).delay(0.4 + Double(i) * 0.15)) {
                    linesProgress[i] = 1.0
                }
            }
        }
    }
}

struct BranchLine: View {
    let index: Int
    let progress: CGFloat

    var color: Color {
        [Color.bfmCyan, Color.bfmPurpleLight, Color.bfmGold][index]
    }

    var endX: CGFloat {
        [-80, 0, 80][index]
    }

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let startY: CGFloat = 20
            let midY: CGFloat = 90
            let endY: CGFloat = 170

            if progress > 0 {
                // Trunk
                var trunk = Path()
                trunk.move(to: CGPoint(x: cx, y: startY))
                trunk.addLine(to: CGPoint(x: cx, y: midY))
                ctx.stroke(trunk, with: .color(Color.bfmCyan.opacity(0.7)), lineWidth: 2)

                // Branch
                if progress > 0.4 {
                    var branch = Path()
                    branch.move(to: CGPoint(x: cx, y: midY))
                    let targetX = cx + endX * progress
                    let targetY = midY + (endY - midY) * progress
                    branch.addLine(to: CGPoint(x: targetX, y: targetY))
                    ctx.stroke(branch, with: .color(color.opacity(0.9)), lineWidth: 2)

                    // Endpoint dot
                    if progress > 0.9 {
                        ctx.fill(Path(ellipseIn: CGRect(x: targetX - 5, y: targetY - 5, width: 10, height: 10)),
                                 with: .color(color))
                    }
                }

                // Root dot
                ctx.fill(Path(ellipseIn: CGRect(x: cx - 4, y: startY - 4, width: 8, height: 8)),
                         with: .color(Color.bfmCyan))
                ctx.fill(Path(ellipseIn: CGRect(x: cx - 4, y: midY - 4, width: 8, height: 8)),
                         with: .color(Color.bfmTextSecondary.opacity(0.6)))
            }
        }
    }
}

// MARK: - Page 2
struct OnboardingPage2: View {
    @State private var appeared = false
    @State private var selectedCard: Int = -1

    var body: some View {
        ZStack {
            GlowCircle(color: .bfmPurple, size: 350, opacity: 0.07).offset(x: -60, y: 50)

            VStack(spacing: 0) {
                Spacer()

                // Interactive cards A/B
                HStack(spacing: 16) {
                    ForEach(0..<2, id: \.self) { i in
                        VariantPreviewCard(
                            label: i == 0 ? "A" : "B",
                            title: i == 0 ? "Move to NYC" : "Stay Local",
                            money: i == 0 ? "$45K" : "$2K",
                            time: i == 0 ? "160h" : "20h",
                            stress: i == 0 ? 7 : 3,
                            isSelected: selectedCard == i,
                            color: i == 0 ? .bfmCyan : .bfmPurpleLight
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedCard = i
                            }
                        }
                    }
                }
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)
                .padding(.horizontal, 24)

                Spacer().frame(height: 48)

                VStack(spacing: 12) {
                    Text("See Outcomes")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                    Text("Before You Decide")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient.bfmPurpleGrad)
                }
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 16)

                Text("Tap the cards above to compare!\nAnalyze cost, time, stress, and risk.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.bfmTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .opacity(appeared ? 1 : 0)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
    }
}

struct VariantPreviewCard: View {
    let label: String
    let title: String
    let money: String
    let time: String
    let stress: Int
    let isSelected: Bool
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(color)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                        .font(.system(size: 18))
                }
            }

            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.bfmTextPrimary)
                .lineLimit(2)

            Divider().background(color.opacity(0.3))

            VStack(alignment: .leading, spacing: 6) {
                HStack { Image(systemName: "dollarsign.circle").foregroundColor(.bfmGold).font(.system(size: 12)); Text(money).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundColor(.bfmTextSecondary) }
                HStack { Image(systemName: "clock").foregroundColor(.bfmCyan).font(.system(size: 12)); Text(time).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundColor(.bfmTextSecondary) }
                HStack { Image(systemName: "brain").foregroundColor(.bfmPurpleLight).font(.system(size: 12)); Text("Stress: \(stress)/10").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundColor(.bfmTextSecondary) }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.bfmCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isSelected ? color : color.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )
        )
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 12)
    }
}

// MARK: - Page 3
struct OnboardingPage3: View {
    @State private var appeared = false
    let onStart: () -> Void

    var body: some View {
        ZStack {
            GlowCircle(color: .bfmGold, size: 300, opacity: 0.06).offset(x: 60, y: 60)

            VStack(spacing: 0) {
                Spacer()

                // Emoji illustration
                ZStack {
                    ForEach(0..<6, id: \.self) { i in
                        let angle = Double(i) * 60.0 * .pi / 180
                        let icons = ["🧠", "📊", "💡", "🎯", "⚡", "✅"]
                        Text(icons[i])
                            .font(.system(size: 28))
                            .offset(
                                x: cos(angle) * 80,
                                y: sin(angle) * 80
                            )
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1 + Double(i) * 0.08), value: appeared)
                    }
                    Text("🚀")
                        .font(.system(size: 44))
                        .scaleEffect(appeared ? 1 : 0.3)
                        .opacity(appeared ? 1 : 0)
                }
                .frame(width: 200, height: 200)

                Spacer().frame(height: 40)

                VStack(spacing: 10) {
                    Text("Plan Smart.")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(.bfmTextPrimary)
                    Text("Act Better.")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient.bfmGoldGrad)
                }
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 16)

                VStack(spacing: 8) {
                    FeatureLine(icon: "arrow.triangle.branch", text: "Visual decision trees")
                    FeatureLine(icon: "chart.bar.fill", text: "Impact calculator & analytics")
                    FeatureLine(icon: "lightbulb.fill", text: "Smart scenario simulation")
                }
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 40)

                Button("Start Planning") { onStart() }
                    .buttonStyle(BFMPrimaryButton())
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.9)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
    }
}

struct FeatureLine: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.bfmGold)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.bfmTextSecondary)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

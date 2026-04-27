import SwiftUI
import Combine
import Network

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var particlesVisible: Bool = false
    @State private var glowRadius: CGFloat = 0
    @StateObject private var viewModel = BitFlowViewModel()
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    @State private var lineProgress: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.bfmDeepNavy.ignoresSafeArea()
                
                GeometryReader { geo in
                    Image("bbp")
                        .resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .ignoresSafeArea()
                        .blur(radius: 14)
                        .opacity(0.2)
                }
                
                // Ambient glows
                ZStack {
                    GlowCircle(color: .bfmCyan, size: 300, opacity: 0.08)
                        .offset(x: -80, y: -120)
                    GlowCircle(color: .bfmPurple, size: 250, opacity: 0.1)
                        .offset(x: 100, y: 100)
                }
                
                // Particle dots
                if particlesVisible {
                    ForEach(0..<20, id: \.self) { i in
                        ParticleDot(index: i)
                    }
                }
                
                NavigationLink(
                    destination: BitFlowMapWebView().navigationBarHidden(true),
                    isActive: $viewModel.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $viewModel.navigateToMain
                ) { EmptyView() }
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Logo mark
                    ZStack {
                        // Glow ring
                        Circle()
                            .stroke(
                                LinearGradient.bfmCyanGlow,
                                lineWidth: 2
                            )
                            .frame(width: 100, height: 100)
                            .blur(radius: glowRadius)
                            .opacity(logoOpacity)
                        
                        Circle()
                            .fill(Color.bfmSurface)
                            .frame(width: 90, height: 90)
                            .overlay(
                                BranchIcon()
                                    .frame(width: 50, height: 50)
                            )
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                    }
                    
                    // Title
                    VStack(spacing: 6) {
                        Text("Bit Flow Map")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.bfmCyan, .bfmPurpleLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(titleOpacity)
                        
                        Text("Decision Intelligence")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.bfmTextSecondary)
                            .tracking(3)
                            .opacity(subtitleOpacity)
                    }
                    
                    Spacer()
                    
                    // Loading line
                    VStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.bfmSurface)
                                .frame(width: 160, height: 3)
                            Capsule()
                                .fill(LinearGradient.bfmCyanGlow)
                                .frame(width: 160 * lineProgress, height: 3)
                        }
                        Text("Loading...")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.bfmTextTertiary)
                            .opacity(subtitleOpacity)
                    }
                    .padding(.bottom, 48)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                    glowRadius = 8
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                    titleOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                    subtitleOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
                    particlesVisible = true
                }
                withAnimation(.easeInOut(duration: 15.0).delay(0.5)) {
                    lineProgress = 1.0
                }
            }
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                BitFlowMapConsentView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                OfflineView()
            }
            .onAppear {
                NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
                    .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
                    .sink { data in
                        viewModel.feedAttribution(data)
                    }
                    .store(in: &cancellables)
                
                NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
                    .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
                    .sink { data in
                        viewModel.feedDeeplinks(data)
                    }
                    .store(in: &cancellables)
                setupNetworkMonitoring()
                viewModel.boot()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                viewModel.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
}

struct BranchIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let cx = w / 2
            let startY = h * 0.1
            let midY = h * 0.45
            let endY = h * 0.9

            // Main trunk
            var trunk = Path()
            trunk.move(to: CGPoint(x: cx, y: startY))
            trunk.addLine(to: CGPoint(x: cx, y: midY))
            ctx.stroke(trunk, with: .color(Color.bfmCyan), lineWidth: 2.5)

            // Left branch
            var left = Path()
            left.move(to: CGPoint(x: cx, y: midY))
            left.addLine(to: CGPoint(x: cx - w * 0.3, y: endY))
            ctx.stroke(left, with: .color(Color.bfmCyan.opacity(0.8)), lineWidth: 2)

            // Center branch
            var center = Path()
            center.move(to: CGPoint(x: cx, y: midY))
            center.addLine(to: CGPoint(x: cx, y: endY))
            ctx.stroke(center, with: .color(Color.bfmPurpleLight.opacity(0.8)), lineWidth: 2)

            // Right branch
            var right = Path()
            right.move(to: CGPoint(x: cx, y: midY))
            right.addLine(to: CGPoint(x: cx + w * 0.3, y: endY))
            ctx.stroke(right, with: .color(Color.bfmCyan.opacity(0.8)), lineWidth: 2)

            // Dots at endpoints
            for point in [
                CGPoint(x: cx, y: startY),
                CGPoint(x: cx, y: midY),
                CGPoint(x: cx - w * 0.3, y: endY),
                CGPoint(x: cx, y: endY),
                CGPoint(x: cx + w * 0.3, y: endY)
            ] {
                ctx.fill(Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)),
                         with: .color(Color.bfmCyan))
            }
        }
    }
}

struct ParticleDot: View {
    let index: Int
    @State private var opacity: Double = 0
    @State private var offset: CGSize = .zero

    var body: some View {
        Circle()
            .fill(index % 3 == 0 ? Color.bfmCyan : index % 3 == 1 ? Color.bfmPurpleLight : Color.bfmGold)
            .frame(width: CGFloat.random(in: 2...5))
            .opacity(opacity)
            .offset(offset)
            .onAppear {
                let angle = Double(index) * (360.0 / 20.0) * .pi / 180
                let radius = CGFloat.random(in: 80...200)
                let dx = cos(angle) * radius
                let dy = sin(angle) * radius
                withAnimation(.easeOut(duration: 1.0).delay(Double.random(in: 0...0.5))) {
                    opacity = Double.random(in: 0.3...0.8)
                    offset = CGSize(width: dx, height: dy)
                }
            }
    }
}

#Preview {
    SplashView()
}

struct BitFlowMapConsentView: View {
    let viewModel: BitFlowViewModel
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.grantConsent()
            } label: {
                Image("bbb")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                viewModel.skipConsent()
            } label: {
                Text("Skip")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("bb")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
}

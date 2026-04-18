import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLogin: Bool = true
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var errorMessage: String = ""
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient.bfmBackground.ignoresSafeArea()
            GlowCircle(color: .bfmCyan, size: 400, opacity: 0.06).offset(x: -80, y: -200)
            GlowCircle(color: .bfmPurple, size: 350, opacity: 0.07).offset(x: 100, y: 200)

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        BranchIcon()
                            .frame(width: 56, height: 56)
                            .padding(16)
                            .background(Color.bfmSurface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.bfmCyan.opacity(0.3), lineWidth: 1))

                        Text("Bit Flow Map")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient.bfmCyanGlow)

                        Text("Decision Intelligence Platform")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.bfmTextSecondary)
                    }
                    .padding(.top, 60)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -20)

                    Spacer().frame(height: 40)

                    // Demo Account Banner
                    Button(action: { appState.loginAsDemo() }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.bfmGold)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Try Demo Account")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.bfmTextPrimary)
                                Text("Explore with pre-loaded scenarios")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.bfmTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.bfmGold.opacity(0.7))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.bfmGold.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.bfmGold.opacity(0.5), lineWidth: 1.5)
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 24)

                    // Divider
                    HStack {
                        Rectangle().fill(Color.bfmTextTertiary.opacity(0.3)).frame(height: 1)
                        Text("or").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundColor(.bfmTextTertiary).padding(.horizontal, 12)
                        Rectangle().fill(Color.bfmTextTertiary.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // Auth form
                    VStack(spacing: 16) {
                        // Tab selector
                        HStack(spacing: 0) {
                            ForEach(["Sign In", "Sign Up"], id: \.self) { tab in
                                Button(tab) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isLogin = (tab == "Sign In")
                                        errorMessage = ""
                                    }
                                }
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor((isLogin ? tab == "Sign In" : tab == "Sign Up") ? .bfmDeepNavy : .bfmTextSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    (isLogin ? tab == "Sign In" : tab == "Sign Up") ?
                                    AnyView(RoundedRectangle(cornerRadius: 10).fill(LinearGradient.bfmCyanGlow)) :
                                    AnyView(Color.clear)
                                )
                            }
                        }
                        .padding(4)
                        .background(Color.bfmSurface)
                        .cornerRadius(14)

                        if !isLogin {
                            BFMTextField(placeholder: "Your name", text: $name, icon: "person.fill")
                        }
                        BFMTextField(placeholder: "Email address", text: $email, icon: "envelope.fill")
                        BFMTextField(placeholder: "Password", text: $password, icon: "lock.fill", isSecure: true)

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.bfmRed)
                                .padding(.horizontal, 4)
                        }

                        Button(isLogin ? "Sign In" : "Create Account") {
                            handleAuth()
                        }
                        .buttonStyle(BFMPrimaryButton())
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }

    func handleAuth() {
        errorMessage = ""
        if isLogin {
            if email.isEmpty || password.isEmpty {
                errorMessage = "Please fill in all fields."
                return
            }
            if !appState.login(email: email, password: password) {
                errorMessage = "Login failed. Try again."
            }
        } else {
            if name.isEmpty || email.isEmpty || password.isEmpty {
                errorMessage = "Please fill in all fields."
                return
            }
            if password.count < 6 {
                errorMessage = "Password must be at least 6 characters."
                return
            }
            if !appState.register(name: name, email: email, password: password) {
                errorMessage = "Registration failed. Try again."
            }
        }
    }
}

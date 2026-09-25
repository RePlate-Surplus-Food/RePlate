//
//  OnboardingView.swift
//  RePlate
//
//  Created by Jyotika Sadani on 5/26/26.
//  Auth flow — RePlate 2.0:
//    • OnboardingView       → 3-slide paginated welcome flow
//    • AuthenticationView   → "Join the Movement" card-picker
//    • SignInView           → labeled form + Sign in with Apple
//    • SignUpView           → customer account creation
//    • RestaurantSignUpView → dedicated 3-step restaurant wizard
//

import SwiftUI
import PhotosUI
import CoreLocation
import Supabase

// MARK: - Reusable App Logo Mark
struct RePlateIconView: View {
    var size: CGFloat = 80

    var body: some View {
        Image("RePlateLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

// MARK: - Onboarding Page Data
private struct OnboardingPageData {
    let icon: String
    let iconColors: [Color]
    let badge: String
    let badgeIcon: String
    let title: String
    let subtitle: String
    let highlights: [(icon: String, label: String, color: Color)]
}

// MARK: - Onboarding View (3-slide paginated flow)
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var showAuth    = false
    @State private var showSignIn  = false
    @State private var blobPhase   = false

    private let pages: [OnboardingPageData] = [
        .init(
            icon: "fork.knife",
            iconColors: [Color(hex: "118b50"), Color(hex: "5db996")],
            badge: "50–80% off",
            badgeIcon: "tag.fill",
            title: "Rescue Surplus Food",
            subtitle: "Restaurants post their daily leftovers at a fraction of the original price.",
            highlights: [
                ("bag.fill",   "Same-day pickup",    Color(hex: "118b50")),
                ("sparkles",   "Fresh & verified",   Color(hex: "5db996")),
                ("percent",    "Up to 80% savings",  Color(hex: "3aa76d")),
            ]
        ),
        .init(
            icon: "leaf.fill",
            iconColors: [Color(hex: "3aa76d"), Color(hex: "5db996")],
            badge: "1M+ meals rescued",
            badgeIcon: "globe.americas.fill",
            title: "Every Meal Counts",
            subtitle: "Join thousands reducing food waste and carbon emissions, one meal at a time.",
            highlights: [
                ("scalemass.fill",  "2.3M lbs food saved",    Color(hex: "118b50")),
                ("cloud.fill",      "3.2M kg CO₂ prevented",  Color(hex: "5db996")),
                ("person.3.fill",   "40K+ happy customers",   Color(hex: "3aa76d")),
            ]
        ),
        .init(
            icon: "heart.fill",
            iconColors: [Color(hex: "118b50"), Color(hex: "5db996")],
            badge: "Community",
            badgeIcon: "heart.fill",
            title: "Be Part of the Change",
            subtitle: "A growing community of food-lovers and local restaurants making a real difference.",
            highlights: [
                ("building.2.fill",     "500+ partner restaurants",  Color(hex: "118b50")),
                ("star.fill",           "4.8 avg rating",            Color(hex: "5db996")),
                ("arrow.2.circlepath",  "Zero food wasted",          Color(hex: "3aa76d")),
            ]
        ),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Theme.Colors.primaryGradientStart.opacity(0.07),
                    Theme.Colors.primaryGradientEnd.opacity(0.03),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            blobBackground
            VStack(spacing: 0) {
                skipRow
                pageCarousel
                pageIndicators
                bottomActions.padding(.bottom, 48)
            }
        }
        .fullScreenCover(isPresented: $showAuth)  { AuthenticationView() }
        .sheet(isPresented: $showSignIn)           { SignInView() }
    }

    @ViewBuilder
    private var skipRow: some View {
        HStack {
            Spacer()
            if currentPage < pages.count - 1 {
                Button("Skip") {
                    hapticFeedback(.light)
                    withAnimation(.easeInOut(duration: 0.35)) { currentPage = pages.count - 1 }
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryLabel)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var pageCarousel: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                OnboardingPageView(page: page).tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.35), value: currentPage)
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? Theme.Colors.primaryGradientStart : Color(.systemGray4))
                    .frame(width: i == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
            }
        }
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var bottomActions: some View {
        if currentPage < pages.count - 1 {
            nextPageButton
        } else {
            finalPageButtons
        }
    }

    private var nextPageButton: some View {
        Button {
            hapticFeedback(.light)
            withAnimation(.easeInOut(duration: 0.35)) { currentPage += 1 }
        } label: {
            HStack(spacing: 8) {
                Text("Next").font(.system(size: 17, weight: .bold, design: .rounded))
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(Theme.Colors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.35), radius: 12, y: 5)
        }
        .padding(.horizontal, 24)
    }

    private var finalPageButtons: some View {
        VStack(spacing: 12) {
            Button { hapticFeedback(.medium); showAuth = true } label: {
                Text("Get Started")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Theme.Colors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.35), radius: 12, y: 5)
            }
            Button { hapticFeedback(.light); showSignIn = true } label: {
                Text("Log In")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.Colors.primaryGradientStart)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(.systemGray5), lineWidth: 1))
            }
        }
        .padding(.horizontal, 24)
    }

    private var blobBackground: some View {
        ZStack {
            // Top-left: deep green
            Circle()
                .fill(Theme.Colors.primaryGradientStart.opacity(0.45))
                .frame(width: 340)
                .blur(radius: 75)
                .offset(x: blobPhase ? -100 : -60, y: blobPhase ? -240 : -180)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: blobPhase)
            // Bottom-right: teal
            Circle()
                .fill(Theme.Colors.primaryGradientEnd.opacity(0.50))
                .frame(width: 320)
                .blur(radius: 70)
                .offset(x: blobPhase ? 150 : 100, y: blobPhase ? 360 : 290)
                .animation(.easeInOut(duration: 11).repeatForever(autoreverses: true), value: blobPhase)
            // Bottom-left: lime accent
            Circle()
                .fill(Theme.Colors.accent.opacity(0.55))
                .frame(width: 270)
                .blur(radius: 65)
                .offset(x: blobPhase ? -130 : -80, y: blobPhase ? 280 : 340)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true).delay(1), value: blobPhase)
            // Top-right: primary light
            Circle()
                .fill(Theme.Colors.primaryLight.opacity(0.42))
                .frame(width: 220)
                .blur(radius: 60)
                .offset(x: blobPhase ? 160 : 110, y: blobPhase ? -190 : -130)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true).delay(0.5), value: blobPhase)
        }
        .ignoresSafeArea()
        .onAppear { blobPhase = true }
    }
}

// MARK: - Onboarding Page View
private struct OnboardingPageView: View {
    let page: OnboardingPageData

    var body: some View {
        VStack(spacing: 0) {
            // Hero circle + badge
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: page.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 176, height: 176)
                        .shadow(color: page.iconColors[0].opacity(0.35), radius: 24, y: 8)
                    Image("RePlateLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 142, height: 142)
                        .offset(x: -6, y: -8)
                }
                .overlay(Circle().stroke(Theme.Colors.accent, lineWidth: 3))

                HStack(spacing: 4) {
                    Image(systemName: page.badgeIcon)
                        .font(.system(size: 9, weight: .bold))
                    Text(page.badge)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                }
                .foregroundColor(Theme.Colors.primaryGradientStart)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.Colors.accent)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
                .offset(x: 12, y: -6)
            }
            .padding(.bottom, 26)

            // Title + subtitle
            VStack(spacing: 10) {
                Text(page.title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)
            }
            .padding(.bottom, 24)

            // Highlights
            VStack(spacing: 10) {
                ForEach(Array(page.highlights.enumerated()), id: \.offset) { _, h in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(h.color.opacity(0.14))
                                .frame(width: 40, height: 40)
                            Image(systemName: h.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(h.color)
                        }
                        Text(h.label)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(h.color.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .liquidGlass(cornerRadius: 16)
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 20)
        .padding(.horizontal, 16)
    }
}

// MARK: - Authentication View  (Figma 2.0 — "Join the Movement")
struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var showSignIn           = false
    @State private var showRestaurantSignUp = false
    @State private var showCustomerSignUp   = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            Circle()
                .fill(Theme.Colors.primaryGradientStart.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: -80, y: -140)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray6))
                                .frame(width: 42, height: 42)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 28)

                    Text("Join the Movement")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.Colors.label)

                    Text("Choose your role in reducing food waste.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryLabel)
                        .padding(.top, 6)
                        .padding(.bottom, 36)

                    AccountTypePickerCard(
                        icon: "fork.knife",
                        title: "Restaurant",
                        description: "Post surplus food and track your impact.",
                        accentColor: Theme.Colors.primaryGradientStart
                    ) {
                        hapticFeedback(.medium)
                        showRestaurantSignUp = true
                    }
                    .padding(.bottom, 20)

                    AccountTypePickerCard(
                        icon: "person.fill",
                        title: "Customer",
                        description: "Discover and claim fresh surplus meals.",
                        accentColor: Theme.Colors.primaryGradientEnd
                    ) {
                        hapticFeedback(.medium)
                        showCustomerSignUp = true
                    }

                    Text("You can always change this later in settings")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.tertiaryLabel)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 36)
                        .padding(.bottom, 16)

                    Button {
                        hapticFeedback(.light)
                        showSignIn = true
                    } label: {
                        Text("Already have an account?  \(Text("Log In").foregroundColor(Theme.Colors.primaryGradientStart))")
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showSignIn)            { SignInView() }
        .sheet(isPresented: $showRestaurantSignUp)  { RestaurantSignUpView() }
        .sheet(isPresented: $showCustomerSignUp)    { SignUpView(accountType: .customer) }
    }
}

// MARK: - Account Type Picker Card
private struct AccountTypePickerCard: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 90, height: 90)
                .padding(.leading, 8)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(accentColor.opacity(0.12))
                                .frame(width: 28, height: 28)
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(accentColor)
                        }
                        Text(title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                    }
                    Text(description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 16)

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 34, height: 34)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .liquidGlass(cornerRadius: 28)
            .shadow(color: Color.black.opacity(0.07), radius: 14, y: 5)
        }
        .buttonStyle(SpringyButtonStyle())
    }
}

// MARK: - Springy Button Style
private struct SpringyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Sign In View
struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var email        = ""
    @State private var password     = ""
    @State private var isLoading    = false
    @State private var showError    = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    signInHeading
                    signInFields
                    signInButton
                    orDivider
                    socialSignInButtons
                    demoHint
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle().fill(Color(.systemGray6)).frame(width: 36, height: 36)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage) }
        }
    }

    private var signInHeading: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Welcome Back")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.Colors.label)
                .padding(.top, 32)
            Text("Sign in to your RePlate account")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryLabel)
                .padding(.top, 6)
                .padding(.bottom, 40)
        }
    }

    private var signInFields: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                AuthLabeledField(label: "Email", placeholder: "you@example.com",
                                 text: $email, keyboardType: .emailAddress)
                    .textInputAutocapitalization(.never)
                AuthLabeledField(label: "Password", placeholder: "Your password",
                                 text: $password, isSecure: true)
            }
            .padding(.bottom, 12)

            Button("Forgot Password?") {}
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryGradientStart)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, 28)
        }
    }

    private var signInButton: some View {
        Button { Task { await signIn() } } label: {
            ZStack {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(Theme.Colors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.30), radius: 12, y: 5)
        }
        .disabled(isLoading)
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color(.systemGray5)).frame(height: 1)
            Text("or")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Theme.Colors.tertiaryLabel)
            Rectangle().fill(Color(.systemGray5)).frame(height: 1)
        }
        .padding(.vertical, 20)
    }

    private var socialSignInButtons: some View {
        VStack(spacing: 12) {
            socialButton(
                label: "Continue with Google",
                icon: nil, googleLogo: true,
                background: Color(.systemBackground),
                border: Color(.systemGray4),
                foreground: Color.primary
            ) {
                Task {
                    isLoading = true
                    defer { isLoading = false }
                    let auth = RePlateAuthService.shared
                    if await auth.signInWithGoogle() {
                        appState.isAuthenticated = true
                        appState.currentUser = auth.currentUser
                        appState.completeOnboarding()
                        dismiss()
                    }
                }
            }

            socialButton(
                label: "Continue with Apple",
                icon: "apple.logo",
                googleLogo: false,
                background: Color.black,
                border: Color.clear,
                foreground: .white
            ) {
                Task {
                    isLoading = true
                    defer { isLoading = false }
                    let auth = RePlateAuthService.shared
                    if await auth.signInWithApple() {
                        appState.isAuthenticated = true
                        appState.currentUser = auth.currentUser
                        appState.completeOnboarding()
                        dismiss()
                    }
                }
            }
        }
        .disabled(isLoading)
    }

    @ViewBuilder
    private func socialButton(
        label: String,
        icon: String?,
        googleLogo: Bool,
        background: Color,
        border: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: { hapticFeedback(.medium); action() }) {
            HStack(spacing: 10) {
                if googleLogo {
                    // Google "G" rendered with brand colours using two half-circles
                    GoogleLogoMark()
                        .frame(width: 20, height: 20)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(foreground)
                }
                Text(label)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(foreground)
            }
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(background == Color(.systemBackground) ? 0.06 : 0),
                    radius: 6, y: 2)
        }
    }

    private var demoHint: some View {
        Text("Don't have an account? Go back and sign up.")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Theme.Colors.tertiaryLabel)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
    }

    func signIn() async {
        // OWASP A03: validate email format and password length before hitting the network
        do {
            let _ = try Validators.email(email)
            let _ = try Validators.password(password)
        } catch let e as InputValidationError {
            errorMessage = e.errorDescription ?? "Invalid input."
            showError = true
            return
        } catch {}
        isLoading = true
        defer { isLoading = false }

        let auth: RePlateAuthService = RePlateAuthService.shared
        let success = await auth.signIn(email: email, password: password)
        if success {
            appState.isAuthenticated = true
            appState.currentUser = auth.currentUser
            appState.completeOnboarding()
            dismiss()
        } else {
            errorMessage = auth.errorMessage ?? "Invalid email or password"
            showError = true
        }
    }
}

// MARK: - Sign Up View (customer)
struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let accountType: User.AccountType

    @State private var name          = ""
    @State private var email         = ""
    @State private var password      = ""
    @State private var isLoading     = false
    @State private var showError     = false
    @State private var errorMessage  = ""
    @State private var agreedToTerms = false
    @State private var showLegalPage: LegalPageView.LegalPage? = nil
    @State private var avatarPhoto: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var locationGranted = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Join RePlate and start saving food")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryLabel)
                        .padding(.top, 8)
                        .padding(.bottom, 28)

                    customerPhotoUpload.padding(.bottom, 28)

                    VStack(spacing: 18) {
                        AuthLabeledField(label: "Full Name", placeholder: "Your name", text: $name)

                        AuthLabeledField(
                            label: "Email",
                            placeholder: "you@example.com",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        .textInputAutocapitalization(.never)

                        AuthLabeledField(
                            label: "Password",
                            placeholder: "Create a secure password",
                            text: $password,
                            isSecure: true
                        )
                    }
                    .padding(.bottom, 24)

                    locationPermissionButton.padding(.bottom, 8)
                    Text("We need your location to show surplus food near you")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.tertiaryLabel)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 20)

                    // Terms consent checkbox
                    HStack(alignment: .top, spacing: 12) {
                        Button {
                            hapticFeedback(.light)
                            agreedToTerms.toggle()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(agreedToTerms ? Theme.Colors.primaryGradientStart : Color(.systemGray6))
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(agreedToTerms ? Color.clear : Color(.systemGray4), lineWidth: 1.5)
                                    )
                                if agreedToTerms {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text("I have read and agree to the \(Text("Terms of Service").bold().foregroundColor(Theme.Colors.primaryGradientStart)) and \(Text("Privacy Policy").bold().foregroundColor(Theme.Colors.primaryGradientStart))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                        .onTapGesture { showLegalPage = .termsOfService }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 20)

                    Button {
                        Task { await signUp() }
                    } label: {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(agreedToTerms ? Theme.Colors.primaryGradient : LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Theme.Colors.primaryGradientStart.opacity(agreedToTerms ? 0.30 : 0), radius: 12, y: 5)
                    }
                    .disabled(isLoading || !agreedToTerms)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle().fill(Color(.systemGray6)).frame(width: 36, height: 36)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(item: $showLegalPage) { page in
                NavigationView { LegalPageView(page: page) }
            }
        }
    }

    private var customerPhotoUpload: some View {
        PhotosPicker(selection: $avatarPhoto, matching: .images) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 96, height: 96)
                    if let avatarImage {
                        avatarImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .strokeBorder(Color(.systemGray4),
                                          style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                            .frame(width: 96, height: 96)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Theme.Colors.tertiaryLabel)
                    }
                    // Camera badge overlay
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.primaryGradientStart)
                            .frame(width: 28, height: 28)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 32, y: 32)
                }
                Text(avatarImage == nil ? "Add Photo" : "Change Photo")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: avatarPhoto) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    avatarImage = Image(uiImage: ui)
                }
            }
        }
    }

    private var locationPermissionButton: some View {
        Button {
            hapticFeedback(.light)
            LocationService.shared.requestPermission()
            locationGranted = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: locationGranted ? "location.fill" : "location")
                    .font(.system(size: 15, weight: .semibold))
                Text(locationGranted ? "Location Access Enabled" : "Allow Location Access")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(locationGranted ? Theme.Colors.primaryGradientStart : Theme.Colors.label)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                locationGranted
                    ? Theme.Colors.primaryGradientStart.opacity(0.12)
                    : Color(.systemGray6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        locationGranted ? Theme.Colors.primaryGradientStart.opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .disabled(locationGranted)
    }

    func signUp() async {
        // OWASP A03: validate and sanitize all fields before sending to Supabase
        do {
            let _ = try Validators.name(name, field: "Name")
            let _ = try Validators.email(email)
            let _ = try Validators.password(password)
        } catch let e as InputValidationError {
            errorMessage = e.errorDescription ?? "Invalid input."
            showError = true
            return
        } catch {}
        isLoading = true
        defer { isLoading = false }

        let auth: RePlateAuthService = RePlateAuthService.shared
        let success = await auth.signUp(
            name: name, email: email, password: password, accountType: accountType
        )
        if success {
            UserDefaults.standard.set(true, forKey: "acceptedTerms")
            UserDefaults.standard.set(Date(), forKey: "acceptedTermsAt")
            if let uid = auth.currentUser?.id {
                try? await supabase.from("profiles")
                    .update(["terms_accepted_at": ISO8601DateFormatter().string(from: Date())])
                    .eq("id", value: uid)
                    .execute()
            }
            appState.isAuthenticated = true
            appState.currentUser = auth.currentUser
            appState.completeOnboarding()
            dismiss()
        } else {
            errorMessage = auth.errorMessage ?? "Could not create account"
            showError = true
        }
    }
}

// MARK: - Restaurant Sign Up View (dedicated 3-step wizard)
struct RestaurantSignUpView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var step = 1

    // Step 1 — Business info
    @State private var restaurantName = ""
    @State private var cuisineType    = ""
    @State private var logoPhoto: PhotosPickerItem?
    @State private var logoImage: Image?

    // Step 2 — Location & contact (split address fields)
    @State private var streetLine1     = ""
    @State private var streetLine2     = ""
    @State private var city            = ""
    @State private var addressState    = ""
    @State private var zipCode         = ""
    @State private var rawPhone        = ""
    @State private var schedule        = DaySchedule.defaultSchedule()
    @State private var locationGranted = false

    // Step 3 — Account credentials
    @State private var email    = ""
    @State private var password = ""
    @State private var showVerification = false
    @State private var agreedToTerms = false
    @State private var showLegalPage: LegalPageView.LegalPage? = nil

    // UI state
    @State private var isLoading    = false
    @State private var showError    = false
    @State private var errorMessage = ""
    @State private var showSignIn   = false

    private var formattedPhone: String {
        let d = rawPhone.filter { $0.isNumber }
        var r = ""
        for (i, ch) in d.prefix(10).enumerated() {
            switch i {
            case 0: r = "(\(ch)"; case 1,2: r += String(ch); case 3: r += ") \(ch)"
            case 4,5: r += String(ch); case 6: r += "-\(ch)"; default: r += String(ch)
            }
        }
        return r
    }

    private let cuisineTypes = [
        "Italian", "Indian", "Mexican", "American",
        "Mediterranean", "Chinese", "Japanese", "Korean",
        "Thai", "Asian Fusion", "Bakery & Café", "Desserts",
        "Breakfast", "Lunch", "Dinner", "Snacks", "Other",
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                progressHeader

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        Color.clear.frame(height: 0).id("top")
                        Group {
                            switch step {
                            case 1:  step1BusinessInfo
                            case 2:  step2LocationContact
                            default: step3Account
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .padding(.bottom, 20)

                        // Already have an account
                        Button {
                            hapticFeedback(.light)
                            showSignIn = true
                        } label: {
                            Text("Already have an account?  \(Text("Sign In").foregroundColor(Theme.Colors.primaryGradientStart).bold())")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                        .padding(.bottom, 40)
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: step)
                    .onChange(of: step) { _, _ in
                        withAnimation { proxy.scrollTo("top", anchor: .top) }
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle().fill(Color(.systemGray6)).frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showVerification) { RestaurantVerificationView() }
            .sheet(item: $showLegalPage) { page in
                NavigationView { LegalPageView(page: page) }
            }
            .sheet(isPresented: $showSignIn) {
                SignInView().environmentObject(appState)
            }
        }
        .onChange(of: logoPhoto) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) { logoImage = Image(uiImage: ui) }
            }
        }
    }

    // MARK: Progress Header
    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { s in
                    Capsule()
                        .fill(s <= step
                              ? Theme.Colors.primaryGradientStart
                              : Color(.systemGray5))
                        .frame(height: 5)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: step)
                }
            }
            .padding(.horizontal, 24)

            Text(stepLabel)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.tertiaryLabel)
        }
        .padding(.vertical, 14)
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
    }

    private var stepLabel: String {
        switch step {
        case 1:  return "Step 1 of 3 — Business Info"
        case 2:  return "Step 2 of 3 — Location & Contact"
        default: return "Step 3 of 3 — Create Account"
        }
    }

    // MARK: Step 1 — Business Info
    private var step1BusinessInfo: some View {
        VStack(alignment: .leading, spacing: 28) {
            stepHeading(title: "Tell us about your restaurant",
                        subtitle: "This appears on your public profile.")

            // Logo upload zone — PhotosPicker
            PhotosPicker(selection: $logoPhoto, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Theme.Colors.primaryGradientStart.opacity(0.05))
                        .frame(height: 120)
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Theme.Colors.primaryGradientStart.opacity(0.25),
                                      style: StrokeStyle(lineWidth: 2, dash: [10, 6]))
                        .frame(height: 120)
                    if let logoImage {
                        logoImage.resizable().scaledToFill()
                            .frame(height: 120).clipShape(RoundedRectangle(cornerRadius: 24))
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "photo.badge.plus.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(Theme.Colors.primaryGradient)
                            Text("Tap to Upload Logo")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: 24))
                .frame(height: 120)
            }

            AuthLabeledField(
                label: "Restaurant Name",
                placeholder: "e.g., Bella's Italian Kitchen",
                text: $restaurantName
            )

            // Cuisine type chips
            VStack(alignment: .leading, spacing: 10) {
                Text("CUISINE TYPE")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.tertiaryLabel)
                    .tracking(1.2)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2),
                    spacing: 10
                ) {
                    ForEach(cuisineTypes, id: \.self) { type in
                        Button {
                            hapticFeedback(.light)
                            cuisineType = type
                        } label: {
                            Text(type)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(cuisineType == type ? .white : Theme.Colors.label)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    cuisineType == type
                                        ? Theme.Colors.primaryGradient
                                        : LinearGradient(colors: [Color(.systemGray6)],
                                                         startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            nextOnlyButton(label: "Next: Location & Contact") {
                guard !restaurantName.isEmpty else {
                    errorMessage = "Please enter your restaurant name"
                    showError = true
                    return
                }
                advance()
            }
        }
    }

    // Computed full address used for storage / validation
    private var address: String {
        var parts = [streetLine1]
        if !streetLine2.isEmpty { parts.append(streetLine2) }
        if !city.isEmpty { parts.append(city) }
        let stateZip = [addressState, zipCode].filter { !$0.isEmpty }.joined(separator: " ")
        if !stateZip.isEmpty { parts.append(stateZip) }
        return parts.joined(separator: ", ")
    }

    // MARK: Step 2 — Location & Contact
    private var step2LocationContact: some View {
        VStack(alignment: .leading, spacing: 28) {
            stepHeading(title: "Where are you located?",
                        subtitle: "Customers use this to find you.")

            VStack(spacing: 18) {
                // Multi-box address section
                VStack(alignment: .leading, spacing: 6) {
                    Text("ADDRESS")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.tertiaryLabel)
                        .tracking(1.2)

                    VStack(spacing: 2) {
                        // Street line 1
                        addressBox(placeholder: "Street address", text: $streetLine1)
                        Divider().background(Color(.systemGray4))
                        // Street line 2
                        addressBox(placeholder: "Apt, suite, floor (optional)", text: $streetLine2)
                        Divider().background(Color(.systemGray4))
                        // City / State / ZIP row
                        HStack(spacing: 0) {
                            addressBox(placeholder: "City", text: $city)
                                .frame(maxWidth: .infinity)
                            Divider().background(Color(.systemGray4)).frame(height: 48)
                            addressBox(placeholder: "State", text: $addressState)
                                .frame(width: 72)
                            Divider().background(Color(.systemGray4)).frame(height: 48)
                            addressBox(placeholder: "ZIP", text: $zipCode, keyboard: .numberPad)
                                .frame(width: 80)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                // Auto-formatted phone
                VStack(alignment: .leading, spacing: 6) {
                    Text("PHONE NUMBER")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.tertiaryLabel).tracking(1.2)
                    HStack {
                        TextField("(555) 123-4567", text: $rawPhone)
                            .keyboardType(.numberPad)
                            .onChange(of: rawPhone) { _, v in
                                let d = v.filter { $0.isNumber }
                                rawPhone = String(d.prefix(10))
                            }
                        if !formattedPhone.isEmpty {
                            Text(formattedPhone)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                    }
                    .padding(.horizontal, 18).padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                // Per-day hours table
                VStack(alignment: .leading, spacing: 8) {
                    Text("BUSINESS HOURS")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.tertiaryLabel)
                        .tracking(1.2)
                    OperatingHoursTable(schedule: $schedule)
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                        Text("Tap a day's times to set open and close hours.")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                    }
                }
            }

            // Use current location — requests CoreLocation permission
            Button {
                hapticFeedback(.light)
                locationGranted = true
                LocationService.shared.requestPermission()
                // Pre-fill from device location string when available
                let locStr = LocationService.shared.locationString
                if !locStr.isEmpty && locStr != "San Francisco, CA" {
                    let parts = locStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    city = parts.first ?? ""
                    addressState = parts.dropFirst().first ?? ""
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(locationGranted ? Color(hex:"118b50").opacity(0.12) : Theme.Colors.primaryGradientStart.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: locationGranted ? "location.fill" : "location")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(locationGranted ? Color(hex:"118b50") : Theme.Colors.primaryGradientStart)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(locationGranted ? "Location Granted" : "Use Current Location")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                        Text(locationGranted ? "Address auto-filled" : "Auto-fill your address")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                    }
                    Spacer()
                    Image(systemName: locationGranted ? "checkmark.circle.fill" : "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(locationGranted ? Color(hex:"118b50") : Theme.Colors.tertiaryLabel)
                }
                .padding(14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            backNextRow {
                guard !streetLine1.isEmpty, !city.isEmpty else {
                    errorMessage = "Please enter your street address and city"
                    showError = true
                    return
                }
                advance()
            }
        }
    }

    // MARK: Step 3 — Account Credentials
    private var step3Account: some View {
        VStack(alignment: .leading, spacing: 28) {
            stepHeading(title: "Create your account",
                        subtitle: "You'll use these to log in to RePlate.")

            VStack(spacing: 18) {
                AuthLabeledField(label: "Business Email",
                                 placeholder: "hello@yourrestaurant.com",
                                 text: $email,
                                 keyboardType: .emailAddress)
                    .textInputAutocapitalization(.never)
                AuthLabeledField(label: "Password",
                                 placeholder: "Min. 8 characters",
                                 text: $password,
                                 isSecure: true)
            }

            // Password strength bar
            if !password.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(strengthColor(bar: i))
                                .frame(maxWidth: .infinity)
                                .frame(height: 4)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: password.count)
                    Text(strengthLabel)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(strengthColor(bar: 0))
                }
            }

            // Verify Business — opens full verification wizard
            Button {
                hapticFeedback(.light)
                showVerification = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.primaryGradientStart.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.primaryGradientStart)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Verify Your Business")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                        Text("Required to post food listings")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.tertiaryLabel)
                }
                .padding(14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            // Terms consent checkbox
            HStack(alignment: .top, spacing: 12) {
                Button {
                    hapticFeedback(.light)
                    agreedToTerms.toggle()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(agreedToTerms ? Theme.Colors.primaryGradientStart : Color(.systemGray6))
                            .frame(width: 22, height: 22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(agreedToTerms ? Color.clear : Color(.systemGray4), lineWidth: 1.5)
                            )
                        if agreedToTerms {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Text("I have read and agree to the \(Text("Terms of Service").bold().foregroundColor(Theme.Colors.primaryGradientStart)) and \(Text("Privacy Policy").bold().foregroundColor(Theme.Colors.primaryGradientStart))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryLabel)
                .onTapGesture { showLegalPage = .termsOfService }
                .fixedSize(horizontal: false, vertical: true)
            }

            // Back + Create Account
            HStack(spacing: 12) {
                backButton

                Button {
                    Task { await createAccount() }
                } label: {
                    ZStack {
                        if isLoading {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        } else {
                            HStack(spacing: 8) {
                                Text("Create Account")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .black))
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(agreedToTerms ? Theme.Colors.primaryGradient : LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Theme.Colors.primaryGradientStart.opacity(agreedToTerms ? 0.3 : 0), radius: 10, y: 5)
                }
                .disabled(isLoading || !agreedToTerms)
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: Reusable sub-views
    // Reusable single cell inside the grouped address block
    @ViewBuilder
    private func addressBox(placeholder: String,
                            text: Binding<String>,
                            keyboard: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .font(.system(size: 15, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
    }

    private func stepHeading(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.Colors.label)
            Text(subtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryLabel)
        }
    }

    private func nextOnlyButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label).font(.system(size: 16, weight: .bold, design: .rounded))
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .black))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.Colors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.3), radius: 10, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func backNextRow(onNext: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            backButton
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text("Next").font(.system(size: 16, weight: .bold, design: .rounded))
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .black))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.Colors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.3), radius: 10, y: 5)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var backButton: some View {
        Button {
            hapticFeedback(.light)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { step -= 1 }
        } label: {
            Text("Back")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryLabel)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private func advance() {
        hapticFeedback(.light)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { step += 1 }
    }

    private var strengthLabel: String {
        switch password.count {
        case 0..<6:  return "Too short"
        case 6..<8:  return "Weak"
        case 8..<12: return "Fair"
        default:     return "Strong"
        }
    }

    private func strengthColor(bar: Int) -> Color {
        let filled = min(password.count / 3, 4)
        let palette: [Color] = [.red, .orange, Color(hex: "5db996"), Color(hex: "118b50")]
        return bar < filled ? palette[min(filled - 1, palette.count - 1)] : Color(.systemGray5)
    }

    private func createAccount() async {
        // OWASP A03: validate restaurant name, email, and password before network call
        do {
            let _ = try Validators.name(restaurantName, field: "Restaurant name")
            let _ = try Validators.email(email)
            let _ = try Validators.password(password)
        } catch let e as InputValidationError {
            errorMessage = e.errorDescription ?? "Invalid input."
            showError = true
            return
        } catch {}
        isLoading = true
        defer { isLoading = false }

        let auth: RePlateAuthService = RePlateAuthService.shared
        let success = await auth.signUp(
            name: restaurantName,
            email: email,
            password: password,
            accountType: .restaurant
        )
        if success {
            UserDefaults.standard.set(true, forKey: "acceptedTerms")
            UserDefaults.standard.set(Date(), forKey: "acceptedTermsAt")

            // Save restaurant row to Supabase
            if let userId = auth.currentUser?.id {
                let fullAddress = [streetLine1, city, addressState, zipCode]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")

                struct RestaurantInsert: Encodable {
                    let owner_id: String
                    let name: String
                    let cuisine: [String]
                    let address: String
                    let phone_number: String
                    let email: String
                    let rating: Double
                    let total_reviews: Int
                    let verified: Bool
                    let is_premium: Bool
                }

                let payload = RestaurantInsert(
                    owner_id: userId,
                    name: restaurantName,
                    cuisine: [cuisineType],
                    address: fullAddress,
                    phone_number: formattedPhone,
                    email: email,
                    rating: 0.0,
                    total_reviews: 0,
                    verified: false,
                    is_premium: false
                )
                try? await supabase.from("restaurants").insert(payload).execute()

                // Upload logo and store URL
                if let logoData = try? await logoPhoto?.loadTransferable(type: Data.self),
                   let ui = UIImage(data: logoData),
                   let jpegData = ui.jpegData(compressionQuality: 0.8) {
                    let logoPath = "\(userId)/logo.jpg"
                    try? await supabase.storage.from("restaurant-images")
                        .upload(logoPath, data: jpegData,
                                options: FileOptions(contentType: "image/jpeg", upsert: true))
                    if let logoUrl = try? supabase.storage.from("restaurant-images").getPublicURL(path: logoPath) {
                        try? await supabase.from("restaurants")
                            .update(["image_url": logoUrl.absoluteString])
                            .eq("owner_id", value: userId)
                            .execute()
                    }
                }
            }

            appState.isAuthenticated = true
            appState.currentUser = auth.currentUser
            appState.completeOnboarding()
            dismiss()
        } else {
            errorMessage = auth.errorMessage ?? "Could not create account"
            showError = true
        }
    }
}

// MARK: - Auth Labeled Field  (label above + bordered input — Figma pattern)
struct AuthLabeledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryLabel)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .font(.system(size: 16, weight: .regular))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        text.isEmpty
                            ? Color.clear
                            : Theme.Colors.primaryGradientStart.opacity(0.4),
                        lineWidth: 1.5
                    )
            )
        }
    }
}

// MARK: - Legacy / Preserved Structs
struct AccountTypeButton: View {
    let type: User.AccountType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: type.icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : Theme.Colors.primaryGradientStart)
                Text(type.displayName)
                    .font(Theme.Typography.headline)
                    .foregroundColor(isSelected ? .white : Theme.Colors.label)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                isSelected
                    ? Theme.Colors.primaryGradient
                    : LinearGradient(
                        colors: [Theme.Colors.secondaryBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
            )
            .cornerRadius(Theme.CornerRadius.xxl)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xxl)
                    .stroke(
                        isSelected ? Color.clear : Theme.Colors.primaryGradientStart.opacity(0.3),
                        lineWidth: 2
                    )
            )
        }
    }
}

// Renders the Google "G" logo using brand colours without requiring an asset.
struct GoogleLogoMark: View {
    var body: some View {
        ZStack {
            // Blue arc (right side)
            Circle()
                .trim(from: 0.08, to: 0.5)
                .stroke(Color(hex: "4285F4"), lineWidth: 4)
            // Red arc (top)
            Circle()
                .trim(from: 0.5, to: 0.75)
                .stroke(Color(hex: "EA4335"), lineWidth: 4)
            // Yellow arc (bottom-left)
            Circle()
                .trim(from: 0.75, to: 1.0)
                .stroke(Color(hex: "FBBC04"), lineWidth: 4)
            // Green arc (bottom-right)
            Circle()
                .trim(from: 0.0, to: 0.08)
                .stroke(Color(hex: "34A853"), lineWidth: 4)
            // Horizontal bar for the G cutout
            Rectangle()
                .fill(Color(hex: "4285F4"))
                .frame(width: 7, height: 4)
                .offset(x: 3, y: 0)
        }
        .rotationEffect(.degrees(-45))
    }
}

struct SocialSignInButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                Text(title).font(Theme.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundColor(Theme.Colors.label)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.xxl)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xxl)
                    .stroke(Theme.Colors.tertiaryLabel, lineWidth: 1)
            )
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(
                    configuration.isOn
                        ? Theme.Colors.primaryGradientStart
                        : Theme.Colors.secondaryLabel
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                    hapticFeedback(.light)
                }
            configuration.label
        }
    }
}

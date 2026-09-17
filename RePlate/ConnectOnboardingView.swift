//
//  ConnectOnboardingView.swift
//  RePlate
//
//  Stripe Connect onboarding for restaurant owners.
//
//  WHAT THIS DOES:
//    Restaurants must onboard to Stripe Connect before they can accept payments.
//    This view shows current onboarding status (fetched live from the API on every
//    appear — never stored in a local database for this demo) and lets the restaurant
//    open the Stripe-hosted onboarding form.
//
//  FLOW:
//    1. View appears → fetches account status from connect-onboarding Edge Function.
//    2. If no Stripe account exists yet → "Create Account" button calls
//       create-connect-account to mint a V2 connected account.
//    3. Once an account exists → shows capability + requirements status.
//    4. "Complete Setup" → calls connect-onboarding (POST) to get a one-time link.
//    5. Link opens in SFSafariViewController inside the app.
//    6. After return → status is refreshed.
//
//  SUPABASE URL:
//    Update SupabaseConfig.url if it changes. The Edge Function paths are
//    assembled below from that base URL.
//

import SwiftUI
import SafariServices
import Supabase

// MARK: - ConnectOnboardingView

struct ConnectOnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    // ── State ─────────────────────────────────────────────────────────────────

    @State private var status: ConnectStatus?
    @State private var isLoadingStatus  = false
    @State private var isLoadingAction  = false
    @State private var errorMessage: String?
    @State private var safariURL: URL?

    // ── Computed ──────────────────────────────────────────────────────────────

    private var baseURL: String { SupabaseConfig.url.absoluteString + "/functions/v1" }
    private var stripeAccountId: String? { appState.currentUser?.stripeAccountId }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerCard
                    statusSection
                    actionSection
                    infoFooter
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Theme.Colors.pageBackground)
            .navigationTitle("Payment Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoadingStatus {
                        ProgressView()
                    } else {
                        Button {
                            hapticFeedback(.light)
                            Task { await fetchStatus() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .task { await fetchStatus() }
            // SFSafariViewController is presented modally when we have a URL
            .sheet(item: $safariURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea()
                    // Refresh status when the user returns from Stripe onboarding
                    .onDisappear { Task { await fetchStatus() } }
            }
        }
    }

    // MARK: - Sub-views

    private var headerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryGradient)
                    .frame(width: 72, height: 72)
                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }

            VStack(spacing: 6) {
                Text("Accept Payments")
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(Theme.Colors.label)

                Text("Complete Stripe Connect onboarding to start receiving payouts when customers buy your surplus food.")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var statusSection: some View {
        if let error = errorMessage {
            // Error state
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.label)
                Spacer()
            }
            .padding(16)
            .background(Color.red.opacity(0.08))
            .cornerRadius(14)

        } else if isLoadingStatus && status == nil {
            // Initial loading skeleton
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.Colors.pageBackground)
                            .frame(height: 20)
                    }
                }
            }
            .padding(16)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(20)
            .redacted(reason: .placeholder)

        } else if let s = status {
            // Live status card
            VStack(alignment: .leading, spacing: 16) {
                Text("Account Status")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.label)

                Divider()

                StatusRow(
                    icon: capabilityIcon(s.cardPaymentsStatus),
                    label: "Card Payments",
                    value: s.cardPaymentsStatus.displayName,
                    color: capabilityColor(s.cardPaymentsStatus)
                )

                StatusRow(
                    icon: requirementsIcon(s.requirementsStatus),
                    label: "Requirements",
                    value: s.requirementsStatus.displayName,
                    color: requirementsColor(s.requirementsStatus)
                )

                StatusRow(
                    icon: s.onboardingComplete ? "checkmark.seal.fill" : "clock.fill",
                    label: "Onboarding",
                    value: s.onboardingComplete ? "Complete" : "In progress",
                    color: s.onboardingComplete ? .green : .orange
                )
            }
            .padding(20)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        if stripeAccountId == nil {
            // No account yet — create one first
            GreenButton(
                title: "Create Payment Account",
                icon: "plus.circle.fill",
                isLoading: isLoadingAction
            ) {
                Task { await createAccount() }
            }
        } else if status?.cardPaymentsStatus == .active && status?.onboardingComplete == true {
            // Fully active — show a celebration and manage button
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("You're ready to accept payments!")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(14)

                // Still let them open the dashboard to manage payout details etc.
                GreenButton(
                    title: "Manage Stripe Account",
                    icon: "arrow.up.forward.square",
                    isLoading: isLoadingAction
                ) {
                    Task { await openOnboardingLink() }
                }
            }
        } else {
            // Account exists but onboarding incomplete or requirements pending
            GreenButton(
                title: "Complete Setup",
                icon: "arrow.up.right.circle.fill",
                isLoading: isLoadingAction
            ) {
                Task { await openOnboardingLink() }
            }
        }
    }

    private var infoFooter: some View {
        VStack(alignment: .leading, spacing: 12) {
            infoRow(icon: "lock.shield.fill", text: "Your bank details are stored securely by Stripe — RePlate never sees them.")
            infoRow(icon: "dollarsign.circle.fill", text: "Payouts go directly from your customers to your bank, minus RePlate's 10% platform fee.")
            infoRow(icon: "clock.fill", text: "First payout typically arrives 2–3 business days after a transaction.")
        }
        .padding(16)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(16)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Theme.Colors.primaryGradientStart)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - API Calls

    /// Fetches account status from the connect-onboarding Edge Function.
    /// NOTE: Per the demo spec, we always fetch live from the API — no local caching.
    private func fetchStatus() async {
        guard let accountId = stripeAccountId else {
            // No account yet — nothing to fetch
            await MainActor.run { isLoadingStatus = false }
            return
        }

        await MainActor.run {
            isLoadingStatus = true
            errorMessage = nil
        }

        do {
            // GET /connect-onboarding?accountId=acct_xxx
            var components = URLComponents(string: "\(baseURL)/connect-onboarding")!
            components.queryItems = [URLQueryItem(name: "accountId", value: accountId)]

            var req = URLRequest(url: components.url!)
            req.httpMethod = "GET"
            // Pass the Supabase anon key so the Edge Function can authenticate the request
            req.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
            if let token = appState.authToken {
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let (data, response) = try await URLSession.shared.data(for: req)

            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                let msg = (try? JSONDecoder().decode(APIError.self, from: data))?.error
                    ?? "Failed to fetch account status"
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: msg])
            }

            let decoded = try JSONDecoder().decode(ConnectStatusResponse.self, from: data)
            await MainActor.run {
                status = decoded.status
                isLoadingStatus = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoadingStatus = false
            }
        }
    }

    /// Creates a new V2 Stripe connected account for this restaurant.
    private func createAccount() async {
        guard let user = appState.currentUser else { return }

        await MainActor.run {
            isLoadingAction = true
            errorMessage = nil
        }

        do {
            var req = URLRequest(url: URL(string: "\(baseURL)/create-connect-account")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
            if let token = appState.authToken {
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            req.httpBody = try JSONEncoder().encode([
                "displayName": user.name,
                "email": user.email,
            ])

            let (data, response) = try await URLSession.shared.data(for: req)

            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                let msg = (try? JSONDecoder().decode(APIError.self, from: data))?.error
                    ?? "Failed to create account"
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: msg])
            }

            let decoded = try JSONDecoder().decode(CreateAccountResponse.self, from: data)

            // Persist the account ID in-memory and to the profiles table
            await MainActor.run {
                appState.currentUser?.stripeAccountId = decoded.accountId
                isLoadingAction = false
            }
            if let uid = supabase.auth.currentSession?.user.id.uuidString {
                try? await supabase
                    .from("profiles")
                    .update(["stripe_account_id": decoded.accountId])
                    .eq("id", value: uid)
                    .execute()
            }

            // Now that the account exists, fetch its initial status
            await fetchStatus()

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoadingAction = false
            }
        }
    }

    /// Requests a one-time Stripe-hosted onboarding link, then opens it in SafariViewController.
    private func openOnboardingLink() async {
        guard let accountId = stripeAccountId else { return }

        await MainActor.run {
            isLoadingAction = true
            errorMessage = nil
        }

        do {
            var req = URLRequest(url: URL(string: "\(baseURL)/connect-onboarding")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
            if let token = appState.authToken {
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let appOrigin = SupabaseConfig.url.absoluteString
            req.httpBody = try JSONEncoder().encode([
                "accountId": accountId,
                "refreshUrl": "\(appOrigin)/onboarding-refresh",  // deep link or web page
                "returnUrl":  "\(appOrigin)/onboarding-return",   // deep link or web page
            ])

            let (data, response) = try await URLSession.shared.data(for: req)

            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                let msg = (try? JSONDecoder().decode(APIError.self, from: data))?.error
                    ?? "Failed to get onboarding link"
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: msg])
            }

            let decoded = try JSONDecoder().decode(OnboardingLinkResponse.self, from: data)

            guard let url = URL(string: decoded.url) else {
                throw URLError(.badURL)
            }

            await MainActor.run {
                isLoadingAction = false
                safariURL = url  // triggers the .sheet to open SFSafariViewController
            }

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoadingAction = false
            }
        }
    }

    // MARK: - Status helpers

    private func capabilityIcon(_ s: CapabilityStatus) -> String {
        switch s {
        case .active:      return "checkmark.circle.fill"
        case .inactive:    return "xmark.circle.fill"
        case .pending:     return "clock.fill"
        case .unrequested: return "minus.circle.fill"
        }
    }

    private func capabilityColor(_ s: CapabilityStatus) -> Color {
        switch s {
        case .active:      return .green
        case .inactive:    return .red
        case .pending:     return .orange
        case .unrequested: return Theme.Colors.secondaryLabel
        }
    }

    private func requirementsIcon(_ s: RequirementsStatus) -> String {
        switch s {
        case .none:        return "checkmark.circle.fill"
        case .pastDue:     return "exclamationmark.circle.fill"
        case .currentlyDue: return "clock.badge.exclamationmark.fill"
        case .eventuallyDue: return "info.circle.fill"
        }
    }

    private func requirementsColor(_ s: RequirementsStatus) -> Color {
        switch s {
        case .none:         return .green
        case .pastDue:      return .red
        case .currentlyDue: return .orange
        case .eventuallyDue: return .yellow
        }
    }
}

// MARK: - Supporting Views

private struct StatusRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.Colors.label)
            Spacer()
            Text(value)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

private struct GreenButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: { hapticFeedback(.medium); action() }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isLoading ? Color.gray : Theme.Colors.primaryGradientStart)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(isLoading)
    }
}

// MARK: - SFSafariViewController wrapper

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let cfg = SFSafariViewController.Configuration()
        cfg.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: cfg)
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// URL is Identifiable so it can be used with .sheet(item:)
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Models

// The status shape mirrors what connect-onboarding's GET endpoint returns.
// Update these if you change the Edge Function's response shape.

private struct ConnectStatusResponse: Decodable {
    let status: ConnectStatus
}

struct ConnectStatus: Decodable {
    let accountId: String
    let readyToProcessPayments: Bool
    let onboardingComplete: Bool
    let cardPaymentsStatus: CapabilityStatus
    let requirementsStatus: RequirementsStatus
}

enum CapabilityStatus: String, Decodable {
    case active      = "active"
    case inactive    = "inactive"
    case pending     = "pending"
    case unrequested = "unrequested"

    var displayName: String {
        switch self {
        case .active:      return "Active"
        case .inactive:    return "Inactive"
        case .pending:     return "Pending review"
        case .unrequested: return "Not requested"
        }
    }
}

enum RequirementsStatus: String, Decodable {
    case none         = "none"
    case pastDue      = "past_due"
    case currentlyDue = "currently_due"
    case eventuallyDue = "eventually_due"

    var displayName: String {
        switch self {
        case .none:          return "All clear"
        case .pastDue:       return "Past due"
        case .currentlyDue:  return "Action needed"
        case .eventuallyDue: return "Due soon"
        }
    }
}

private struct CreateAccountResponse: Decodable {
    let accountId: String
}

private struct OnboardingLinkResponse: Decodable {
    let url: String
}

private struct APIError: Decodable {
    let error: String
}

// MARK: - AppState + User extensions
// These add Stripe-specific fields that don't yet exist on the models.
// Once you have a real database, load stripeAccountId from the DB on sign-in.

extension AppState {
    var authToken: String? { accessToken }
}

// MARK: - Preview

struct ConnectOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectOnboardingView()
            .environmentObject(AppState())
    }
}

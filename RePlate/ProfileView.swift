//
//  ProfileView.swift
//  RePlate
//
//  Created by Jyotika Sadani on 5/26/26.
//  Redesigned to match RePlate 2.0 Figma — gradient header, impact stats, clean menu cards.
//

import SwiftUI
import PhotosUI
import Supabase

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showSettings        = false
    @State private var showNotifications   = false
    @State private var showEditProfile     = false
    @State private var showPaymentMethods  = false
    @State private var showLegalPage: LegalPageView.LegalPage? = nil
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var showExportShare     = false
    @State private var exportURL: URL?

    private var displayName: String {
        viewModel.user?.name ?? appState.currentUser?.name ?? "User"
    }
    private var displayEmail: String {
        viewModel.user?.email ?? appState.currentUser?.email ?? ""
    }
    private var accountType: User.AccountType? {
        viewModel.user?.accountType ?? appState.currentUser?.accountType
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                profileHeader
                mainContent
            }
            .padding(.bottom, 100)
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
        .task { await viewModel.loadProfile() }
        .sheet(isPresented: $showEditProfile) { EditProfileView() }
        .sheet(isPresented: $showNotifications) { NotificationsView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showPaymentMethods) { PaymentMethodsView().environmentObject(appState) }
        .sheet(item: $showLegalPage) { page in
            NavigationView { LegalPageView(page: page) }
        }
        .sheet(isPresented: $showExportShare, onDismiss: { exportURL = nil }) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let ui = UIImage(data: data),
                      let jpegData = ui.jpegData(compressionQuality: 0.8) else { return }
                profileImage = Image(uiImage: ui)
                appState.profileImageData = data
                guard let uid = supabase.auth.currentSession?.user.id.uuidString else { return }
                let path = "\(uid)/profile.jpg"
                try? await supabase.storage.from("avatars")
                    .upload(path, data: jpegData,
                            options: FileOptions(contentType: "image/jpeg", upsert: true))
                if let url = try? supabase.storage.from("avatars").getPublicURL(path: path) {
                    try? await supabase.from("profiles")
                        .update(["profile_image_url": url.absoluteString])
                        .eq("id", value: uid)
                        .execute()
                    appState.currentUser?.profileImageURL = url.absoluteString
                }
            }
        }
    }

    // MARK: - Gradient Header
    private var profileHeader: some View {
        VStack(spacing: 0) {
            // Top bar: title + settings
            HStack(alignment: .center) {
                Text("My Profile")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    hapticFeedback(.light)
                    showSettings = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                            .frame(width: 48, height: 48)
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 28)

            // Avatar — tappable PhotosPicker
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 96, height: 96)
                        .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 3))
                    if let profileImage {
                        profileImage.resizable().scaledToFill()
                            .clipShape(Circle()).frame(width: 96, height: 96)
                    } else if let urlStr = viewModel.user?.profileImageURL ?? appState.currentUser?.profileImageURL,
                              let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            if let img = phase.image {
                                img.resizable().scaledToFill()
                                    .clipShape(Circle()).frame(width: 96, height: 96)
                            } else {
                                Text(displayName.prefix(1).uppercased())
                                    .font(.system(size: 42, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 96, height: 96)
                            }
                        }
                        .clipShape(Circle()).frame(width: 96, height: 96)
                    } else {
                        Text(displayName.prefix(1).uppercased())
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 96, height: 96)
                    }
                    // Camera badge
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Theme.Colors.primaryGradientStart)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            }

            Spacer().frame(height: 14)

            Text(displayName)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(displayEmail)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 2)

            if let type = accountType {
                HStack(spacing: 6) {
                    Image(systemName: type.icon)
                        .font(.system(size: 11, weight: .bold))
                    Text(type.displayName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(Theme.Colors.primaryGradientStart)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Theme.Colors.accent)
                .clipShape(Capsule())
                .padding(.top, 10)
            }

            Spacer().frame(height: 52)
        }
        .padding(.horizontal, 20)
        .background(Theme.Colors.primaryGradient)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40))
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Edit Profile button floats up over header
            editProfileButton
                .padding(.horizontal, 20)
                .offset(y: -28)
                .padding(.bottom, 8) // net: -20 visual

            if let user = viewModel.user {
                impactSection(user: user)
                    .padding(.top, 4)
            }

            accountMenuSection
                .padding(.top, 28)

            helpSupportSection
                .padding(.top, 12)

            aboutMenuSection
                .padding(.top, 12)

            signOutButton
                .padding(.top, 24)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Edit Profile Floating Button
    private var editProfileButton: some View {
        Button {
            hapticFeedback(.medium)
            showEditProfile = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.primaryGradient)
                        .frame(width: 40, height: 40)
                    Image(systemName: "pencil")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("Edit Profile")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.primaryGradientStart)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryLabel)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 18, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Impact Section
    private func impactSection(user: User) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Impact")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 11))
                    Text("Eco Hero")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(Theme.Colors.primaryGradientStart)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.Colors.primaryGradientStart.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 14
            ) {
                ProfileStatCard(
                    label: "Meals Saved",
                    value: "\(user.mealsSaved)",
                    icon: "fork.knife",
                    accent: false
                )
                ProfileStatCard(
                    label: "CO₂ Reduced",
                    value: "\(String(format: "%.1f", user.co2Reduced))kg",
                    icon: "leaf.fill",
                    accent: true
                )
                ProfileStatCard(
                    label: "Food Rescued",
                    value: "\(String(format: "%.1f", user.foodRescued))lbs",
                    icon: "scalemass.fill",
                    accent: false
                )
                ProfileStatCard(
                    label: "Good Deeds",
                    value: "\(user.mealsSaved)",
                    icon: "heart.fill",
                    accent: true
                )
            }
            .padding(.horizontal, 20)

            if let user = viewModel.user ?? appState.currentUser {
                let shareText = "I've rescued \(user.mealsSaved) meals and saved \(String(format: "%.1f", user.co2Reduced)) kg of CO₂ with @RePlate! Join me in reducing food waste."
                ShareLink(item: shareText) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .bold))
                        Text("Share Your Impact")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Account Menu
    private var accountMenuSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.label)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                MenuButton(icon: "person", title: "Edit Profile") {
                    showEditProfile = true
                }
                Divider().padding(.leading, 60)
                MenuButton(icon: "bell", title: "Notifications") {
                    showNotifications = true
                }
                Divider().padding(.leading, 60)
                MenuButton(icon: "creditcard", title: "Payment Methods") {
                    showPaymentMethods = true
                }
                Divider().padding(.leading, 60)
                MenuButton(icon: "gearshape", title: "Settings") {
                    showSettings = true
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Help & Support (§1.5 — developer must provide easy contact method)
    private var helpSupportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Help & Support")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.label)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                // §1.5: Easy contact method required
                MenuButton(icon: "envelope", title: "Contact Support") {
                    if let url = URL(string: "mailto:support@replate.app?subject=RePlate%20Support") {
                        UIApplication.shared.open(url)
                    }
                }
                Divider().padding(.leading, 60)
                // §1.2: Report mechanism for user-generated content
                MenuButton(icon: "exclamationmark.bubble", title: "Report a Problem") {
                    if let url = URL(string: "mailto:support@replate.app?subject=RePlate%20Problem%20Report") {
                        UIApplication.shared.open(url)
                    }
                }
                Divider().padding(.leading, 60)
                MenuButton(icon: "questionmark.circle", title: "FAQs") {
                    showLegalPage = .faq
                }
                Divider().padding(.leading, 60)
                // §4.5.4: Users can always find the notification opt-out
                MenuButton(icon: "bell.badge", title: "Notification Preferences") {
                    showNotifications = true
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - About Menu
    private var aboutMenuSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.label)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                MenuButton(icon: "person.3.fill", title: "Community Guidelines") {
                    showLegalPage = .communityGuidelines
                }
                Divider().padding(.leading, 60)
                MenuButton(icon: "doc.text", title: "Terms of Service") {
                    showLegalPage = .termsOfService
                }
                Divider().padding(.leading, 60)
                MenuButton(icon: "lock.shield", title: "Privacy Policy") {
                    showLegalPage = .privacyPolicy
                }
                Divider().padding(.leading, 60)
                MenuButton(icon: "person.badge.shield.checkmark", title: "Food Safety Policy") {
                    showLegalPage = .foodSafetyPolicy
                }
                Divider().padding(.leading, 60)
                MenuButton(icon: "arrow.down.doc", title: "Export My Data") {
                    Task {
                        let user = viewModel.user ?? appState.currentUser
                        var csv = "RePlate Data Export\nGenerated,\(Date().formatted(date: .abbreviated, time: .shortened))\n\n"
                        csv += "ACCOUNT\n"
                        csv += "Name,\(user?.name ?? "")\n"
                        csv += "Email,\(user?.email ?? "")\n"
                        csv += "Account Type,\(user?.accountType.displayName ?? "")\n\n"
                        let tmp = FileManager.default.temporaryDirectory
                            .appendingPathComponent("replate_data_export.csv")
                        try? csv.write(to: tmp, atomically: true, encoding: .utf8)
                        exportURL = tmp
                        showExportShare = true
                        hapticFeedback(.success)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Sign Out
    private var signOutButton: some View {
        Button {
            hapticFeedback(.medium)
            appState.signOut()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                Text("Sign Out")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.red.opacity(0.25), lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Profile Stat Card (private)
private struct ProfileStatCard: View {
    let label: String
    let value: String
    let icon: String
    let accent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        accent
                            ? Theme.Colors.accent.opacity(0.5)
                            : Theme.Colors.primaryGradientStart.opacity(0.12)
                    )
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGradientStart)
            }
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(Theme.Colors.label)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        )
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Menu Button
struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            hapticFeedback(.light)
            action()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Theme.Colors.primaryGradientStart)
                    .frame(width: 28)

                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.label)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.tertiaryLabel)
            }
            .padding(Theme.Spacing.md)
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ProfileViewModel()
    @State private var name          = ""
    @State private var email         = ""
    @State private var rawPhone      = ""   // raw digits only
    @State private var isLoading     = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?

    /// Auto-formats raw digits to (xxx) xxx-xxxx
    private var formattedPhone: String {
        let d = rawPhone.filter { $0.isNumber }
        var r = ""
        for (i, ch) in d.prefix(10).enumerated() {
            switch i {
            case 0: r = "(\(ch)"
            case 1, 2: r += String(ch)
            case 3: r += ") \(ch)"
            case 4, 5: r += String(ch)
            case 6: r += "-\(ch)"
            default: r += String(ch)
            }
        }
        return r
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Avatar with PhotosPicker
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        VStack(spacing: Theme.Spacing.sm) {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(Theme.Colors.primaryGradient)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Group {
                                            if let profileImage {
                                                profileImage.resizable().scaledToFill()
                                                    .clipShape(Circle())
                                            } else {
                                                Text(name.prefix(1).uppercased())
                                                    .font(.system(size: 40, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    )
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Theme.Colors.primaryGradientStart)
                                    .clipShape(Circle())
                                    .offset(x: 4, y: 4)
                            }
                            Text("Change Photo")
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(Theme.Colors.primaryGradientStart)
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let ui = UIImage(data: data) {
                                profileImage = Image(uiImage: ui)
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.lg)

                    // Form
                    VStack(spacing: Theme.Spacing.md) {
                        CustomTextField(placeholder: "Name", text: $name, icon: "person")

                        CustomTextField(placeholder: "Email", text: $email, icon: "envelope")
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)

                        // Auto-formatted phone field
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 14) {
                                Image(systemName: "phone")
                                    .foregroundColor(Theme.Colors.primaryGradientStart)
                                    .frame(width: 20)
                                TextField("Phone Number (Optional)", text: $rawPhone)
                                    .keyboardType(.numberPad)
                                    .onChange(of: rawPhone) { _, v in
                                        let digits = v.filter { $0.isNumber }
                                        rawPhone = String(digits.prefix(10))
                                    }
                                if !formattedPhone.isEmpty {
                                    Text(formattedPhone)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(Theme.Colors.secondaryLabel)
                                }
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.secondaryBackground)
                            .cornerRadius(Theme.CornerRadius.md)
                        }
                    }

                    PrimaryButton("Save Changes", isLoading: isLoading) {
                        Task { await save() }
                    }
                    .padding(.top, Theme.Spacing.md)
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await viewModel.loadProfile()
                name = viewModel.user?.name ?? ""
                email = viewModel.user?.email ?? ""
                // Strip non-digit characters from saved phone
                rawPhone = (viewModel.user?.phoneNumber ?? "").filter { $0.isNumber }
            }
        }
    }

    func save() async {
        isLoading = true
        await viewModel.updateProfile(
            name: name,
            email: email,
            phoneNumber: formattedPhone.isEmpty ? nil : formattedPhone
        )
        isLoading = false
        dismiss()
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var notificationsEnabled = true
    @State private var pushNotificationsEnabled = true
    @State private var emailNotificationsEnabled = true
    @State private var newListingsNotifications = true
    @State private var orderUpdatesNotifications = true
    @State private var impactMilestonesNotifications = true
    @State private var showDeleteAccountConfirmation = false
    @State private var showLegalPage: LegalPageView.LegalPage? = nil
    @State private var showExportShare = false

    private var exportCSV: String {
        "RePlate Account Export\nDate,\(Date().formatted(date: .abbreviated, time: .shortened))\nNotifications Enabled,\(notificationsEnabled)\nPush,\(pushNotificationsEnabled)\nEmail,\(emailNotificationsEnabled)"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    appearanceSection
                    Divider()
                    notificationsSection
                    Divider()
                    privacySection
                    Divider()
                    dangerZoneSection
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $showLegalPage) { page in
                NavigationView { LegalPageView(page: page) }
            }
            .alert("Delete Account", isPresented: $showDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Appearance")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.label)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(AppState.ColorSchemePreference.allCases, id: \.self) { preference in
                    Button {
                        appState.saveColorSchemePreference(preference)
                        hapticFeedback()
                    } label: {
                        HStack {
                            Text(preference.rawValue)
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.label)
                            Spacer()
                            if appState.colorScheme == preference {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Theme.Colors.primaryGradientStart)
                            }
                        }
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(Theme.CornerRadius.md)
                    }
                }
            }
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Notifications")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.label)

            VStack(spacing: 0) {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .padding(Theme.Spacing.md)

                if notificationsEnabled {
                    Divider()
                    Toggle("Push Notifications", isOn: $pushNotificationsEnabled)
                        .padding(Theme.Spacing.md)
                    Divider()
                    Toggle("Email Notifications", isOn: $emailNotificationsEnabled)
                        .padding(Theme.Spacing.md)
                    Divider()
                    Toggle("New Listings", isOn: $newListingsNotifications)
                        .padding(Theme.Spacing.md)
                    Divider()
                    Toggle("Order Updates", isOn: $orderUpdatesNotifications)
                        .padding(Theme.Spacing.md)
                    Divider()
                    Toggle("Impact Milestones", isOn: $impactMilestonesNotifications)
                        .padding(Theme.Spacing.md)
                }
            }
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.xl)
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Privacy & Data")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.label)

            VStack(spacing: 0) {
                Button {
                    showLegalPage = .termsOfService
                } label: {
                    HStack {
                        Text("Terms of Service")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.label)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(Theme.Colors.tertiaryLabel)
                    }
                    .padding(Theme.Spacing.md)
                }

                Divider()

                Button {
                    showLegalPage = .privacyPolicy
                } label: {
                    HStack {
                        Text("Privacy Policy")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.label)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(Theme.Colors.tertiaryLabel)
                    }
                    .padding(Theme.Spacing.md)
                }

                Divider()

                ShareLink(item: exportCSV, subject: Text("My RePlate Data"), message: Text("Exported account data from RePlate")) {
                    HStack {
                        Text("Export My Data")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.label)
                        Spacer()
                        Image(systemName: "arrow.down.doc")
                            .foregroundColor(Theme.Colors.tertiaryLabel)
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.xl)
        }
    }

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Danger Zone")
                .font(Theme.Typography.headline)
                .foregroundColor(.red)

            Button {
                showDeleteAccountConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Account")
                        .font(Theme.Typography.body)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Color.red)
                .cornerRadius(Theme.CornerRadius.xl)
            }
        }
    }

    func deleteAccount() async {
        await ProfileViewModel().deleteAccount()
        dismiss()
    }
}

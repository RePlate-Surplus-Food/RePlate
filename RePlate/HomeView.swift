//
//  HomeView.swift
//  RePlate
//
//  Created by Jyotika Sadani on 5/26/26.
//  Redesigned to match RePlate 2.0 Figma — playful, bold, food-first.
//

import SwiftUI
import MapKit
import UserNotifications
import Supabase

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedListing: FoodListing?
    @State private var showNotifications = false
    @State private var showAIAssistant = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                homeHeader
                categoriesSection
                freshlyRescuedSection
            }
            .padding(.bottom, 100)
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .top)
        .refreshable { await viewModel.refreshListings() }
        .task { await viewModel.loadListings() }
        .sheet(item: $selectedListing) { listing in
            ListingDetailView(listing: listing)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
        }
        .sheet(isPresented: $showAIAssistant) {
            AIAssistantView()
                .environmentObject(appState)
        }
    }

    // MARK: - Hero Header
    private var homeHeader: some View {
        ZStack(alignment: .top) {
            // Adaptive gradient — light: fresh bright green / dark: deep forest
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(hex: "030d06"), Color(hex: "0a3d1e"), Theme.Colors.primaryGradientStart]
                    : [Color(hex: "0f7a46"), Color(hex: "17a05e"), Color(hex: "22bc74")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            // Animated floating gradient bubbles
            HeaderBubbles()
                .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 0) {

                // ── Top bar ──────────────────────────────────
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.Colors.accent)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("YOUR LOCATION")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.50))
                                .tracking(1.5)
                            Text(appState.currentUser != nil ? "Downtown Manhattan" : "San Francisco, CA")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                    Button {
                        hapticFeedback(.light)
                        showNotifications = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Circle()
                                .fill(.white.opacity(0.12))
                                .frame(width: 42, height: 42)
                            Image(systemName: "bell.fill")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .frame(width: 42, height: 42)
                            Circle()
                                .fill(Theme.Colors.accent)
                                .frame(width: 9, height: 9)
                                .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 1))
                                .offset(x: 1, y: -1)
                        }
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 28)

                // ── Big stat ──────────────────────────────────
                Text("Available near you")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.60))
                    .padding(.bottom, 6)

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(viewModel.isLoading ? "--" : "\(viewModel.listings.count)")
                        .font(.system(size: 58, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(" meals")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.Colors.accent, Color(hex: "a8f0c6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.leading, 4)
                }
                .padding(.bottom, 10)

                // Badge
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("rescued today near you")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(Theme.Colors.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.Colors.accent.opacity(0.15)))
                .padding(.bottom, 24)

                // ── Glass impact card ─────────────────────────
                HStack(spacing: 0) {
                    headerStatCell(value: "1.2k", label: "kg saved")
                    Rectangle().fill(.white.opacity(0.15)).frame(width: 1, height: 32)
                    headerStatCell(value: "340", label: "CO₂ reduced")
                    Rectangle().fill(.white.opacity(0.15)).frame(width: 1, height: 32)
                    headerStatCell(value: "$8.2k", label: "value rescued")
                }
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )
                )
                .padding(.bottom, 18)

                // ── Action pills ──────────────────────────────
                HStack(spacing: 10) {
                    NavigationLink(destination: SearchView()) {
                        headerActionPill(icon: "magnifyingglass", title: "Search")
                    }
                    Button {
                        hapticFeedback(.light)
                        viewModel.toggleMapView()
                    } label: {
                        headerActionPill(icon: "map.fill", title: "Map View")
                    }
                    Button {
                        hapticFeedback(.light)
                        showAIAssistant = true
                    } label: {
                        headerActionPill(icon: "sparkles", title: "AI Pick")
                    }
                }
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 20)
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 32, bottomTrailingRadius: 32, topTrailingRadius: 0))
    }

    private func headerStatCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    private func headerActionPill(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.22), lineWidth: 1)
                )
        )
    }

    // MARK: - Categories
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Categories")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                Spacer()
                Button("View All") {
                    hapticFeedback(.light)
                    appState.selectedTab = .search
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.primaryGradientStart)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(foodCategories, id: \.label) { cat in
                        CategoryPill(cat: cat)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Freshly Rescued
    private var freshlyRescuedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Freshly Rescued")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 11))
                    Text("New Today")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(Theme.Colors.primaryGradientStart)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.Colors.primaryGradientStart.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 16)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                VStack(spacing: 28) {
                    ForEach(viewModel.listings) { listing in
                        FigmaListingCard(listing: listing) {
                            selectedListing = listing
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Data
    private let foodCategories: [(icon: String, label: String, color: Color)] = [
        // Cuisines
        ("flame.fill",                        "Indian",        Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("fork.knife.circle.fill",            "Italian",       Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("leaf.arrow.circlepath",             "Mexican",       Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("fish.fill",                         "Japanese",      Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("globe.asia.australia.fill",          "Asian",         Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("flame.circle.fill",                 "Korean",        Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("cup.and.saucer.fill",               "Chinese",       Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("leaf.circle.fill",                  "Thai",          Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("sun.horizon.fill",                  "Mediterranean", Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("takeoutbag.and.cup.and.straw.fill", "American",      Theme.Colors.primaryGradientStart.opacity(0.10)),
        // Meal times
        ("sunrise.fill",                      "Breakfast",     Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("sun.max.fill",                      "Lunch",         Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("moon.stars.fill",                   "Dinner",        Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("takeoutbag.and.cup.and.straw",      "Snacks",        Theme.Colors.primaryGradientStart.opacity(0.10)),
        // Food types
        ("birthday.cake.fill",                "Desserts",      Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("birthday.cake",                     "Bakery",        Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("carrot",                            "Produce",       Theme.Colors.primaryGradientStart.opacity(0.10)),
        ("cup.and.saucer",                    "Beverages",     Theme.Colors.primaryGradientStart.opacity(0.10)),
    ]
}

// MARK: - Floating Header Bubbles
private struct HeaderBubbles: View {
    @State private var phase = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [Theme.Colors.accent.opacity(0.55), .clear],
                                   center: .center, startRadius: 0, endRadius: 80)
                )
                .frame(width: 160)
                .blur(radius: 30)
                .offset(x: phase ? 130 : 100, y: phase ? 40 : 70)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: phase)

            Circle()
                .fill(
                    RadialGradient(colors: [Color(hex: "a8f0c6").opacity(0.45), .clear],
                                   center: .center, startRadius: 0, endRadius: 60)
                )
                .frame(width: 120)
                .blur(radius: 25)
                .offset(x: phase ? -110 : -80, y: phase ? 160 : 120)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: phase)

            Circle()
                .fill(
                    RadialGradient(colors: [Color.white.opacity(0.18), .clear],
                                   center: .center, startRadius: 0, endRadius: 50)
                )
                .frame(width: 90)
                .blur(radius: 18)
                .offset(x: phase ? 60 : 30, y: phase ? 240 : 200)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true).delay(1), value: phase)

            Circle()
                .fill(
                    RadialGradient(colors: [Theme.Colors.primaryGradientEnd.opacity(0.5), .clear],
                                   center: .center, startRadius: 0, endRadius: 70)
                )
                .frame(width: 130)
                .blur(radius: 28)
                .offset(x: phase ? -50 : -20, y: phase ? 60 : 30)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true).delay(2), value: phase)
        }
        .onAppear { phase = true }
        .allowsHitTesting(false)
    }
}

// MARK: - Category Pill
private struct CategoryPill: View {
    let cat: (icon: String, label: String, color: Color)

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: cat.icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryGradientStart)
            Text(cat.label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(width: 76, height: 96)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cat.color)
                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 3)
        )
    }
}

// MARK: - Figma-style Listing Card
struct FigmaListingCard: View {
    let listing: FoodListing
    let onTap: () -> Void

    var body: some View {
        Button(action: { onTap(); hapticFeedback(.light) }) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                ZStack(alignment: .bottom) {
                    AsyncImage(url: nil) { _ in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.primaryGradientStart.opacity(0.3),
                                        Theme.Colors.primaryGradientEnd.opacity(0.5)
                                    ],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                    } placeholder: {
                        ZStack {
                            Theme.Colors.primaryGradient
                            Image(systemName: listing.category.icon)
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(height: 200)
                    .clipped()

                    // Tags overlay
                    HStack {
                        ForEach(listing.dietaryInfo.prefix(2), id: \.self) { tag in
                            Text(tag.rawValue)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.black.opacity(0.35).blendMode(.normal))
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    .padding(14)

                    // Rating badge
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "F5A623"))
                                Text("4.8")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.Colors.label)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Spacer()
                    }
                    .padding(14)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28))

                // Info row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(listing.restaurantName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                        HStack(spacing: 14) {
                            Label("Pickup: 6–8 PM", systemImage: "clock")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                            Label("0.5 mi", systemImage: "location")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(String(format: "%.2f", listing.discountedPrice))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.primaryGradientStart)
                        Text("$\(String(format: "%.2f", listing.originalPrice))")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .strikethrough()
                    }
                }
                .padding(.top, 14)
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        // §1.2: Long-press context menu for reporting inappropriate listings
        .contextMenu {
            Button(role: .destructive) {
                Task {
                    guard let uid = supabase.auth.currentSession?.user.id.uuidString else { return }
                    try? await supabase.from("reports")
                        .insert([
                            "reporter_id": uid,
                            "listing_id": listing.id,
                            "reason": "inappropriate",
                            "created_at": ISO8601DateFormatter().string(from: Date())
                        ])
                        .execute()
                }
            } label: {
                Label("Report Listing", systemImage: "exclamationmark.triangle")
            }
        }
    }
}

// MARK: - Listing Detail View (sheet)
struct ListingDetailView: View {
    let listing: FoodListing
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Hero image placeholder
                    ZStack {
                        Theme.Colors.primaryGradient
                        Image(systemName: listing.category.icon)
                            .font(.system(size: 64))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, Theme.Spacing.lg)

                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text(listing.title)
                            .font(Theme.Typography.title2)
                            .foregroundColor(Theme.Colors.label)
                        Text(listing.restaurantName)
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.secondaryLabel)
                        Text(listing.description)
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryLabel)

                        // Price row
                        HStack {
                            Text("$\(String(format: "%.2f", listing.discountedPrice))")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.Colors.primaryGradient)
                            Text("$\(String(format: "%.2f", listing.originalPrice))")
                                .font(Theme.Typography.title3)
                                .foregroundColor(Theme.Colors.secondaryLabel)
                                .strikethrough()
                            Spacer()
                            Text("\(Int(listing.savingsPercentage))% off")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.Colors.primaryGradientStart)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Theme.Colors.primaryGradientStart.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        PrimaryButton("Reserve Now") {
                            hapticFeedback(.success)
                            dismiss()
                        }
                        .padding(.top, Theme.Spacing.sm)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                }
            }
        }
    }
}

// MARK: - Notifications View (placeholder)
// §4.5.4: Push notification preferences — explicit opt-in required;
// users must always be able to opt out of marketing notifications.
struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss

    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var orderUpdates    = true
    @State private var newListingsNearby = true
    @State private var marketingOffers  = false  // off by default — §4.5.4 requires opt-in
    @State private var reminders        = true

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // System permission card
                    permissionCard
                        .padding(.top, 16)

                    if permissionStatus == .authorized || permissionStatus == .provisional {
                        preferencesSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Theme.Colors.pageBackground)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                }
            }
            .task { await refreshPermissionStatus() }
        }
    }

    // MARK: - System Permission Card

    private var permissionCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(permissionStatus == .authorized
                          ? Theme.Colors.primaryGradientStart.opacity(0.12)
                          : Color(.systemGray5))
                    .frame(width: 72, height: 72)
                Image(systemName: permissionStatus == .authorized ? "bell.fill" : "bell.slash.fill")
                    .font(.system(size: 30))
                    .foregroundColor(permissionStatus == .authorized
                                     ? Theme.Colors.primaryGradientStart
                                     : Theme.Colors.secondaryLabel)
            }

            VStack(spacing: 6) {
                Text(permissionStatus == .authorized ? "Notifications are on" : "Turn on notifications")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                Text(permissionStatus == .authorized
                     ? "You'll be notified about order updates and listings near you."
                     : "Stay updated when your order is ready and new deals drop nearby. You can customise or turn off at any time.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }

            if permissionStatus == .notDetermined {
                // §4.5.4: First-time explicit opt-in request
                Button {
                    Task { await requestPermission() }
                } label: {
                    Text("Enable Notifications")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Theme.Colors.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else if permissionStatus == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Theme.Colors.primaryGradientStart.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 3)
    }

    // MARK: - Notification Preferences

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What to notify me about")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryLabel)
                .tracking(0.5)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                notifRow(
                    icon: "bag.fill",
                    iconColor: Theme.Colors.primaryGradientStart,
                    title: "Order Updates",
                    subtitle: "Ready for pickup, confirmed, changes",
                    value: $orderUpdates
                )
                Divider().padding(.leading, 64)
                notifRow(
                    icon: "location.fill",
                    iconColor: Color(hex: "FF6B35"),
                    title: "Nearby Listings",
                    subtitle: "New surplus food posted close to you",
                    value: $newListingsNearby
                )
                Divider().padding(.leading, 64)
                notifRow(
                    icon: "clock.fill",
                    iconColor: Color(hex: "5856D6"),
                    title: "Pickup Reminders",
                    subtitle: "Reminded before your pickup window closes",
                    value: $reminders
                )
                Divider().padding(.leading, 64)
                // §4.5.4: Marketing must be opt-in, with clear description of what will be sent
                notifRow(
                    icon: "tag.fill",
                    iconColor: Color(hex: "FF9500"),
                    title: "Deals & Promotions",
                    subtitle: "Special offers from restaurants you follow",
                    value: $marketingOffers
                )
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 3)

            Text("You can always manage these in your iPhone's Settings → Notifications → RePlate.")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.tertiaryLabel)
                .padding(.horizontal, 4)
        }
    }

    private func notifRow(
        icon: String, iconColor: Color,
        title: String, subtitle: String,
        value: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryLabel)
            }
            Spacer()
            Toggle("", isOn: value)
                .labelsHidden()
                .tint(Theme.Colors.primaryGradientStart)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Permission Helpers

    private func refreshPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionStatus = settings.authorizationStatus
    }

    private func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            permissionStatus = granted ? .authorized : .denied
        } catch {
            permissionStatus = .denied
        }
    }
}

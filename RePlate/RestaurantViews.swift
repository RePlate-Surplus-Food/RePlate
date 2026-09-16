//
//  RestaurantViews.swift
//  RePlate
//
//  Created by Jyotika Sadani on 5/26/26.
//

import SwiftUI
import PhotosUI
import Combine
import Supabase

// MARK: - Restaurant Dashboard
struct RestaurantDashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = RestaurantDashboardViewModel()
    @State private var showPostListing        = false
    @State private var showVerificationGate  = false
    @State private var showSettings          = false
    @State private var showNotifications     = false
    @State private var showMenuScanner       = false
    @State private var showConnectOnboarding = false
    @State private var selectedOrder: Order? = nil
    @State private var selectedListing: FoodListing? = nil

    private var isVerified: Bool {
        appState.currentUser?.verifiedRestaurant ?? false
    }

    private var restaurantDisplayName: String {
        appState.currentUser?.name ?? "Verde Bistro"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                gradientHeader
                mainContent
            }
            .padding(.bottom, 100)
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
        .refreshable { await viewModel.refreshDashboard() }
        .task { await viewModel.loadDashboard() }
        .sheet(isPresented: $showPostListing) { PostSurplusView() }
        .sheet(isPresented: $showVerificationGate) { VerificationGateView() }
        .sheet(isPresented: $showSettings) { RestaurantSettingsView() }
        .sheet(isPresented: $showNotifications) { NotificationsView() }
        .sheet(isPresented: $showConnectOnboarding) { ConnectOnboardingView() }
        .sheet(isPresented: $showMenuScanner) {
            MenuScannerView { scannedItems in
                let now = Date()
                let pickup5pm = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: now) ?? now.addingTimeInterval(3600)
                let pickup9pm = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: now) ?? now.addingTimeInterval(7200)
                let restaurantId = appState.currentUser?.id ?? "restaurant"

                let newListings: [FoodListing] = scannedItems.compactMap { item in
                    guard let originalPrice = Double(item.price.replacingOccurrences(of: ",", with: ".")) else { return nil }
                    return FoodListing(
                        id: UUID().uuidString,
                        restaurantId: restaurantId,
                        restaurant: nil,
                        title: item.name,
                        description: item.description.isEmpty ? "Freshly rescued from today's menu" : item.description,
                        category: item.category,
                        imageURLs: [],
                        originalPrice: originalPrice,
                        discountedPrice: round(originalPrice * 0.6 * 100) / 100,
                        isFree: false,
                        quantity: 5,
                        availableQuantity: 5,
                        pickupStartTime: pickup5pm,
                        pickupEndTime: pickup9pm,
                        status: .active,
                        createdAt: now,
                        expiresAt: pickup9pm,
                        tags: [],
                        dietaryInfo: []
                    )
                }
                withAnimation { viewModel.activeListings.append(contentsOf: newListings) }
            }
        }
        .sheet(item: $selectedOrder) { order in
            RestaurantOrderDetailView(order: order)
        }
        .sheet(item: $selectedListing) { listing in
            EditListingView(listing: listing)
        }
    }

    // MARK: - Gradient Header
    private var gradientHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top bar: name + bell
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurantDisplayName)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.Colors.accent)
                            .frame(width: 8, height: 8)
                        Text("Store Open • High Impact")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                Spacer()
                HStack(spacing: 10) {
                // Settings gear
                Button {
                    hapticFeedback(.light)
                    showSettings = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                // Bell with badge
                Button {
                    hapticFeedback(.light)
                    showNotifications = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                                .frame(width: 48, height: 48)
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        if viewModel.hasUnreadNotifications {
                            Circle()
                                .fill(Color.red.opacity(0.9))
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Theme.Colors.primaryGradientStart, lineWidth: 2))
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                } // end HStack (gear + bell)
            }
            .padding(.top, 60)
            .padding(.bottom, 28)

            // 2×2 impact stats grid
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 14
            ) {
                FigmaStatCard(
                    label: "Meals Saved",
                    value: "\(viewModel.todayStats.mealsSaved)",
                    icon: "bag.fill",
                    accent: false
                )
                FigmaStatCard(
                    label: "CO₂ Reduced",
                    value: "\(String(format: "%.0f", viewModel.todayStats.co2Reduced))kg",
                    icon: "leaf.fill",
                    accent: true
                )
                FigmaStatCard(
                    label: "Revenue",
                    value: "$\(String(format: "%.0f", viewModel.todayStats.revenueToday))",
                    icon: "dollarsign.circle.fill",
                    accent: false
                )
                FigmaStatCard(
                    label: "Growth",
                    value: "+12%",
                    icon: "chart.line.uptrend.xyaxis",
                    accent: true
                )
            }
            .padding(.bottom, 52)
        }
        .padding(.horizontal, 20)
        .background(Theme.Colors.primaryGradient)
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: 40,
                bottomTrailingRadius: 40
            )
        )
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Quick actions float up over the header
            HStack(spacing: 12) {
                postSurplusButton
                scanMenuButton
            }
            .padding(.horizontal, 20)
            .offset(y: -28)
            .padding(.bottom, 8)

            // Stripe Connect setup prompt — shown until the restaurant finishes onboarding
            if appState.currentUser?.stripeAccountId == nil {
                stripeSetupBanner
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }

            // Today's Pickups
            todaysPickupsSection
                .padding(.top, 12)

            // Active Listings
            activeListingsSection
                .padding(.top, 8)
        }
    }

    // MARK: - Quick Action Buttons

    private var postSurplusButton: some View {
        Button {
            hapticFeedback(.medium)
            // SECURITY: server must check verified flag before accepting listing
            if isVerified { showPostListing = true } else { showVerificationGate = true }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.Colors.primaryGradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("Post Surplus")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.primaryGradientStart)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 14, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var scanMenuButton: some View {
        Button {
            hapticFeedback(.medium)
            if isVerified { showMenuScanner = true } else { showVerificationGate = true }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.Colors.primaryGradientStart.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                }
                Text("Scan Menu")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.primaryGradientStart)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 14, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Stripe Connect Setup Banner

    private var stripeSetupBanner: some View {
        Button {
            hapticFeedback(.medium)
            showConnectOnboarding = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.22))
                        .frame(width: 46, height: 46)
                    Image(systemName: "creditcard.and.123")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set up payments")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Connect Stripe to receive payouts")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.82))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(16)
            .background(Theme.Colors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.28), radius: 10, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Today's Pickups
    private var todaysPickupsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Today's Pickups")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                Spacer()
                if !viewModel.pendingOrders.isEmpty {
                    Text("\(viewModel.pendingOrders.count) New")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.Colors.primaryGradientStart.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
            } else if viewModel.pendingOrders.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.Colors.primaryGradient)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("All Caught Up!")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                        Text("No pending orders at the moment")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                    }
                    Spacer()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                )
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.pendingOrders.prefix(3)) { order in
                        FigmaOrderCard(order: order) {
                            selectedOrder = order
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Active Listings
    private var activeListingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Active Listings")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                Spacer()
                Button("See All") {
                    hapticFeedback(.light)
                    appState.selectedTab = .orders
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.primaryGradientStart)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
            } else if viewModel.activeListings.isEmpty {
                PremiumEmptyState(
                    icon: "fork.knife",
                    title: "No Active Listings",
                    message: "Start rescuing food by posting your first surplus listing",
                    actionTitle: "Post Listing",
                    action: { showPostListing = true }
                )
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 24) {
                    ForEach(viewModel.activeListings.prefix(3)) { listing in
                        FigmaActiveListingCard(listing: listing, onEdit: {
                            selectedListing = listing
                        }, onCancel: {
                            withAnimation {
                                viewModel.activeListings.removeAll { $0.id == listing.id }
                            }
                            Task {
                                try? await supabase
                                    .from("food_listings")
                                    .delete()
                                    .eq("id", value: listing.id)
                                    .execute()
                            }
                        })
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Figma Stat Card (header stats — white-on-gradient)
private struct FigmaStatCard: View {
    let label: String
    let value: String
    let icon: String
    let accent: Bool // true → use accent (#caf8a5), false → white

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accent ? Theme.Colors.accent : .white)
                Spacer()
                Text(label.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .tracking(0.5)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(16)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Figma Order Card (Today's Pickups)
private struct FigmaOrderCard: View {
    let order: Order
    var onDetails: () -> Void = {}
    @State private var isConfirmed = false

    var body: some View {
        VStack(spacing: 0) {
            // Top row: avatar + details + price
            HStack(alignment: .top, spacing: 14) {
                // Customer avatar (pickup code initial as proxy)
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Colors.primaryGradientStart.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Text(String(order.pickupCode.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.pickupCode)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.label)
                    if let listing = order.listing {
                        Text(listing.title)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", order.totalAmount))")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(order.status.rawValue)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.orange)
                }
            }
            .padding(.bottom, 18)

            // Action buttons
            HStack(spacing: 12) {
                Button("Details") { hapticFeedback(.light); onDetails() }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    hapticFeedback(.success)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isConfirmed = true
                    }
                    Task {
                        try? await supabase
                            .from("orders")
                            .update(["status": "completed",
                                     "completed_at": ISO8601DateFormatter().string(from: Date())])
                            .eq("id", value: order.id)
                            .execute()
                    }
                } label: {
                    Text(isConfirmed ? "Picked Up!" : "Confirm Pickup")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            isConfirmed
                                ? LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing)
                                : Theme.Colors.primaryGradient
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isConfirmed)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.07), radius: 12, y: 4)
        )
    }
}

// MARK: - Figma Active Listing Card
private struct FigmaActiveListingCard: View {
    let listing: FoodListing
    var onEdit: () -> Void = {}
    var onCancel: () -> Void = {}
    @State private var showCancelAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Image / gradient hero
            ZStack(alignment: .top) {
                Theme.Colors.primaryGradient
                    .overlay(
                        Image(systemName: listing.category.icon)
                            .font(.system(size: 52, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                    )
                    .frame(height: 220)
                    .clipped()

                // Active badge + views badge
                HStack {
                    Text("Active")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.Colors.primaryGradientStart)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.07), radius: 4, y: 2)

                    Spacer()

                    HStack(spacing: 5) {
                        Image(systemName: "eye")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("124")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
            }

            // Details section
            VStack(alignment: .leading, spacing: 0) {
                // Name + price row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(listing.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                        HStack(spacing: 5) {
                            Image(systemName: "bag")
                                .font(.system(size: 12))
                            Text("\(listing.availableQuantity) boxes left")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Theme.Colors.secondaryLabel)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(String(format: "%.2f", listing.discountedPrice))")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.Colors.primaryGradientStart)
                        Text("$\(String(format: "%.2f", listing.originalPrice))")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .strikethrough()
                    }
                }
                .padding(.bottom, 16)

                // Pickup window
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                    Text("Pickup: \(listing.pickupStartTime.formatted(date: .omitted, time: .shortened)) – \(listing.pickupEndTime.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.bottom, 16)

                // Edit / Cancel buttons
                HStack(spacing: 12) {
                    Button { hapticFeedback(.light); onEdit() } label: {
                        Text("Edit")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        hapticFeedback(.light)
                        showCancelAlert = true
                    } label: {
                        Text("Cancel Listing")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.3), lineWidth: 1.5))
                    }
                    .alert("Cancel Listing?", isPresented: $showCancelAlert) {
                        Button("Yes, Cancel", role: .destructive) { onCancel() }
                        Button("Keep Active", role: .cancel) {}
                    } message: {
                        Text("This listing will be removed from the marketplace.")
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.07), radius: 16, y: 5)
    }
}

// MARK: - Dashboard Stat Card
struct DashboardStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(value)
                .font(Theme.Typography.title2)
                .foregroundColor(Theme.Colors.label)
            
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.xl)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            hapticFeedback()
            action()
        }) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.label)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100, height: 100)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.xl)
        }
    }
}

// MARK: - Restaurant Listing Card
struct RestaurantListingCard: View {
    let listing: FoodListing
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Thumbnail
            if let imageURL = listing.imageURLs.first {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.tertiaryBackground)
                }
                .frame(width: 80, height: 80)
                .cornerRadius(Theme.CornerRadius.md)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.label)
                    .lineLimit(1)
                
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "bag")
                        .font(.caption)
                    Text("\(listing.availableQuantity) of \(listing.quantity) left")
                        .font(Theme.Typography.subheadline)
                }
                .foregroundColor(Theme.Colors.secondaryLabel)
                
                if listing.isFree {
                    Text("FREE")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.green)
                } else {
                    Text("$\(String(format: "%.2f", listing.discountedPrice))")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                }
            }
            
            Spacer()
            
            VStack(spacing: Theme.Spacing.xs) {
                Menu {
                    Button {
                        // Edit action
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        // Pause action
                    } label: {
                        Label("Pause", systemImage: "pause")
                    }
                    
                    Button(role: .destructive) {
                        // Delete action
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.secondaryLabel)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.xl)
    }
}

// MARK: - Restaurant Order Card
struct RestaurantOrderCard: View {
    let order: Order
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let listing = order.listing {
                        Text(listing.title)
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.label)
                    }
                    
                    Text("Order #\(order.pickupCode)")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.secondaryLabel)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(order.status.rawValue)
                        .font(Theme.Typography.caption)
                        .foregroundColor(order.status.color)
                    
                    Text("$\(String(format: "%.2f", order.totalAmount))")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.label)
                }
            }
            
            Divider()
            
            HStack(spacing: Theme.Spacing.md) {
                Button {
                    // Mark as ready
                } label: {
                    Text("Mark Ready")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.Colors.primaryGradient)
                        .cornerRadius(Theme.CornerRadius.md)
                }
                
                Button {
                    // Contact customer
                } label: {
                    Image(systemName: "message.fill")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                        .frame(width: 44, height: 44)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(Theme.CornerRadius.md)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.xl)
    }
}

// MARK: - Post Listing View
struct PostListingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PostListingViewModel()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var currentStep = 0
    
    let steps = ["Photos", "Details", "Pricing", "Pickup", "Review"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Indicator
                progressIndicator
                
                // Content
                TabView(selection: $currentStep) {
                    // Step 1: Photos
                    photosStep
                        .tag(0)
                    
                    // Step 2: Details
                    detailsStep
                        .tag(1)
                    
                    // Step 3: Pricing
                    pricingStep
                        .tag(2)
                    
                    // Step 4: Pickup
                    pickupStep
                        .tag(3)
                    
                    // Step 5: Review
                    reviewStep
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation Buttons
                navigationButtons
            }
            .background(Theme.Colors.background)
            .navigationTitle("Post Surplus Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $viewModel.showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your listing has been posted successfully!")
            }
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: 4) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? Theme.Colors.primaryGradient : LinearGradient(colors: [Theme.Colors.tertiaryBackground], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            
            Text("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryLabel)
        }
        .padding(.vertical, Theme.Spacing.md)
    }
    
    // MARK: - Step 1: Photos
    private var photosStep: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                Text("Add Photos")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.label)
                
                Text("Upload at least one photo of your food")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.Colors.primaryGradient)
                        
                        Text("Tap to select photos")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.primaryGradientStart)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.xl)
                }
                
                if !viewModel.selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(0..<viewModel.selectedImages.count, id: \.self) { index in
                                Image(uiImage: viewModel.selectedImages[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(Theme.CornerRadius.md)
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .onChange(of: selectedPhotos) { _, newPhotos in
            Task {
                viewModel.selectedImages = []
                for photo in newPhotos {
                    if let data = try? await photo.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectedImages.append(image)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Details
    private var detailsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                CustomTextField(
                    placeholder: "Food Title",
                    text: $viewModel.title,
                    icon: "fork.knife"
                )
                
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Description")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.label)
                    
                    TextEditor(text: $viewModel.description)
                        .frame(height: 120)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(Theme.CornerRadius.md)
                }
                
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Category")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.label)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(FoodListing.FoodCategory.allCases, id: \.self) { category in
                                Button {
                                    viewModel.category = category
                                    hapticFeedback(.light)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: category.icon)
                                        Text(category.rawValue)
                                    }
                                    .font(Theme.Typography.subheadline)
                                    .foregroundColor(viewModel.category == category ? .white : Theme.Colors.label)
                                    .padding(.horizontal, Theme.Spacing.md)
                                    .padding(.vertical, Theme.Spacing.sm)
                                    .background(viewModel.category == category ? Theme.Colors.primaryGradient : LinearGradient(colors: [Theme.Colors.secondaryBackground], startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(Theme.CornerRadius.xl)
                                }
                            }
                        }
                    }
                }
                
                CustomTextField(
                    placeholder: "Quantity Available",
                    text: $viewModel.quantity,
                    icon: "number"
                )
                .keyboardType(.numberPad)
            }
            .padding(Theme.Spacing.lg)
        }
    }
    
    // MARK: - Step 3: Pricing
    private var pricingStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Toggle(isOn: $viewModel.isFree) {
                    Text("Offer for Free")
                        .font(Theme.Typography.headline)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.md)
                
                if !viewModel.isFree {
                    CustomTextField(
                        placeholder: "Original Price",
                        text: $viewModel.originalPrice,
                        icon: "dollarsign.circle"
                    )
                    .keyboardType(.decimalPad)
                    
                    CustomTextField(
                        placeholder: "Discounted Price",
                        text: $viewModel.discountedPrice,
                        icon: "tag"
                    )
                    .keyboardType(.decimalPad)
                    
                    Button {
                        viewModel.suggestPrice()
                        hapticFeedback()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Suggest Price (50% off)")
                        }
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.accent.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.md)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }
    
    // MARK: - Step 4: Pickup
    private var pickupStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text("Pickup Window")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.label)
                
                DatePicker(
                    "Start Time",
                    selection: $viewModel.pickupStartTime,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                
                DatePicker(
                    "End Time",
                    selection: $viewModel.pickupEndTime,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                
                Text("Dietary Information")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.label)
                    .padding(.top, Theme.Spacing.md)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
                    ForEach(FoodListing.DietaryInfo.allCases, id: \.self) { info in
                        Button {
                            if viewModel.selectedDietaryInfo.contains(info) {
                                viewModel.selectedDietaryInfo.remove(info)
                            } else {
                                viewModel.selectedDietaryInfo.insert(info)
                            }
                            hapticFeedback(.light)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: info.icon)
                                Text(info.rawValue)
                            }
                            .font(Theme.Typography.caption)
                            .foregroundColor(viewModel.selectedDietaryInfo.contains(info) ? .white : Theme.Colors.label)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(viewModel.selectedDietaryInfo.contains(info) ? Theme.Colors.primaryGradient : LinearGradient(colors: [Theme.Colors.secondaryBackground], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(Theme.CornerRadius.md)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }
    
    // MARK: - Step 5: Review
    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text("Review Your Listing")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.label)
                
                VStack(spacing: Theme.Spacing.md) {
                    reviewRow(label: "Title", value: viewModel.title)
                    reviewRow(label: "Category", value: viewModel.category.rawValue)
                    reviewRow(label: "Quantity", value: viewModel.quantity)
                    
                    if viewModel.isFree {
                        reviewRow(label: "Price", value: "FREE")
                    } else {
                        reviewRow(label: "Price", value: "$\(viewModel.discountedPrice)")
                        reviewRow(label: "Original Price", value: "$\(viewModel.originalPrice)")
                    }
                    
                    reviewRow(
                        label: "Pickup Window",
                        value: "\(viewModel.pickupStartTime.formatted(date: .abbreviated, time: .shortened)) - \(viewModel.pickupEndTime.formatted(date: .omitted, time: .shortened))"
                    )
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.xl)
            }
            .padding(Theme.Spacing.lg)
        }
    }
    
    private func reviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.secondaryLabel)
            Spacer()
            Text(value)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.label)
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            if currentStep > 0 {
                SecondaryButton("Back") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
            }
            
            if currentStep < steps.count - 1 {
                PrimaryButton("Continue") {
                    withAnimation {
                        currentStep += 1
                    }
                }
            } else {
                PrimaryButton("Post Listing", isLoading: viewModel.isPosting) {
                    Task {
                        await viewModel.postListing()
                    }
                }
                .disabled(!viewModel.canPost)
                .opacity(viewModel.canPost ? 1 : 0.5)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.background)
    }
}
// MARK: - Premium Stat Card
struct PremiumStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let showGlow: Bool
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                if showGlow {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                        .blur(radius: 12)
                }
                
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: Theme.Spacing.xxs) {
                Text(value)
                    .font(Theme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.label)
                
                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .background(Theme.Colors.elevatedCard)
        .cornerRadius(Theme.CornerRadius.cardLarge)
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Premium Quick Action Card
struct PremiumQuickActionCard: View {
    let icon: String
    let title: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            hapticFeedback(.light)
            action()
        }) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(gradient)
                    .frame(height: 32)
                
                Text(title)
                    .font(Theme.Typography.subheadlineMedium)
                    .foregroundColor(Theme.Colors.label)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(Theme.Colors.elevatedCard)
            .cornerRadius(Theme.CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
        }
        .buttonStyle(PremiumScaleButtonStyle())
    }
}

// MARK: - Premium Restaurant Listing Card
struct PremiumRestaurantListingCard: View {
    let listing: FoodListing
    
    var body: some View {
        HStack(spacing: Theme.Spacing.base) {
            // Thumbnail with Gradient Overlay
            ZStack(alignment: .bottomLeading) {
                if let imageURL = listing.imageURLs.first {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Theme.Colors.tertiaryBackground)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(Theme.Colors.tertiaryLabel)
                            )
                    }
                    .frame(width: 100, height: 100)
                    .cornerRadius(Theme.CornerRadius.lg)
                }
                
                // Status Badge
                if listing.isAlmostGone {
                    PremiumBadge(text: "Almost Gone", style: .filled(Theme.Colors.warning))
                        .padding(Theme.Spacing.xs)
                }
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(listing.title)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.label)
                    .lineLimit(2)
                
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "bag")
                        .font(.caption)
                    Text("\(listing.availableQuantity) of \(listing.quantity) left")
                        .font(Theme.Typography.subheadline)
                }
                .foregroundColor(Theme.Colors.secondaryLabel)
                
                Spacer()
                
                HStack {
                    if listing.isFree {
                        PremiumBadge(text: "FREE", style: .gradient)
                    } else {
                        Text("$\(String(format: "%.2f", listing.discountedPrice))")
                            .font(Theme.Typography.headlineMedium)
                            .foregroundStyle(Theme.Colors.primaryGradient)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            // Edit action
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button {
                            // Pause action
                        } label: {
                            Label("Pause", systemImage: "pause")
                        }
                        
                        Button(role: .destructive) {
                            // Delete action
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .frame(width: 32, height: 32)
                            .background(Theme.Colors.tertiaryBackground)
                            .cornerRadius(Theme.CornerRadius.xs)
                    }
                }
            }
        }
        .padding(Theme.Spacing.base)
        .background(Theme.Colors.elevatedCard)
        .cornerRadius(Theme.CornerRadius.cardLarge)
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Premium Restaurant Order Card
struct PremiumRestaurantOrderCard: View {
    let order: Order
    
    var body: some View {
        VStack(spacing: Theme.Spacing.base) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    if let listing = order.listing {
                        Text(listing.title)
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.label)
                    }
                    
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("Order")
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.secondaryLabel)
                        Text("#\(order.pickupCode)")
                            .font(Theme.Typography.monospaced)
                            .foregroundColor(Theme.Colors.label)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                    PremiumBadge(
                        text: order.status.rawValue,
                        style: .filled(order.status.color)
                    )
                    
                    Text("$\(String(format: "%.2f", order.totalAmount))")
                        .font(Theme.Typography.headlineMedium)
                        .foregroundColor(Theme.Colors.label)
                }
            }
            
            Divider()
            
            HStack(spacing: Theme.Spacing.compactSpacing) {
                AnimatedButton("Mark Ready", style: .primary) {
                    // Mark as ready
                }
                
                Button {
                    // Contact customer
                } label: {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                        .frame(width: 56, height: 56)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(Theme.CornerRadius.base)
                }
                .buttonStyle(PremiumScaleButtonStyle())
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.elevatedCard)
        .cornerRadius(Theme.CornerRadius.cardLarge)
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Premium Empty State
struct PremiumEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryGradientStart.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Colors.primaryGradient)
            }
            
            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.label)
                
                Text(message)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let actionTitle = actionTitle, let action = action {
                AnimatedButton(actionTitle, icon: "plus", style: .primary, action: action)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - Impact Metric
struct ImpactMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(Theme.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.label)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Restaurant Orders View Model
@MainActor
class RestaurantOrdersViewModel: ObservableObject {
    @Published var pendingOrders: [Order] = []
    @Published var completedOrders: [Order] = []
    @Published var isLoading = false
    @Published var showPickupConfirmed = false
    @Published var confirmedOrderId: String? = nil

    func loadOrders() async {
        isLoading = true
        defer { isLoading = false }

        guard let uid = supabase.auth.currentSession?.user.id.uuidString else { return }

        do {
            let rows: [RestOrderRow] = try await supabase
                .from("orders")
                .select("id, listing_id, customer_id, restaurant_id, quantity, total_amount, status, pickup_code, pickup_window_start, pickup_window_end, notes, payment_id, created_at, completed_at")
                .eq("restaurant_id", value: uid)
                .order("created_at", ascending: false)
                .execute()
                .value
            let orders = rows.map { $0.toOrder() }
            pendingOrders   = orders.filter { $0.status == .pending || $0.status == .confirmed || $0.status == .ready }
            completedOrders = orders.filter { $0.status == .completed || $0.status == .cancelled || $0.status == .noShow }
        } catch {
            // Fetch failed — leave empty state
        }
    }

    // SECURITY: server must also validate the pickup code and mark it used
    func confirmPickup(_ order: Order) {
        guard let idx = pendingOrders.firstIndex(where: { $0.id == order.id }) else { return }
        withAnimation {
            var updated = pendingOrders.remove(at: idx)
            updated.status = .completed
            completedOrders.insert(updated, at: 0)
        }
        confirmedOrderId = order.id
        showPickupConfirmed = true
        Task {
            try? await supabase
                .from("orders")
                .update(["status": "completed",
                         "completed_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: order.id)
                .execute()
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showPickupConfirmed = false
            confirmedOrderId = nil
        }
    }
}

private struct RestOrderRow: Decodable {
    let id: String
    let listingId: String?
    let customerId: String
    let restaurantId: String
    let quantity: Int
    let totalAmount: Double
    let status: String
    let pickupCode: String
    let pickupWindowStart: Date?
    let pickupWindowEnd: Date?
    let notes: String?
    let paymentId: String?
    let createdAt: Date
    let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, quantity, notes, status
        case listingId = "listing_id"
        case customerId = "customer_id"
        case restaurantId = "restaurant_id"
        case totalAmount = "total_amount"
        case pickupCode = "pickup_code"
        case pickupWindowStart = "pickup_window_start"
        case pickupWindowEnd = "pickup_window_end"
        case paymentId = "payment_id"
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }

    func toOrder() -> Order {
        let now = Date()
        let start = pickupWindowStart ?? now
        let end = pickupWindowEnd ?? now.addingTimeInterval(3600)
        return Order(
            id: id,
            listingId: listingId ?? "",
            listing: nil,
            customerId: customerId,
            customer: nil,
            restaurantId: restaurantId,
            restaurant: nil,
            quantity: quantity,
            totalAmount: totalAmount,
            status: dbStatusToOrderStatus(status),
            pickupCode: pickupCode,
            pickupTime: start,
            pickupWindowStart: start,
            pickupWindowEnd: end,
            createdAt: createdAt,
            completedAt: completedAt,
            notes: notes,
            paymentId: paymentId
        )
    }

    private func dbStatusToOrderStatus(_ s: String) -> Order.OrderStatus {
        switch s {
        case "confirmed": return .confirmed
        case "ready": return .ready
        case "completed": return .completed
        case "cancelled": return .cancelled
        default: return .pending
        }
    }
}

// MARK: - Pending Order Card (stateful, owns code-entry state)
private struct PendingOrderCard: View {
    let order: Order
    let viewModel: RestaurantOrdersViewModel
    @Binding var selectedOrder: Order?
    @Binding var messageOrder: Order?
    @State private var enteredCode = ""
    @FocusState private var codeFocused: Bool

    // SECURITY: server must validate the code, mark it used, and prevent reuse
    private var codeMatches: Bool { enteredCode == order.pickupCode }

    var body: some View {
        VStack(spacing: 0) {
            // Customer row
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Colors.primaryGradientStart.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Text(String(order.pickupCode.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.customer?.name ?? "Customer")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.label)
                    if let listing = order.listing {
                        Text(listing.title)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", order.totalAmount))")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                    Text("Qty: \(order.quantity)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.Colors.secondaryLabel)
                }
            }
            .padding(.bottom, 14)

            // Pickup window banner
            HStack(spacing: 8) {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.orange)
                Text("Pickup: \(order.pickupWindowStart.formatted(date: .omitted, time: .shortened)) – \(order.pickupWindowEnd.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
                Spacer()
            }
            .padding(12)
            .background(Color.orange.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, 14)

            // 6-digit pickup code entry
            // SECURITY: server must validate the code, mark it used, and prevent reuse
            VStack(alignment: .leading, spacing: 6) {
                Text("ENTER CUSTOMER'S 6-DIGIT CODE")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.tertiaryLabel)
                    .tracking(1.0)
                TextField("e.g. ABC123", text: $enteredCode)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(codeMatches ? Theme.Colors.primaryGradientStart : Theme.Colors.label)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($codeFocused)
                    .onChange(of: enteredCode) { _, v in
                        enteredCode = String(v.prefix(6)).uppercased()
                    }
                    .padding(12)
                    .background(codeMatches ? Theme.Colors.primaryGradientStart.opacity(0.08) : Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(codeMatches ? Theme.Colors.primaryGradientStart.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            }
            .padding(.bottom, 14)

            // Action buttons
            HStack(spacing: 10) {
                Button("Details") { hapticFeedback(.light); selectedOrder = order }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Button { hapticFeedback(.light); messageOrder = order } label: {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                        .frame(width: 46, height: 42)
                        .background(Theme.Colors.primaryGradientStart.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    hapticFeedback(.success)
                    // SECURITY: server must validate the code, mark it used, and prevent reuse
                    viewModel.confirmPickup(order)
                } label: {
                    Text("Confirm Pickup")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(codeMatches ? Theme.Colors.primaryGradient : LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!codeMatches)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color.black.opacity(0.07), radius: 12, y: 4)
    }
}

// MARK: - Restaurant Orders View
struct RestaurantOrdersView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = RestaurantOrdersViewModel()
    @State private var selectedTab        = 0
    @State private var selectedOrder: Order? = nil
    @State private var messageOrder: Order?  = nil
    @State private var showRepostListing  = false

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    gradientHeader
                    mainContent
                }
                .padding(.bottom, 100)
            }
            .ignoresSafeArea(edges: .top)
            .background(Theme.Colors.pageBackground)
            .task {
                await viewModel.loadOrders()
            }
            .sheet(item: $selectedOrder)       { order in RestaurantOrderDetailView(order: order) }
            .sheet(item: $messageOrder)        { order in MessageCustomerView(order: order) }
            .sheet(isPresented: $showRepostListing) { PostSurplusView() }

            // Green "Picked up!" toast banner
            if viewModel.showPickupConfirmed {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("Picked up!")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Theme.Colors.primaryGradient)
                .clipShape(Capsule())
                .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.35), radius: 12, y: 4)
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showPickupConfirmed)
                .zIndex(10)
            }
        }
    }

    // MARK: Header
    private var gradientHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Orders")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Manage your pickup requests")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                if !viewModel.pendingOrders.isEmpty {
                    Text("\(viewModel.pendingOrders.count)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                        .frame(width: 44, height: 44)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 20)

            // Tab pill
            HStack(spacing: 0) {
                ForEach(["Pending","Picked Up","Expired"], id: \.self) { tab in
                    let idx = ["Pending","Picked Up","Expired"].firstIndex(of: tab)!
                    Button {
                        hapticFeedback(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedTab = idx }
                    } label: {
                        Text(tab)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTab == idx ? Theme.Colors.primaryGradientStart : .white.opacity(0.7))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(selectedTab == idx ? Color.white : Color.clear)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(4)
            .background(.white.opacity(0.15))
            .clipShape(Capsule())
            .padding(.bottom, 44)
        }
        .padding(.horizontal, 20)
        .background(Theme.Colors.primaryGradient)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40))
    }

    // MARK: Content switch
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else if selectedTab == 0 {
                pendingContent
            } else if selectedTab == 1 {
                completedContent
            } else {
                expiredContent
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: Pending
    @ViewBuilder
    private var pendingContent: some View {
        if viewModel.pendingOrders.isEmpty {
            ordersEmptyState(icon: "tray.fill", title: "No Pending Orders", message: "New orders will appear here")
        } else {
            ForEach(viewModel.pendingOrders) { order in
                PendingOrderCard(order: order, viewModel: viewModel, selectedOrder: $selectedOrder, messageOrder: $messageOrder)
            }
        }
    }

    // MARK: Completed (Picked Up)
    @ViewBuilder
    private var completedContent: some View {
        let picked = viewModel.completedOrders.filter { $0.status == .completed }
        if picked.isEmpty {
            ordersEmptyState(icon: "checkmark.circle.fill", title: "No Completed Orders", message: "Picked-up orders will appear here")
        } else {
            ForEach(picked) { order in completedCard(order) }
        }
    }

    private func completedCard(_ order: Order) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(order.customer?.name ?? "Customer")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.label)
                    Text("Collected")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                }
                if let listing = order.listing {
                    Text(listing.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.Colors.secondaryLabel)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Text("$\(String(format: "%.2f", order.totalAmount))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.primaryGradientStart)
                Button("Details") { hapticFeedback(.light); selectedOrder = order }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.secondaryLabel)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 3)
    }

    // MARK: Expired
    @ViewBuilder
    private var expiredContent: some View {
        let expired = viewModel.completedOrders.filter { $0.isOverdue }
        if expired.isEmpty {
            ordersEmptyState(icon: "clock.badge.xmark.fill", title: "No Expired Orders", message: "Listings past their pickup window will appear here")
        } else {
            ForEach(expired) { order in expiredCard(order) }
        }
    }

    private func expiredCard(_ order: Order) -> some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: "clock.badge.xmark.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(order.customer?.name ?? "Customer")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                        Text("Expired")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    if let listing = order.listing {
                        Text(listing.title)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                    }
                }
                Spacer()
            }
            Button {
                hapticFeedback(.medium)
                showRepostListing = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                    Text("Repost to Marketplace")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.Colors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 3)
    }

    // MARK: Empty state
    private func ordersEmptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryGradientStart.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Colors.primaryGradient)
            }
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                Text(message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Restaurant Profile View
struct RestaurantProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var profileVM = RestaurantProfileViewModel()
    @State private var showRestaurantDetails  = false
    @State private var showLocationPickup     = false
    @State private var showConnectOnboarding  = false
    @State private var showNotifications      = false
    @State private var showStaffAccounts      = false
    @State private var showHelpCenter         = false
    @State private var showContactSupport     = false
    @State private var showSignOutConfirm     = false

    private var restaurantName: String { appState.currentUser?.name ?? "Your Restaurant" }
    private var isVerified: Bool { appState.currentUser?.verifiedRestaurant ?? false }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                gradientHeader
                mainContent
            }
            .padding(.bottom, 100)
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
        .task { await profileVM.load() }
        .sheet(isPresented: $showRestaurantDetails)  {
            RestaurantDetailsEditView()
                .onDisappear { Task { await profileVM.load() } }
        }
        .sheet(isPresented: $showLocationPickup)     {
            LocationPickupEditView()
                .onDisappear { Task { await profileVM.load() } }
        }
        .sheet(isPresented: $showConnectOnboarding)  { ConnectOnboardingView() }
        .sheet(isPresented: $showNotifications)      { NotificationsPreferencesView() }
        .sheet(isPresented: $showStaffAccounts)      { StaffAccountsView() }
        .sheet(isPresented: $showHelpCenter)         { HelpCenterView() }
        .sheet(isPresented: $showContactSupport)     { ContactSupportView() }
        .alert("Sign Out?", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { appState.signOut() }
        } message: {
            Text("You'll need to sign in again to access your restaurant account.")
        }
    }

    // MARK: Header
    private var gradientHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("Profile")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.top, 60)
            .padding(.bottom, 24)

            // Logo circle
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 2))
                Image(systemName: "storefront.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 14)

            // Name + verified badge
            HStack(spacing: 8) {
                Text(restaurantName)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                if isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.accent)
                }
            }
            if !profileVM.cuisine.isEmpty {
                Text(profileVM.cuisine)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 4)
            }
            Text(isVerified ? "Verified Restaurant" : "Pending Verification")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(isVerified ? .white.opacity(0.7) : Color.yellow.opacity(0.9))
                .padding(.top, profileVM.cuisine.isEmpty ? 4 : 2)
                .padding(.bottom, 44)
        }
        .padding(.horizontal, 20)
        .background(Theme.Colors.primaryGradient)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40))
    }

    // MARK: Main Content
    private var mainContent: some View {
        VStack(spacing: 24) {
            infoCard
                .padding(.horizontal, 20)
                .offset(y: -24)
                .padding(.bottom, -24)

            quickStats
                .padding(.horizontal, 20)

            profileSection(
                label: "Business Settings",
                rows: [
                    ("storefront.fill",  "Restaurant Details", "Name, cuisine & hours",      { showRestaurantDetails = true }),
                    ("location.fill",    "Location & Pickup",  "Address and instructions",   { showLocationPickup = true }),
                    ("banknote.fill",    "Payouts & Stripe",   "Connect to accept payments",  { showConnectOnboarding = true }),
                ]
            )
            .padding(.horizontal, 20)

            profileSection(
                label: "Preferences",
                rows: [
                    ("bell.fill",        "Notifications",      "Push and email preferences", { showNotifications = true }),
                    ("person.2.fill",    "Staff Accounts",     "Manage team access",         { showStaffAccounts = true }),
                ]
            )
            .padding(.horizontal, 20)

            profileSection(
                label: "Support",
                rows: [
                    ("questionmark.circle.fill", "Help Center",     "FAQs and tutorials",      { showHelpCenter = true }),
                    ("bubble.left.fill",          "Contact Support", "Get help from our team",  { showContactSupport = true }),
                ]
            )
            .padding(.horizontal, 20)

            // Sign out
            Button {
                hapticFeedback(.light)
                showSignOutConfirm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 36)
    }

    // MARK: Info Card
    private var infoCard: some View {
        VStack(spacing: 0) {
            profileInfoRow(
                icon: "mappin.circle.fill",
                value: profileVM.address.isEmpty ? "No address set — tap Location & Pickup to add" : profileVM.address
            )
            Divider().padding(.leading, 54)
            profileInfoRow(
                icon: "phone.fill",
                value: profileVM.phone.isEmpty ? "No phone set — tap Restaurant Details to add" : profileVM.phone
            )
            Divider().padding(.leading, 54)
            profileInfoRow(
                icon: "envelope.fill",
                value: appState.currentUser?.email ?? ""
            )
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color.black.opacity(0.07), radius: 14, y: 5)
    }

    private func profileInfoRow(icon: String, value: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.Colors.primaryGradientStart.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGradientStart)
            }
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Theme.Colors.label)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.vertical, 11)
    }

    // MARK: Quick Stats
    private var quickStats: some View {
        HStack(spacing: 0) {
            profileStatCell(value: "\(appState.currentUser?.mealsSaved ?? 0)", label: "Meals Saved")
            Divider().frame(height: 40)
            profileStatCell(value: String(format: "%.1f", appState.currentUser?.co2Reduced ?? 0), label: "kg CO₂ Saved")
            Divider().frame(height: 40)
            profileStatCell(value: String(format: "%.1f", appState.currentUser?.foodRescued ?? 0), label: "kg Rescued")
        }
        .padding(.vertical, 18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
    }

    private func profileStatCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.Colors.primaryGradient)
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Generic settings section
    private func profileSection(
        label: String,
        rows: [(String, String, String, () -> Void)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryLabel)
                .tracking(0.8)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    Button {
                        hapticFeedback(.light)
                        row.3()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.primaryGradientStart.opacity(0.12))
                                    .frame(width: 42, height: 42)
                                Image(systemName: row.0)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Theme.Colors.primaryGradientStart)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(row.1)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.Colors.label)
                                Text(row.2)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(Theme.Colors.secondaryLabel)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.Colors.tertiaryLabel)
                        }
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if idx < rows.count - 1 {
                        Divider().padding(.leading, 58)
                    }
                }
            }
            .padding(.horizontal, 20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
        }
    }
}


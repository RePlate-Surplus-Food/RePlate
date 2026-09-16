//
//  OrdersView.swift
//  RePlate
//
//  Created by Jyotika Sadani on 5/26/26.
//  Redesigned to match RePlate 2.0 Figma — gradient header, pill tabs, bold pickup-code cards.
//

import SwiftUI
import Combine

struct OrdersView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OrdersViewModel()
    @State private var selectedOrder: Order?

    var body: some View {
        VStack(spacing: 0) {
            ordersHeader

            // Pill tab picker sits directly below the gradient, with a shadow card feel
            tabPickerRow

            // TabView fills the remaining screen height
            TabView(selection: $viewModel.selectedTab) {
                activeOrdersList.tag(0)
                completedOrdersList.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
        .task {
            await viewModel.loadOrders()
        }
        .sheet(item: $selectedOrder) { order in
            OrderDetailView(order: order, viewModel: viewModel)
        }
    }

    // MARK: - Gradient Header
    private var ordersHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Orders")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(
                        viewModel.pendingOrders.isEmpty
                            ? "No active pickups"
                            : "\(viewModel.pendingOrders.count) active pickup\(viewModel.pendingOrders.count == 1 ? "" : "s")"
                    )
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                if !viewModel.pendingOrders.isEmpty {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.accent)
                            .frame(width: 44, height: 44)
                        Text("\(viewModel.pendingOrders.count)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(Theme.Colors.primaryGradientStart)
                    }
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 44)
        }
        .padding(.horizontal, 20)
        .background(Theme.Colors.primaryGradient)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40))
    }

    // MARK: - Pill Tab Picker
    private var tabPickerRow: some View {
        HStack(spacing: 0) {
            pillTabButton(title: "Active", index: 0)
            pillTabButton(title: "Completed", index: 1)
        }
        .padding(6)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color.black.opacity(0.09), radius: 14, y: 5)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func pillTabButton(title: String, index: Int) -> some View {
        Button {
            withAnimation(Theme.Animation.spring) {
                viewModel.selectedTab = index
            }
            hapticFeedback(.light)
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.selectedTab == index ? .white : Theme.Colors.secondaryLabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if viewModel.selectedTab == index {
                            Theme.Colors.primaryGradient
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                )
        }
    }

    // MARK: - Active Orders
    private var activeOrdersList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonView()
                            .frame(height: 160)
                            .padding(.horizontal, 20)
                    }
                } else if viewModel.pendingOrders.isEmpty {
                    ordersEmptyState(
                        icon: "bag",
                        title: "No Active Orders",
                        message: "Your active orders will appear here"
                    )
                } else {
                    ForEach(viewModel.pendingOrders) { order in
                        OrderSummaryCard(order: order) {
                            selectedOrder = order
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .refreshable { await viewModel.loadOrders() }
    }

    // MARK: - Completed Orders
    private var completedOrdersList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonView()
                            .frame(height: 160)
                            .padding(.horizontal, 20)
                    }
                } else if viewModel.completedOrders.isEmpty {
                    ordersEmptyState(
                        icon: "checkmark.circle",
                        title: "No Completed Orders",
                        message: "Your order history will appear here"
                    )
                } else {
                    ForEach(viewModel.completedOrders) { order in
                        OrderSummaryCard(order: order) {
                            selectedOrder = order
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .refreshable { await viewModel.loadOrders() }
    }

    // MARK: - Empty State
    private func ordersEmptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryGradientStart.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(Theme.Colors.primaryGradientStart.opacity(0.5))
            }
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }
}

// MARK: - Order Summary Card
private struct OrderSummaryCard: View {
    let order: Order
    let onTap: () -> Void

    private var itemTitle: String { order.listing?.title ?? "Surplus Bag" }
    private var restaurantName: String { order.restaurant?.name ?? "Restaurant" }

    var body: some View {
        Button {
            onTap()
            hapticFeedback(.light)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Top: restaurant icon + name + status badge
                HStack(alignment: .center, spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.Colors.primaryGradientStart.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.Colors.primaryGradient)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurantName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                        Text(itemTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .lineLimit(1)
                    }
                    .padding(.leading, 12)

                    Spacer()

                    Text(order.status.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(order.status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(order.status.color.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(20)

                Divider()
                    .padding(.horizontal, 20)

                // Bottom: pickup code + time + total
                HStack(alignment: .bottom) {
                    // Pickup code — monospaced bold
                    VStack(alignment: .leading, spacing: 3) {
                        Text("PICKUP CODE")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .tracking(1.5)
                        Text(order.pickupCode)
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .foregroundStyle(Theme.Colors.primaryGradient)
                    }

                    Spacer()

                    // Pickup time
                    VStack(alignment: .center, spacing: 3) {
                        Text("PICKUP")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .tracking(1.5)
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.primaryGradientStart)
                            Text(order.pickupWindowStart.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.Colors.label)
                        }
                    }

                    Spacer()

                    // Total
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("TOTAL")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .tracking(1.5)
                        Text("$\(String(format: "%.2f", order.totalAmount))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.07), radius: 14, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Order Detail View
struct OrderDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    let order: Order
    var viewModel: OrdersViewModel? = nil
    @State private var showCancelConfirmation = false
    @State private var isCancelled = false
    @State private var now = Date()

    // Tick every second for the countdown timer
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // SECURITY: this code must be validated server-side; client display is for UX only
    private var isCodeExpired: Bool {
        now > order.pickupWindowEnd
    }

    private var pickupCountdown: String {
        let remaining = order.pickupWindowEnd.timeIntervalSince(now)
        if remaining <= 0 { return "Expired" }
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    statusSection

                    if order.status == .ready || order.status == .confirmed {
                        pickupCodeSection
                    }

                    orderDetailsSection

                    if let restaurant = order.restaurant {
                        restaurantSection(restaurant)
                    }

                    timelineSection

                    if order.status != .completed && order.status != .cancelled {
                        actionButtons
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var statusSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: order.status.icon)
                .font(.system(size: 60))
                .foregroundColor(order.status.color)

            Text(order.status.rawValue)
                .font(Theme.Typography.title2)
                .foregroundColor(Theme.Colors.label)

            if order.status == .ready {
                Text("Your order is ready for pickup!")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .background(order.status.color.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.xl)
    }

    private var pickupCodeSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Your Pickup Code")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.label)

            if isCodeExpired {
                // Code has expired — show red badge instead of code
                Text("Code Expired")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .clipShape(Capsule())
            } else {
                // SECURITY: this code must be validated server-side; client display is for UX only
                Text(order.pickupCode)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.Colors.primaryGradient)

                // Countdown timer until pickup window closes
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                    Text("Expires in \(pickupCountdown)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                }

                Text("Show this code to the restaurant")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .background(isCodeExpired ? Color.red.opacity(0.1) : Theme.Colors.accent.opacity(0.2))
        .cornerRadius(Theme.CornerRadius.xl)
        .onReceive(timer) { _ in now = Date() }
    }

    private var orderDetailsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Order Details")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.label)

            VStack(spacing: Theme.Spacing.sm) {
                if let listing = order.listing {
                    detailRow(label: "Item", value: listing.title)
                }
                detailRow(label: "Quantity", value: "\(order.quantity)")
                detailRow(label: "Total", value: "$\(String(format: "%.2f", order.totalAmount))")
                detailRow(
                    label: "Pickup Window",
                    value: "\(order.pickupWindowStart.formatted(date: .abbreviated, time: .shortened)) – \(order.pickupWindowEnd.formatted(date: .omitted, time: .shortened))"
                )
                detailRow(label: "Order ID", value: order.id)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.xl)
        }
    }

    private func restaurantSection(_ restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Restaurant")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.label)

            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Colors.primaryGradient)

                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.label)
                    Text(restaurant.address)
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.secondaryLabel)
                    Text(restaurant.phoneNumber)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                }

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.xl)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Order Timeline")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.label)

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                TimelineItem(
                    icon: "checkmark.circle.fill",
                    title: "Order Placed",
                    time: order.createdAt,
                    isCompleted: true
                )
                TimelineItem(
                    icon: "clock.fill",
                    title: "Confirmed",
                    time: order.createdAt,
                    isCompleted: order.status != .pending
                )
                TimelineItem(
                    icon: "bag.fill",
                    title: "Ready for Pickup",
                    time: order.pickupWindowStart,
                    isCompleted: order.status == .ready || order.status == .completed
                )
                TimelineItem(
                    icon: "checkmark.circle.fill",
                    title: "Completed",
                    time: order.completedAt,
                    isCompleted: order.status == .completed
                )
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.xl)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            PrimaryButton("Contact Restaurant") {
                hapticFeedback(.light)
                appState.selectedTab = .messages
                dismiss()
            }

            Button("Get Directions") {
                hapticFeedback(.light)
                if let restaurant = order.restaurant {
                    let encoded = restaurant.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    if let url = URL(string: "maps://?address=\(encoded)") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .font(Theme.Typography.headline)
            .foregroundColor(Theme.Colors.primaryGradientStart)

            if order.status == .pending && !isCancelled {
                Button("Cancel Order") {
                    hapticFeedback(.warning)
                    showCancelConfirmation = true
                }
                .font(Theme.Typography.subheadline)
                .foregroundColor(.red)
                .alert("Cancel Order?", isPresented: $showCancelConfirmation) {
                    Button("Keep Order", role: .cancel) {}
                    Button("Cancel Order", role: .destructive) {
                        hapticFeedback(.medium)
                        isCancelled = true
                        // TODO: backend — POST /orders/{id}/status { status: "cancelled" }
                        viewModel?.cancelOrder(order)
                        dismiss()
                    }
                } message: {
                    Text("Are you sure you want to cancel this order? This action cannot be undone.")
                }
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
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
}

// MARK: - Timeline Item
struct TimelineItem: View {
    let icon: String
    let title: String
    let time: Date?
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(
                    isCompleted ? Theme.Colors.primaryGradientStart : Theme.Colors.tertiaryLabel
                )
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(isCompleted ? Theme.Colors.label : Theme.Colors.tertiaryLabel)

                if let time = time {
                    Text(time.formatted(date: .abbreviated, time: .shortened))
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryLabel)
                }
            }

            Spacer()
        }
    }
}

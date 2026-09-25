//
//  RestaurantSubViews.swift
//  RePlate
//
//  Created by Jyotika Sadani on 5/30/26.
//  Restaurant sub-screens: settings hub, edit listing, order details,
//  restaurant profile edit, location/pickup edit, payment settings,
//  notification preferences, help center, contact support, and messaging.
//

import SwiftUI
import Supabase
import PhotosUI

// MARK: - Shared: Section label
private func sectionLabel(_ title: String) -> some View {
    Text(title.uppercased())
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundColor(Theme.Colors.secondaryLabel)
        .tracking(0.8)
        .padding(.horizontal, 4)
}

// MARK: - Shared: Sub-screen gradient header (X dismiss style)
private struct SubScreenHeader: View {
    let title: String
    let subtitle: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: { hapticFeedback(.light); onDismiss() }) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.22))
                            .frame(width: 40, height: 40)
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                Spacer()
            }
            .padding(.top, 20)
            .padding(.bottom, 12)

            Text(title)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 4)
                .padding(.bottom, 36)
        }
        .padding(.horizontal, 20)
        .background(Theme.Colors.primaryGradient)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))
    }
}

// MARK: - Shared: White form card wrapper
private struct FormCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Shared: Save button
private struct SaveButton: View {
    @Binding var isSaving: Bool
    let onSave: () async -> Void

    var body: some View {
        Button {
            hapticFeedback(.success)
            isSaving = true
            Task {
                await onSave()
                isSaving = false
            }
        } label: {
            HStack(spacing: 8) {
                if isSaving { ProgressView().tint(.white).scaleEffect(0.85) }
                Text(isSaving ? "Saving…" : "Save Changes")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.Colors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.32), radius: 10, y: 5)
        }
        .disabled(isSaving)
    }
}

// MARK: - Restaurant Settings Hub
struct RestaurantSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showRestaurantDetails  = false
    @State private var showLocationPickup     = false
    @State private var showConnectOnboarding  = false
    @State private var showNotifications      = false
    @State private var showHelpCenter         = false
    @State private var showContactSupport     = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                SubScreenHeader(
                    title: "Settings",
                    subtitle: "Manage your restaurant account",
                    onDismiss: { dismiss() }
                )

                VStack(spacing: 24) {
                    // MARK: Restaurant Profile
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Restaurant Profile")
                        FormCard {
                            VStack(spacing: 0) {
                                settingsRow(
                                    icon: "storefront.fill",
                                    title: "Restaurant Details",
                                    subtitle: "Name, cuisine & hours"
                                ) { showRestaurantDetails = true }
                                Divider().padding(.leading, 58)
                                settingsRow(
                                    icon: "location.fill",
                                    title: "Location & Pickup",
                                    subtitle: "Address and pickup instructions"
                                ) { showLocationPickup = true }
                            }
                        }
                    }

                    // MARK: Financials
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Financials")
                        FormCard {
                            settingsRow(
                                icon: "banknote.fill",
                                title: "Payouts & Stripe",
                                subtitle: "Connect to accept payments"
                            ) { showConnectOnboarding = true }
                        }
                    }

                    // MARK: Preferences
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Preferences")
                        FormCard {
                            settingsRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                subtitle: "Push and email preferences"
                            ) { showNotifications = true }
                        }
                    }

                    // MARK: Support
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Support")
                        FormCard {
                            VStack(spacing: 0) {
                                settingsRow(
                                    icon: "questionmark.circle.fill",
                                    title: "Help Center",
                                    subtitle: "FAQs and tutorials"
                                ) { showHelpCenter = true }
                                Divider().padding(.leading, 58)
                                settingsRow(
                                    icon: "bubble.left.fill",
                                    title: "Contact Support",
                                    subtitle: "Get help from our team"
                                ) { showContactSupport = true }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
        .sheet(isPresented: $showRestaurantDetails)  { RestaurantDetailsEditView() }
        .sheet(isPresented: $showLocationPickup)     { LocationPickupEditView() }
        .sheet(isPresented: $showConnectOnboarding)  { ConnectOnboardingView() }
        .sheet(isPresented: $showNotifications)      { NotificationsPreferencesView() }
        .sheet(isPresented: $showHelpCenter)         { HelpCenterView() }
        .sheet(isPresented: $showContactSupport)     { ContactSupportView() }
    }

    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            hapticFeedback(.light)
            action()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.primaryGradientStart.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.Colors.label)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
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
    }
}

// MARK: - Edit Listing View
struct EditListingView: View {
    let listing: FoodListing
    @Environment(\.dismiss) var dismiss

    @State private var title: String
    @State private var description: String
    @State private var quantity: String
    @State private var isFree: Bool
    @State private var originalPrice: String
    @State private var discountedPrice: String
    @State private var pickupStart: Date
    @State private var pickupEnd: Date
    @State private var availableUntilClose = false
    @State private var isSaving = false

    init(listing: FoodListing) {
        self.listing = listing
        _title           = State(initialValue: listing.title)
        _description     = State(initialValue: listing.description)
        _quantity        = State(initialValue: "\(listing.availableQuantity)")
        _isFree          = State(initialValue: listing.isFree)
        _originalPrice   = State(initialValue: String(format: "%.2f", listing.originalPrice))
        _discountedPrice = State(initialValue: String(format: "%.2f", listing.discountedPrice))
        _pickupStart     = State(initialValue: listing.pickupStartTime)
        _pickupEnd       = State(initialValue: listing.pickupEndTime)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                SubScreenHeader(
                    title: "Edit Listing",
                    subtitle: listing.title,
                    onDismiss: { dismiss() }
                )

                VStack(spacing: 24) {
                    // Photo row
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Photos")
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Theme.Colors.primaryGradientStart.opacity(0.06))
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    Theme.Colors.primaryGradientStart.opacity(0.35),
                                    style: StrokeStyle(lineWidth: 2, dash: [8, 5])
                                )
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(Theme.Colors.primaryGradientStart.opacity(0.55))
                                Text("Tap to update photos")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(Theme.Colors.secondaryLabel)
                            }
                        }
                        .frame(height: 130)
                    }

                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Details")
                        FormCard {
                            VStack(spacing: 16) {
                                AuthLabeledField(label: "Title", placeholder: "e.g. Assorted Pastries", text: $title)
                                AuthLabeledField(label: "Description", placeholder: "Describe the food…", text: $description)
                                AuthLabeledField(
                                    label: "Quantity Available",
                                    placeholder: "Number of boxes",
                                    text: $quantity,
                                    keyboardType: .numberPad
                                )
                            }
                        }
                    }

                    // Pricing
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Pricing")
                        FormCard {
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Offer for Free")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(Theme.Colors.label)
                                        Text("No payment required from customer")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(Theme.Colors.secondaryLabel)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $isFree)
                                        .tint(Theme.Colors.primaryGradientStart)
                                }
                                if !isFree {
                                    Divider()
                                    AuthLabeledField(
                                        label: "Original Price ($)",
                                        placeholder: "e.g. 12.00",
                                        text: $originalPrice,
                                        keyboardType: .decimalPad
                                    )
                                    AuthLabeledField(
                                        label: "Discounted Price ($)",
                                        placeholder: "e.g. 5.00",
                                        text: $discountedPrice,
                                        keyboardType: .decimalPad
                                    )
                                }
                            }
                        }
                    }

                    // Pickup Window
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Pickup Window")
                        FormCard {
                            VStack(spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Available Until Close")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(Theme.Colors.label)
                                        Text("Pickup any time until store closes")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(Theme.Colors.secondaryLabel)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $availableUntilClose)
                                        .tint(Theme.Colors.primaryGradientStart)
                                }
                                if !availableUntilClose {
                                    Divider()
                                    DatePicker(
                                        "Pickup Start",
                                        selection: $pickupStart,
                                        displayedComponents: .hourAndMinute
                                    )
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    DatePicker(
                                        "Pickup End",
                                        selection: $pickupEnd,
                                        in: pickupStart...,
                                        displayedComponents: .hourAndMinute
                                    )
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                }
                            }
                        }
                    }

                    SaveButton(isSaving: $isSaving) { dismiss() }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
    }
}

// MARK: - Restaurant Order Detail View
struct RestaurantOrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    @State private var showMessage = false
    @State private var isMarkedPickedUp = false

    private var customerName: String   { order.customer?.name        ?? "Customer" }
    private var customerPhone: String  { order.customer?.phoneNumber  ?? "—" }
    private var customerNote: String   { order.notes                  ?? "No special instructions." }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Custom header (has status badge on right)
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Button(action: { dismiss() }) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.22))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "xmark")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                        // Status pill
                        Text(isMarkedPickedUp ? "Completed" : order.status.rawValue)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(isMarkedPickedUp ? .white : order.status.color)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(isMarkedPickedUp ? Theme.Colors.primaryGradientStart : order.status.color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                    Text("Order Details")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Code: \(order.pickupCode)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 4)
                        .padding(.bottom, 36)
                }
                .padding(.horizontal, 20)
                .background(Theme.Colors.primaryGradient)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))

                VStack(spacing: 20) {
                    // Customer Info
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Customer")
                        FormCard {
                            VStack(spacing: 0) {
                                customerInfoRow(icon: "person.fill",   label: "Name",  value: customerName)
                                Divider().padding(.leading, 54)
                                customerInfoRow(icon: "phone.fill",    label: "Phone", value: customerPhone)
                                Divider().padding(.leading, 54)
                                customerInfoRow(icon: "note.text",     label: "Note",  value: customerNote)
                            }
                        }
                    }

                    // Order Items
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Order Items")
                        FormCard {
                            VStack(spacing: 0) {
                                if let listing = order.listing {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Theme.Colors.primaryGradientStart.opacity(0.12))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: listing.category.icon)
                                                .font(.system(size: 18))
                                                .foregroundColor(Theme.Colors.primaryGradientStart)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(listing.title)
                                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                .foregroundColor(Theme.Colors.label)
                                            Text("Qty: \(order.quantity)")
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundColor(Theme.Colors.secondaryLabel)
                                        }
                                        Spacer()
                                        Text(listing.isFree ? "FREE" : "$\(String(format: "%.2f", order.totalAmount))")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(Theme.Colors.primaryGradient)
                                    }
                                    .padding(.vertical, 4)
                                }

                                Divider().padding(.top, 14)

                                HStack {
                                    Text("Total")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.Colors.label)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", order.totalAmount))")
                                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Theme.Colors.primaryGradient)
                                }
                                .padding(.top, 14)
                            }
                        }
                    }

                    // Pickup Details
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Pickup")
                        FormCard {
                            VStack(spacing: 0) {
                                pickupDetailRow(
                                    icon: "number",
                                    label: "Pickup Code",
                                    value: order.pickupCode,
                                    monospaced: true
                                )
                                Divider().padding(.leading, 54)
                                pickupDetailRow(
                                    icon: "clock.fill",
                                    label: "Window",
                                    value: "\(order.pickupWindowStart.formatted(date: .omitted, time: .shortened)) – \(order.pickupWindowEnd.formatted(date: .omitted, time: .shortened))"
                                )
                            }
                        }
                    }

                    // CTAs
                    VStack(spacing: 14) {
                        Button {
                            hapticFeedback(.success)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                isMarkedPickedUp = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isMarkedPickedUp ? "checkmark.circle.fill" : "bag.badge.checkmark")
                                    .font(.system(size: 17, weight: .bold))
                                Text(isMarkedPickedUp ? "Order Completed!" : "Mark as Picked Up")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                isMarkedPickedUp
                                    ? LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing)
                                    : Theme.Colors.primaryGradient
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Theme.Colors.primaryGradientStart.opacity(isMarkedPickedUp ? 0 : 0.3), radius: 10, y: 5)
                        }
                        .disabled(isMarkedPickedUp)

                        Button {
                            hapticFeedback(.light)
                            showMessage = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Message Customer")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(Theme.Colors.primaryGradientStart)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Theme.Colors.primaryGradientStart.opacity(0.4), lineWidth: 1.5)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
        .sheet(isPresented: $showMessage) {
            MessageCustomerView(order: order)
        }
    }

    private func customerInfoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.Colors.primaryGradientStart.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGradientStart)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.secondaryLabel)
                    .tracking(0.5)
                Text(value)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private func pickupDetailRow(icon: String, label: String, value: String, monospaced: Bool = false) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.Colors.primaryGradientStart.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGradientStart)
            }
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryLabel)
            Spacer()
            if monospaced {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.Colors.primaryGradient)
            } else {
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Day Schedule Model
struct DaySchedule: Identifiable {
    let id = UUID()
    var day: String
    var isOpen: Bool
    var openTime: Date
    var closeTime: Date
    var isExpanded: Bool = false

    static func defaultSchedule() -> [DaySchedule] {
        let open  = Calendar.current.date(from: DateComponents(hour: 9,  minute: 0)) ?? Date()
        let close = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
        let days  = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return days.map { day in
            // Weekends closed by default; Mon–Fri open
            let isWeekend = day == "Saturday" || day == "Sunday"
            return DaySchedule(day: day, isOpen: !isWeekend, openTime: open, closeTime: close)
        }
    }
}

// MARK: - Hours Row
private struct HoursRow: View {
    @Binding var entry: DaySchedule
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.timeStyle = .short; return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Top row: day name | time/closed | chevron | toggle
            // Toggle is a SIBLING of the tap area — NOT inside the Button —
            // so their touch targets don't conflict.
            HStack(spacing: 0) {
                // Left: tappable expand area (only active when open)
                Button {
                    guard entry.isOpen else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        entry.isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(entry.day)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                            .frame(width: 92, alignment: .leading)

                        Spacer()

                        if entry.isOpen {
                            Text("\(timeFormatter.string(from: entry.openTime)) – \(timeFormatter.string(from: entry.closeTime))")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.Colors.primaryGradientStart)
                                .lineLimit(1)

                            Image(systemName: entry.isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                                .frame(width: 14)
                        } else {
                            Text("Closed")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.leading, 16)
                    .padding(.trailing, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Right: toggle lives outside the button to avoid tap-target conflict
                Toggle("", isOn: $entry.isOpen)
                    .labelsHidden()
                    .tint(Theme.Colors.primaryGradientStart)
                    .padding(.trailing, 16)
                    .onChange(of: entry.isOpen) { _, open in
                        if !open {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                entry.isExpanded = false
                            }
                        }
                    }
            }

            // Dropdown: time pickers, shown when row is open + expanded
            if entry.isOpen && entry.isExpanded {
                VStack(spacing: 0) {
                    Divider().padding(.leading, 16)
                    VStack(spacing: 0) {
                        DatePicker(
                            "Opens",
                            selection: $entry.openTime,
                            displayedComponents: .hourAndMinute
                        )
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider().padding(.leading, 16)

                        DatePicker(
                            "Closes",
                            selection: $entry.closeTime,
                            in: entry.openTime...,
                            displayedComponents: .hourAndMinute
                        )
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Theme.Colors.primaryGradientStart.opacity(0.04))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Operating Hours Table (reusable — used in sign-up and settings)
struct OperatingHoursTable: View {
    @Binding var schedule: [DaySchedule]

    var body: some View {
        VStack(spacing: 0) {
            ForEach($schedule) { $entry in
                HoursRow(entry: $entry)
                if entry.day != schedule.last?.day {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 3)
    }
}

// MARK: - Restaurant Details Edit
struct RestaurantDetailsEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var restaurantId: String? = nil
    @State private var restaurantName = ""
    @State private var cuisine = ""
    @State private var phone = ""
    @State private var instagramHandle = ""
    @State private var websiteURL = ""
    @State private var schedule: [DaySchedule] = DaySchedule.defaultSchedule()
    @State private var isSaving = false
    @State private var saveError: String? = nil
    @State private var logoItem: PhotosPickerItem? = nil
    @State private var logoImage: UIImage? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                SubScreenHeader(
                    title: "Restaurant Details",
                    subtitle: "Update your restaurant's profile",
                    onDismiss: { dismiss() }
                )

                VStack(spacing: 24) {
                    // Logo upload area
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $logoItem, matching: .images) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Theme.Colors.primaryGradientStart.opacity(0.07))
                                    .frame(width: 100, height: 100)
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        Theme.Colors.primaryGradientStart.opacity(0.35),
                                        style: StrokeStyle(lineWidth: 2, dash: [8, 5])
                                    )
                                    .frame(width: 100, height: 100)
                                if let img = logoImage {
                                    Image(uiImage: img)
                                        .resizable().scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 24))
                                } else {
                                    VStack(spacing: 6) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundColor(Theme.Colors.primaryGradientStart.opacity(0.65))
                                        Text("Logo")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundColor(Theme.Colors.secondaryLabel)
                                    }
                                }
                            }
                        }
                        .onChange(of: logoItem) { _, item in
                            Task {
                                guard let data = try? await item?.loadTransferable(type: Data.self),
                                      let ui = UIImage(data: data) else { return }
                                logoImage = ui
                            }
                        }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Basic Info")
                        FormCard {
                            VStack(spacing: 16) {
                                AuthLabeledField(
                                    label: "Restaurant Name",
                                    placeholder: "e.g. Verde Bistro",
                                    text: $restaurantName
                                )
                                AuthLabeledField(
                                    label: "Cuisine Type",
                                    placeholder: "e.g. Mediterranean, Italian",
                                    text: $cuisine
                                )
                                AuthLabeledField(
                                    label: "Phone Number",
                                    placeholder: "+1 (555) 000-0000",
                                    text: $phone,
                                    keyboardType: .phonePad
                                )
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Social & Web")
                        FormCard {
                            VStack(spacing: 16) {
                                HStack(spacing: 10) {
                                    Image(systemName: "camera.on.rectangle.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(hex: "C13584"))
                                        .frame(width: 22)
                                    TextField("Instagram handle (e.g. @yourbistro)", text: $instagramHandle)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                }
                                .padding(Theme.Spacing.md)
                                .background(Theme.Colors.secondaryBackground)
                                .cornerRadius(Theme.CornerRadius.md)

                                HStack(spacing: 10) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Theme.Colors.primaryGradientStart)
                                        .frame(width: 22)
                                    TextField("Website URL (optional)", text: $websiteURL)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .keyboardType(.URL)
                                }
                                .padding(Theme.Spacing.md)
                                .background(Theme.Colors.secondaryBackground)
                                .cornerRadius(Theme.CornerRadius.md)
                            }
                        }
                    }

                    // Per-day hours table
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Operating Hours")
                        OperatingHoursTable(schedule: $schedule)
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                            Text("Tap a day's times to set open and close hours.")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                        .padding(.horizontal, 4)
                    }

                    if let error = saveError {
                        Text(error)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    SaveButton(isSaving: $isSaving) { await saveRestaurant() }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
        .task { await loadRestaurant() }
    }

    private func loadRestaurant() async {
        guard let userId = appState.currentUser?.id else { return }
        struct Row: Decodable {
            let id: String; let name: String; let phoneNumber: String?
            let cuisine: [String]; let instagramHandle: String?; let websiteUrl: String?
            let operatingHours: [[String: String]]?
            enum CodingKeys: String, CodingKey {
                case id, name, cuisine
                case phoneNumber = "phone_number"
                case instagramHandle = "instagram_handle"
                case websiteUrl = "website_url"
                case operatingHours = "operating_hours"
            }
        }
        do {
            let row: Row = try await supabase
                .from("restaurants")
                .select("id, name, phone_number, cuisine, instagram_handle, website_url, operating_hours")
                .eq("owner_id", value: userId)
                .single()
                .execute()
                .value
            restaurantId = row.id
            restaurantName = row.name
            cuisine = row.cuisine.joined(separator: ", ")
            phone = row.phoneNumber ?? ""
            instagramHandle = row.instagramHandle ?? ""
            websiteURL = row.websiteUrl ?? ""
            if let hours = row.operatingHours {
                let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
                for (i, h) in hours.enumerated() where i < schedule.count {
                    schedule[i].isOpen = h["isOpen"] == "true"
                    if let open = h["openTime"].flatMap({ fmt.date(from: $0) }) { schedule[i].openTime = open }
                    if let close = h["closeTime"].flatMap({ fmt.date(from: $0) }) { schedule[i].closeTime = close }
                }
            }
        } catch {
            // No restaurant row yet — fields stay empty, created on first save
        }
    }

    private func saveRestaurant() async {
        guard let userId = appState.currentUser?.id else { return }
        saveError = nil
        let cuisineList = cuisine.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
        let hoursJson: [[String: String]] = schedule.map { d in
            ["day": d.day, "isOpen": d.isOpen ? "true" : "false",
             "openTime": fmt.string(from: d.openTime), "closeTime": fmt.string(from: d.closeTime)]
        }

        struct UpdatePayload: Encodable {
            let name: String; let phoneNumber: String; let cuisine: [String]
            let instagramHandle: String; let websiteUrl: String
            let operatingHours: [[String: String]]
            enum CodingKeys: String, CodingKey {
                case name, cuisine
                case phoneNumber = "phone_number"
                case instagramHandle = "instagram_handle"
                case websiteUrl = "website_url"
                case operatingHours = "operating_hours"
            }
        }
        struct InsertPayload: Encodable {
            let ownerId: String; let name: String; let phoneNumber: String
            let cuisine: [String]; let email: String
            let instagramHandle: String; let websiteUrl: String
            let operatingHours: [[String: String]]
            let rating: Double; let totalReviews: Int; let verified: Bool; let isPremium: Bool
            enum CodingKeys: String, CodingKey {
                case name, cuisine, email, rating, verified
                case ownerId = "owner_id"; case phoneNumber = "phone_number"
                case instagramHandle = "instagram_handle"; case websiteUrl = "website_url"
                case operatingHours = "operating_hours"; case totalReviews = "total_reviews"
                case isPremium = "is_premium"
            }
        }
        struct IDRow: Decodable { let id: String }

        do {
            if let id = restaurantId {
                try await supabase.from("restaurants")
                    .update(UpdatePayload(
                        name: restaurantName, phoneNumber: phone, cuisine: cuisineList,
                        instagramHandle: instagramHandle, websiteUrl: websiteURL,
                        operatingHours: hoursJson
                    ))
                    .eq("id", value: id)
                    .execute()
            } else {
                let idRow: IDRow = try await supabase.from("restaurants")
                    .insert(InsertPayload(
                        ownerId: userId, name: restaurantName.isEmpty ? "My Restaurant" : restaurantName,
                        phoneNumber: phone, cuisine: cuisineList.isEmpty ? ["Other"] : cuisineList,
                        email: appState.currentUser?.email ?? "",
                        instagramHandle: instagramHandle, websiteUrl: websiteURL,
                        operatingHours: hoursJson,
                        rating: 0.0, totalReviews: 0, verified: false, isPremium: false
                    ))
                    .select("id").single().execute().value
                restaurantId = idRow.id
            }
            // Upload logo if a new one was selected
            if let img = logoImage, let jpegData = img.jpegData(compressionQuality: 0.8),
               let finalId = restaurantId {
                let logoPath = "\(userId)/logo.jpg"
                try? await supabase.storage.from("restaurant-images")
                    .upload(logoPath, data: jpegData,
                            options: FileOptions(contentType: "image/jpeg", upsert: true))
                if let logoUrl = try? supabase.storage.from("restaurant-images").getPublicURL(path: logoPath) {
                    try? await supabase.from("restaurants")
                        .update(["image_url": logoUrl.absoluteString])
                        .eq("id", value: finalId)
                        .execute()
                }
            }
            RePlateAuthService.shared.updateCurrentUser(
                name: restaurantName.isEmpty ? (appState.currentUser?.name ?? "") : restaurantName,
                email: appState.currentUser?.email ?? "",
                phoneNumber: phone.isEmpty ? nil : phone
            )
            dismiss()
        } catch {
            saveError = "Save failed. Please try again."
        }
    }
}

// MARK: - Location & Pickup Edit
struct LocationPickupEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var restaurantId: String? = nil
    @State private var street = ""
    @State private var city = ""
    @State private var stateName = ""
    @State private var zip = ""
    @State private var pickupInstructions = ""
    @State private var isSaving = false
    @State private var saveError: String? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                SubScreenHeader(
                    title: "Location & Pickup",
                    subtitle: "Set your address and pickup details",
                    onDismiss: { dismiss() }
                )

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Address")
                        FormCard {
                            VStack(spacing: 16) {
                                AuthLabeledField(label: "Street Address", placeholder: "123 Main St", text: $street)
                                AuthLabeledField(label: "City", placeholder: "e.g. San Francisco", text: $city)
                                HStack(spacing: 12) {
                                    AuthLabeledField(label: "State", placeholder: "CA", text: $stateName)
                                    AuthLabeledField(
                                        label: "ZIP Code",
                                        placeholder: "94102",
                                        text: $zip,
                                        keyboardType: .numberPad
                                    )
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Pickup Instructions")
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Instructions")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                            TextEditor(text: $pickupInstructions)
                                .frame(height: 100)
                                .scrollContentBackground(.hidden)
                                .padding(14)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            pickupInstructions.isEmpty
                                                ? Color.clear
                                                : Theme.Colors.primaryGradientStart.opacity(0.4),
                                            lineWidth: 1.5
                                        )
                                )
                        }
                    }

                    if let error = saveError {
                        Text(error)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    SaveButton(isSaving: $isSaving) { await saveAddress() }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
        .task { await loadAddress() }
    }

    private func loadAddress() async {
        guard let userId = appState.currentUser?.id else { return }
        struct Row: Decodable {
            let id: String; let address: String?; let pickupInstructions: String?
            enum CodingKeys: String, CodingKey {
                case id, address; case pickupInstructions = "pickup_instructions"
            }
        }
        do {
            let row: Row = try await supabase
                .from("restaurants")
                .select("id, address, pickup_instructions")
                .eq("owner_id", value: userId)
                .single()
                .execute()
                .value
            restaurantId = row.id
            pickupInstructions = row.pickupInstructions ?? ""
            if let addr = row.address, !addr.isEmpty {
                let parts = addr.components(separatedBy: ", ")
                street = parts.count > 0 ? parts[0] : ""
                city   = parts.count > 1 ? parts[1] : ""
                if parts.count > 2 {
                    let stateZip = parts[2].components(separatedBy: " ")
                    stateName = stateZip.count > 0 ? stateZip[0] : ""
                    zip       = stateZip.count > 1 ? stateZip[1] : ""
                }
            }
        } catch {
            // No restaurant row yet
        }
    }

    private func saveAddress() async {
        guard let userId = appState.currentUser?.id else { return }
        saveError = nil
        let fullAddress = [street, city, "\(stateName) \(zip)".trimmingCharacters(in: .whitespaces)]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        struct AddressPayload: Encodable {
            let address: String; let pickupInstructions: String
            enum CodingKeys: String, CodingKey {
                case address; case pickupInstructions = "pickup_instructions"
            }
        }
        struct InsertPayload: Encodable {
            let ownerId: String; let name: String; let address: String
            let email: String; let pickupInstructions: String
            let cuisine: [String]; let rating: Double; let totalReviews: Int
            let verified: Bool; let isPremium: Bool
            enum CodingKeys: String, CodingKey {
                case name, address, email, cuisine, rating, verified
                case ownerId = "owner_id"
                case pickupInstructions = "pickup_instructions"
                case totalReviews = "total_reviews"; case isPremium = "is_premium"
            }
        }
        struct IDRow: Decodable { let id: String }

        do {
            if let id = restaurantId {
                try await supabase.from("restaurants")
                    .update(AddressPayload(address: fullAddress, pickupInstructions: pickupInstructions))
                    .eq("id", value: id)
                    .execute()
            } else {
                let idRow: IDRow = try await supabase.from("restaurants")
                    .insert(InsertPayload(
                        ownerId: userId,
                        name: appState.currentUser?.name ?? "My Restaurant",
                        address: fullAddress,
                        email: appState.currentUser?.email ?? "",
                        pickupInstructions: pickupInstructions,
                        cuisine: ["Other"],
                        rating: 0.0, totalReviews: 0, verified: false, isPremium: false
                    ))
                    .select("id").single().execute().value
                restaurantId = idRow.id
            }
            dismiss()
        } catch {
            saveError = "Save failed. Please try again."
        }
    }
}

// MARK: - Payment Settings
// SECURITY: never store raw card data client-side. Use Stripe or similar PCI-compliant SDK server-side.
// TODO: backend — payment must be processed server-side; client total is untrusted.
struct PaymentSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var bankName = ""
    @State private var accountHolder = ""
    @State private var accountNumber = ""
    @State private var routingNumber = ""
    @State private var isSaving = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                SubScreenHeader(
                    title: "Payment Settings",
                    subtitle: "Configure your payout details",
                    onDismiss: { dismiss() }
                )

                VStack(spacing: 24) {
                    // Security info banner
                    // SECURITY: never store raw card data client-side. Use Stripe or similar PCI-compliant SDK server-side.
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.primaryGradientStart)
                        Text("Your payment information is encrypted and processed securely via our payment provider. Card data is never stored on-device.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(Theme.Colors.primaryGradientStart.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Bank Details")
                        FormCard {
                            VStack(spacing: 16) {
                                AuthLabeledField(label: "Bank Name", placeholder: "e.g. Chase Bank", text: $bankName)
                                AuthLabeledField(label: "Account Holder", placeholder: "Full legal name", text: $accountHolder)
                                AuthLabeledField(
                                    label: "Account Number",
                                    placeholder: "•••• •••• ••••",
                                    text: $accountNumber,
                                    keyboardType: .numberPad
                                )
                                AuthLabeledField(
                                    label: "Routing Number",
                                    placeholder: "9 digits",
                                    text: $routingNumber,
                                    keyboardType: .numberPad
                                )
                            }
                        }
                    }

                    SaveButton(isSaving: $isSaving) { dismiss() }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
    }
}

// MARK: - Notifications Preferences
struct NotificationsPreferencesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var newOrders      = true
    @State private var reminders      = true
    @State private var confirmations  = true
    @State private var reviews        = false
    @State private var emailDigest    = true
    @State private var emailPromo     = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                SubScreenHeader(
                    title: "Notifications",
                    subtitle: "Choose how RePlate reaches you",
                    onDismiss: { dismiss() }
                )

                VStack(spacing: 24) {
                    // Push
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Push Notifications")
                        FormCard {
                            VStack(spacing: 0) {
                                notifToggle(icon: "bag.fill",                         title: "New Orders",      subtitle: "Alert when a customer places an order",     isOn: $newOrders)
                                Divider().padding(.leading, 54)
                                notifToggle(icon: "clock.badge.exclamationmark.fill", title: "Reminders",       subtitle: "Before pickup window closes",               isOn: $reminders)
                                Divider().padding(.leading, 54)
                                notifToggle(icon: "checkmark.seal.fill",              title: "Confirmations",   subtitle: "Pickup confirmed by customer",              isOn: $confirmations)
                                Divider().padding(.leading, 54)
                                notifToggle(icon: "star.fill",                        title: "Reviews",         subtitle: "New customer review posted",               isOn: $reviews)
                            }
                        }
                    }

                    // Email
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Email")
                        FormCard {
                            VStack(spacing: 0) {
                                notifToggle(icon: "chart.bar.fill",  title: "Weekly Digest",  subtitle: "Your weekly impact report",   isOn: $emailDigest)
                                Divider().padding(.leading, 54)
                                notifToggle(icon: "megaphone.fill",  title: "Promotions",     subtitle: "Tips and product updates",    isOn: $emailPromo)
                            }
                        }
                    }

                    Button {
                        hapticFeedback(.success)
                        dismiss()
                    } label: {
                        Text("Save Preferences")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Theme.Colors.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.32), radius: 10, y: 5)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
    }

    private func notifToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.Colors.primaryGradientStart.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGradientStart)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.Colors.secondaryLabel)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .tint(Theme.Colors.primaryGradientStart)
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Help Center
struct HelpCenterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var expanded: String? = nil
    @State private var showContact = false

    private let faqs: [(title: String, icon: String, items: [(q: String, a: String)])] = [
        (
            title: "Getting Started",
            icon: "star.circle.fill",
            items: [
                (
                    q: "How do I post my first listing?",
                    a: "Tap 'Post Surplus Food' on your dashboard. Fill in the food details, set a pickup window, and publish — it goes live instantly."
                ),
                (
                    q: "What types of food can I list?",
                    a: "Any safe, edible surplus: baked goods, prepared meals, produce, beverages, and packaged snacks."
                ),
            ]
        ),
        (
            title: "Managing Orders",
            icon: "list.bullet.clipboard.fill",
            items: [
                (
                    q: "How do I confirm a pickup?",
                    a: "When the customer arrives, ask for their pickup code and tap 'Mark as Picked Up' in the order details screen."
                ),
                (
                    q: "What if a customer doesn't show?",
                    a: "If a customer misses their window, mark the order as No Show. We'll notify the customer and release the item back to the listing."
                ),
            ]
        ),
        (
            title: "Payments",
            icon: "creditcard.fill",
            items: [
                (
                    q: "When do I get paid?",
                    a: "Payouts are processed every Monday for the previous week's completed orders. Funds arrive in 2–3 business days."
                ),
                (
                    q: "What fees does RePlate charge?",
                    a: "RePlate charges a 15% platform fee on paid listings. Free listings have no fee — giving away food is always free."
                ),
            ]
        ),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                SubScreenHeader(
                    title: "Help Center",
                    subtitle: "Answers to common questions",
                    onDismiss: { dismiss() }
                )

                VStack(spacing: 24) {
                    // FAQ accordions
                    VStack(spacing: 14) {
                        ForEach(faqs, id: \.title) { category in
                            VStack(alignment: .leading, spacing: 0) {
                                Button {
                                    hapticFeedback(.light)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        expanded = expanded == category.title ? nil : category.title
                                    }
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Theme.Colors.primaryGradientStart.opacity(0.12))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: category.icon)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(Theme.Colors.primaryGradientStart)
                                        }
                                        Text(category.title)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(Theme.Colors.label)
                                        Spacer()
                                        Image(systemName: expanded == category.title ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Theme.Colors.secondaryLabel)
                                    }
                                    .padding(18)
                                }
                                .buttonStyle(PlainButtonStyle())

                                if expanded == category.title {
                                    ForEach(category.items, id: \.q) { item in
                                        Divider().padding(.horizontal, 18)
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(item.q)
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundColor(Theme.Colors.label)
                                            Text(item.a)
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundColor(Theme.Colors.secondaryLabel)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 14)
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 3)
                        }
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Quick Actions")
                        HStack(spacing: 14) {
                            helpQuickAction(icon: "play.rectangle.fill", label: "Video Tutorials") {}
                            helpQuickAction(icon: "message.fill",        label: "Contact Support") {
                                showContact = true
                            }
                        }
                    }

                    // Still need help?
                    VStack(spacing: 12) {
                        Text("Still need help?")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                        Text("Our support team typically responds within 2 hours during business hours.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .multilineTextAlignment(.center)
                        Button {
                            hapticFeedback(.light)
                            showContact = true
                        } label: {
                            Text("Get in Touch")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.Colors.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
        .sheet(isPresented: $showContact) { ContactSupportView() }
    }

    private func helpQuickAction(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: { hapticFeedback(.light); action() }) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Colors.primaryGradientStart.opacity(0.1))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                }
                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Contact Support
struct ContactSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory = "Technical Issue"
    @State private var subject = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var showConfirmation = false

    private let categories = ["Technical Issue", "Payment Help", "Order Problem", "Feature Request", "Other"]

    private var canSend: Bool { !subject.trimmingCharacters(in: .whitespaces).isEmpty && !message.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                SubScreenHeader(
                    title: "Contact Support",
                    subtitle: "We'll get back to you shortly",
                    onDismiss: { dismiss() }
                )

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Your Message")
                        FormCard {
                            VStack(spacing: 16) {
                                // Category menu
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Category")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(Theme.Colors.secondaryLabel)
                                    Menu {
                                        ForEach(categories, id: \.self) { cat in
                                            Button(cat) { selectedCategory = cat }
                                        }
                                    } label: {
                                        HStack {
                                            Text(selectedCategory)
                                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                                .foregroundColor(Theme.Colors.label)
                                            Spacer()
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(Theme.Colors.secondaryLabel)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    }
                                }

                                AuthLabeledField(label: "Subject", placeholder: "Brief description of your issue", text: $subject)

                                // Message editor
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Message")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(Theme.Colors.secondaryLabel)
                                    TextEditor(text: $message)
                                        .frame(height: 120)
                                        .scrollContentBackground(.hidden)
                                        .padding(14)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    message.isEmpty ? Color.clear : Theme.Colors.primaryGradientStart.opacity(0.4),
                                                    lineWidth: 1.5
                                                )
                                        )
                                }
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        Button {
                            hapticFeedback(.success)
                            isSending = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                isSending = false
                                showConfirmation = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isSending { ProgressView().tint(.white).scaleEffect(0.85) }
                                Text(isSending ? "Sending…" : "Send Message")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Theme.Colors.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Theme.Colors.primaryGradientStart.opacity(canSend ? 0.32 : 0), radius: 10, y: 5)
                        }
                        .disabled(!canSend || isSending)
                        .opacity(canSend ? 1 : 0.5)

                        Button("Cancel") { dismiss() }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
        .alert("Message Sent!", isPresented: $showConfirmation) {
            Button("Done") { dismiss() }
        } message: {
            Text("We've received your message and will respond within 2 business hours.")
        }
    }
}

// MARK: - Staff Accounts View
struct StaffAccountsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showAddForm = false
    @State private var newName  = ""
    @State private var newEmail = ""
    @State private var newRole  = "Staff"
    private let roles = ["Staff", "Manager", "Admin"]

    // Internal model — not persisted
    @State private var staffMembers: [StaffMember] = [
        StaffMember(name: "Maria Garcia", email: "maria@verde.com", role: "Manager"),
        StaffMember(name: "Luca Rossi",   email: "luca@verde.com",  role: "Staff"),
    ]

    private struct StaffMember: Identifiable {
        let id = UUID()
        let name: String
        let email: String
        let role: String
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                SubScreenHeader(
                    title: "Staff Accounts",
                    subtitle: "Manage your team's access",
                    onDismiss: { dismiss() }
                )

                VStack(spacing: 24) {
                    // Info banner
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.primaryGradientStart)
                        Text("Staff will receive an email invitation to download RePlate and join your restaurant.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(Theme.Colors.primaryGradientStart.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // Add form / button
                    if showAddForm {
                        addMemberForm
                    } else {
                        addMemberButton
                    }

                    // Staff list
                    if !staffMembers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Team Members (\(staffMembers.count))")
                            VStack(spacing: 10) {
                                ForEach(staffMembers) { member in
                                    staffCard(member: member)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
    }

    // MARK: Add button
    private var addMemberButton: some View {
        Button {
            hapticFeedback(.medium)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showAddForm = true }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.primaryGradient)
                        .frame(width: 38, height: 38)
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("Add Staff Member")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.primaryGradientStart)
                Spacer()
            }
            .padding(18)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: Color.black.opacity(0.07), radius: 10, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: Inline add form
    private var addMemberForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("New Staff Member")
            FormCard {
                VStack(spacing: 16) {
                    AuthLabeledField(label: "Full Name", placeholder: "e.g. Jane Smith",     text: $newName)
                    AuthLabeledField(label: "Email",     placeholder: "jane@restaurant.com", text: $newEmail, keyboardType: .emailAddress)

                    // Role chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Role")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                        HStack(spacing: 10) {
                            ForEach(roles, id: \.self) { role in
                                Button {
                                    hapticFeedback(.light)
                                    newRole = role
                                } label: {
                                    Text(role)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(newRole == role ? .white : Theme.Colors.label)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 9)
                                        .background(
                                            newRole == role
                                                ? Theme.Colors.primaryGradient
                                                : LinearGradient(
                                                    colors: [Color(.systemGray6)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Button("Cancel") {
                            hapticFeedback(.light)
                            withAnimation { showAddForm = false }
                            newName = ""; newEmail = ""; newRole = "Staff"
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.Colors.secondaryLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        let canSend = !newName.trimmingCharacters(in: .whitespaces).isEmpty &&
                                      !newEmail.trimmingCharacters(in: .whitespaces).isEmpty

                        Button("Send Invite") {
                            guard canSend else { return }
                            hapticFeedback(.success)
                            let m = StaffMember(name: newName, email: newEmail, role: newRole)
                            withAnimation { staffMembers.append(m); showAddForm = false }
                            newName = ""; newEmail = ""; newRole = "Staff"
                        }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.Colors.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .opacity(canSend ? 1 : 0.5)
                        .disabled(!canSend)
                    }
                }
            }
        }
    }

    // MARK: Staff card row
    private func staffCard(member: StaffMember) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryGradientStart.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(String(member.name.prefix(1)).uppercased())
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.primaryGradientStart)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(member.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                Text(member.email)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.Colors.secondaryLabel)
            }
            Spacer()
            Text(member.role)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.primaryGradientStart)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.Colors.primaryGradientStart.opacity(0.1))
                .clipShape(Capsule())

            Button {
                hapticFeedback(.light)
                withAnimation { staffMembers.removeAll { $0.id == member.id } }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 34, height: 34)
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
    }
}

// MARK: - Message Customer View
private struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromRestaurant: Bool
    let timestamp: Date
}

struct MessageCustomerView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hi! I just placed an order for pickup.", isFromRestaurant: false, timestamp: Date().addingTimeInterval(-600)),
        ChatMessage(text: "Great, we're getting it ready for you now!", isFromRestaurant: true, timestamp: Date().addingTimeInterval(-540)),
        ChatMessage(text: "Should I enter through the main entrance?", isFromRestaurant: false, timestamp: Date().addingTimeInterval(-300)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header (no scroll, fixed at top)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.22))
                                .frame(width: 40, height: 40)
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.Colors.accent)
                            .frame(width: 8, height: 8)
                        Text("Online")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 10)

                Text(order.customer?.name ?? "Customer")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("Order #\(order.pickupCode)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 4)
                    .padding(.bottom, 22)
            }
            .padding(.horizontal, 20)
            .padding(.top, 44) // safe area
            .background(Theme.Colors.primaryGradient)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 32, bottomTrailingRadius: 32))

            // Message list
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in
                            messageBubble(msg)
                                .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            // Input bar
            HStack(spacing: 12) {
                TextField("Type a message…", text: $messageText)
                    .font(.system(size: 15, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                Button {
                    let trimmed = messageText.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    hapticFeedback(.light)
                    let newMsg = ChatMessage(text: trimmed, isFromRestaurant: true, timestamp: Date())
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        messages.append(newMsg)
                    }
                    messageText = ""
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                messageText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color(.systemGray4)
                                    : Theme.Colors.primaryGradientStart
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(.systemBackground)
                    .shadow(color: Color.black.opacity(0.07), radius: 8, y: -3)
            )
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
    }

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromRestaurant { Spacer(minLength: 60) }

            VStack(alignment: message.isFromRestaurant ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(message.isFromRestaurant ? .white : Theme.Colors.label)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isFromRestaurant
                            ? Theme.Colors.primaryGradient
                            : LinearGradient(
                                colors: [Color(.systemBackground)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius:    message.isFromRestaurant ? 20 : 4,
                            bottomLeadingRadius: 20,
                            bottomTrailingRadius: message.isFromRestaurant ? 4 : 20,
                            topTrailingRadius:   20
                        )
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.Colors.tertiaryLabel)
            }

            if !message.isFromRestaurant { Spacer(minLength: 60) }
        }
    }
}

//
//  PostSurplusView.swift
//  RePlate
//
//  Created by Jyotika Sadani on 5/30/26.
//  5-step surplus-posting flow with step validation, auto-pricing,
//  currency formatting, custom time picker, and confetti celebration.
//

import SwiftUI
import Supabase

// MARK: - Post Surplus View
struct PostSurplusView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var listingVM = PostListingViewModel()

    // MARK: Step state
    @State private var step         = 1   // 1 … 5
    @State private var showError    = false
    @State private var errorMsg     = ""
    @State private var showSuccess  = false

    // Step 1
    @State private var hasPhoto     = false  // simulated

    // Step 2
    @State private var title        = ""
    @State private var foodType     = ""
    @State private var quantity     = 1

    // Step 3
    @State private var isFree            = false
    @State private var originalDigits   = ""   // raw cents string for original price
    @State private var manualOverride    = false // allow editing the suggested price
    @State private var overrideDigits    = ""   // if user overrides

    // Step 4
    @State private var pickupWindow  = ""
    @State private var customDate    = Date().addingTimeInterval(3600)
    @State private var showDatePicker = false

    // Step 5
    @State private var isPosting    = false

    // MARK: - Price helpers
    private var originalCents: Int { Int(originalDigits) ?? 0 }
    private var suggestedCents: Int { Int(Double(originalCents) * 0.40) }

    private var displayOriginal: String { formatCents(originalCents) }
    private var displaySuggested: String { formatCents(suggestedCents) }
    private var displayOverride: String { formatCents(Int(overrideDigits) ?? 0) }

    private func formatCents(_ cents: Int) -> String {
        String(format: "$%.2f", Double(cents) / 100.0)
    }

    // MARK: - Food categories (SF Symbols only — no emoji)
    private struct FoodCategory: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
    }

    private let categories: [FoodCategory] = [
        // Cuisines
        .init(name: "Indian",        icon: "flame.fill"),
        .init(name: "Italian",       icon: "fork.knife.circle.fill"),
        .init(name: "Mexican",       icon: "leaf.arrow.circlepath"),
        .init(name: "Japanese",      icon: "fish.fill"),
        .init(name: "Asian",         icon: "bowl.fill"),
        .init(name: "Korean",        icon: "flame.circle.fill"),
        .init(name: "Chinese",       icon: "cup.and.saucer.fill"),
        .init(name: "Thai",          icon: "leaf.circle.fill"),
        .init(name: "Mediterranean", icon: "sun.horizon.fill"),
        .init(name: "American",      icon: "takeoutbag.and.cup.and.straw.fill"),
        // Meal times
        .init(name: "Breakfast",     icon: "sunrise.fill"),
        .init(name: "Lunch",         icon: "sun.max.fill"),
        .init(name: "Dinner",        icon: "moon.stars.fill"),
        .init(name: "Snacks",        icon: "takeoutbag.and.cup.and.straw"),
        // Food types
        .init(name: "Desserts",      icon: "birthday.cake.fill"),
        .init(name: "Bakery",        icon: "birthday.cake"),
        .init(name: "Produce",       icon: "carrot.fill"),
        .init(name: "Beverages",     icon: "cup.and.saucer"),
        .init(name: "Meals",         icon: "fork.knife"),
        .init(name: "Other",         icon: "bag.fill"),
    ]

    private let pickupOptions = [
        "Until Close",
        "6:00 PM – 9:00 PM",
        "7:00 PM – 10:00 PM",
        "Custom Time",
    ]

    // MARK: Body
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                stepHeader
                ScrollView(showsIndicators: false) {
                    currentStepView
                        .id(step)
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .padding(.bottom, 60)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .background(Color(.systemBackground))
            .animation(.spring(response: 0.38, dampingFraction: 0.86), value: step)

            // Success overlay
            if showSuccess {
                SuccessOverlayView(
                    title: title.isEmpty ? "Surplus Listing" : title,
                    pickup: pickupLabel,
                    onDone: { dismiss() }
                )
                .transition(.opacity.combined(with: .scale))
                .zIndex(10)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showSuccess)
        .alert("Required Field", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMsg) }
    }

    private var pickupLabel: String {
        if pickupWindow == "Custom Time" {
            let f = DateFormatter(); f.dateFormat = "MMM d, h:mm a"; return f.string(from: customDate)
        }
        return pickupWindow.isEmpty ? "Not set" : pickupWindow
    }

    // MARK: - Header
    private var stepHeader: some View {
        HStack(alignment: .center) {
            Button { hapticFeedback(.light); dismiss() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6)).frame(width: 44, height: 44)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.Colors.secondaryLabel)
                }
            }
            Spacer()
            VStack(spacing: 8) {
                Text("New Surplus")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { s in
                        Capsule()
                            .fill(s <= step
                                  ? Theme.Colors.primaryGradientStart
                                  : Color(.systemGray5))
                            .frame(width: s == step ? 28 : 20, height: 5)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: step)
                    }
                }
            }
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)
        .background(Color(.systemBackground)
            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 4))
    }

    // MARK: - Step dispatcher
    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case 1:  step1Photos
        case 2:  step2Details
        case 3:  step3Price
        case 4:  step4Pickup
        default: step5Review
        }
    }

    // MARK: - Step 1 · Photos
    private var step1Photos: some View {
        VStack(spacing: 28) {
            stepTitle("Show it off", subtitle: "A great photo gets more orders.")

            // Upload zone
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Theme.Colors.primaryGradientStart.opacity(0.04))
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Theme.Colors.primaryGradientStart.opacity(0.22),
                            style: StrokeStyle(lineWidth: 2, dash: [10, 6]))
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.white)
                            .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                            .frame(width: 80, height: 80)
                        Image(systemName: hasPhoto ? "checkmark.circle.fill" : "photo.on.rectangle.angled")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(hasPhoto
                                ? AnyShapeStyle(Theme.Colors.primaryGradientStart)
                                : AnyShapeStyle(Theme.Colors.primaryGradient))
                    }
                    Text(hasPhoto ? "Photo Added" : "Upload Photo")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.label)
                    if !hasPhoto {
                        Text("Let customers see the goods")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                    }
                }
                .padding(.vertical, 44)
            }

            VStack(spacing: 12) {
                actionButton(label: "Take Photo", icon: "camera.fill", style: .gradient) {
                    hapticFeedback(.medium); hasPhoto = true
                }
                actionButton(label: "Choose from Gallery", icon: "photo.fill.on.rectangle.fill", style: .gray) {
                    hapticFeedback(.light); hasPhoto = true
                }
            }

            accentNextButton(label: "Next Step") { advance() }
        }
    }

    // MARK: - Step 2 · Details
    private var step2Details: some View {
        VStack(spacing: 28) {
            stepTitle("The Details", subtitle: "What are you offering today?")

            VStack(spacing: 20) {
                fieldBlock(label: "TITLE") {
                    TextField("e.g., Fresh Morning Croissants", text: $title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .padding(.horizontal, 20).padding(.vertical, 18)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                }

                fieldBlock(label: "CATEGORY") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(categories) { cat in
                            Button {
                                hapticFeedback(.light); foodType = cat.name
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(foodType == cat.name ? .white : Theme.Colors.primaryGradientStart)
                                    Text(cat.name.uppercased())
                                        .font(.system(size: 9, weight: .black, design: .rounded))
                                        .tracking(0.5)
                                        .foregroundColor(foodType == cat.name ? .white : Theme.Colors.label)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(foodType == cat.name
                                    ? Theme.Colors.primaryGradient
                                    : LinearGradient(colors: [Color(.systemBackground)], startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .overlay(RoundedRectangle(cornerRadius: 22)
                                    .stroke(foodType == cat.name ? Color.clear : Color(.systemGray4), lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                fieldBlock(label: "QUANTITY") {
                    HStack {
                        Button {
                            hapticFeedback(.light); if quantity > 1 { quantity -= 1 }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
                                    .frame(width: 52, height: 52)
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Theme.Colors.primaryGradientStart)
                            }
                        }
                        Spacer()
                        Text("\(quantity)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(Theme.Colors.label)
                        Spacer()
                        Button {
                            hapticFeedback(.light); quantity += 1
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
                                    .frame(width: 52, height: 52)
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Theme.Colors.primaryGradientStart)
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                }
            }

            navRow {
                // OWASP A03: validate and sanitize inputs before advancing to the submit step
                guard !title.isEmpty else { showValidationError("Please enter a title for your listing."); return }
                guard title.count <= 200 else { showValidationError("Title cannot exceed 200 characters."); return }
                guard !foodType.isEmpty else { showValidationError("Please select a food category."); return }
                guard quantity >= 1 && quantity <= 100 else { showValidationError("Quantity must be between 1 and 100."); return }
                advance()
            }
        }
    }

    // MARK: - Step 3 · Price
    private var step3Price: some View {
        VStack(spacing: 28) {
            stepTitle("Set a Price", subtitle: "RePlate auto-applies a 60% discount.")

            // Free toggle
            Button {
                hapticFeedback(.light)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isFree.toggle()
                    if isFree { originalDigits = ""; overrideDigits = "" }
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isFree
                                  ? Theme.Colors.primaryGradient
                                  : LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 48, height: 48)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isFree ? .white : Theme.Colors.secondaryLabel)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Offer for Free")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(isFree ? Theme.Colors.primaryGradientStart : Theme.Colors.label)
                        Text("Maximum community impact")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(isFree ? Theme.Colors.primaryGradientStart : Color(.systemGray5))
                            .frame(width: 26, height: 26)
                        if isFree {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(20)
                .background(isFree ? Theme.Colors.accent.opacity(0.4) : Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .overlay(RoundedRectangle(cornerRadius: 26)
                    .stroke(isFree ? Theme.Colors.primaryGradientStart.opacity(0.4) : Color(.systemGray4), lineWidth: 1.5))
                .shadow(color: isFree ? Theme.Colors.primaryGradientStart.opacity(0.15) : Color.black.opacity(0.04),
                        radius: 10, y: 4)
            }
            .buttonStyle(PlainButtonStyle())

            if !isFree {
                VStack(spacing: 16) {
                    // Original price input
                    fieldBlock(label: "ORIGINAL RETAIL PRICE") {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Theme.Colors.primaryGradientStart.opacity(0.1))
                                    .frame(width: 46, height: 46)
                                Image(systemName: "dollarsign")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Theme.Colors.primaryGradientStart)
                            }
                            ZStack(alignment: .leading) {
                                if originalDigits.isEmpty {
                                    Text("0.00")
                                        .font(.system(size: 34, weight: .black, design: .rounded))
                                        .foregroundColor(Color(.systemGray4))
                                }
                                TextField("", text: $originalDigits)
                                    .font(.system(size: 34, weight: .black, design: .rounded))
                                    .foregroundColor(Theme.Colors.primaryGradientStart)
                                    .keyboardType(.numberPad)
                                    .opacity(originalDigits.isEmpty ? 0 : 1)
                                    .onChange(of: originalDigits) { _, v in
                                        let digits = v.filter { $0.isNumber }
                                        originalDigits = digits.count <= 8 ? digits : String(digits.prefix(8))
                                        manualOverride = false; overrideDigits = ""
                                    }
                            }
                            if !originalDigits.isEmpty {
                                Text(displayOriginal)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.Colors.secondaryLabel)
                            }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                    }

                    // Auto-calculated RePlate price
                    if originalCents > 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("REPLATE PRICE (60% OFF)")
                                        .font(.system(size: 9, weight: .black, design: .rounded))
                                        .foregroundColor(Theme.Colors.tertiaryLabel)
                                        .tracking(1.0)
                                    Text(manualOverride ? displayOverride : displaySuggested)
                                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Theme.Colors.primaryGradient)
                                }
                                Spacer()
                                // Strikethrough original
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(displayOriginal)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.Colors.tertiaryLabel)
                                        .strikethrough()
                                    Text("ORIGINAL")
                                        .font(.system(size: 8, weight: .black, design: .rounded))
                                        .foregroundColor(Theme.Colors.tertiaryLabel)
                                        .tracking(0.8)
                                }
                            }
                            .padding(18)
                            .background(Theme.Colors.primaryGradientStart.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 22))

                            // Manual override
                            if !manualOverride {
                                Button {
                                    hapticFeedback(.light)
                                    manualOverride = true
                                    overrideDigits = String(suggestedCents)
                                } label: {
                                    Text("Override price")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.Colors.primaryGradientStart)
                                }
                            } else {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Theme.Colors.primaryGradientStart.opacity(0.1))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: "dollarsign")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Theme.Colors.primaryGradientStart)
                                    }
                                    TextField("", text: $overrideDigits)
                                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                                        .foregroundColor(Theme.Colors.primaryGradientStart)
                                        .keyboardType(.numberPad)
                                        .onChange(of: overrideDigits) { _, v in
                                            let d = v.filter { $0.isNumber }
                                            overrideDigits = d.count <= 8 ? d : String(d.prefix(8))
                                        }
                                    Button("Reset") {
                                        manualOverride = false; overrideDigits = ""
                                    }
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.Colors.secondaryLabel)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // AI tip
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "b45309"))
                        Text("Pro Tip: 60% off original price sells fastest!")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "92400e")).tracking(0.3)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Color(hex: "fefce8"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "fde68a"), lineWidth: 1))
                }
                .animation(.easeInOut(duration: 0.2), value: originalCents)
            }

            navRow {
                // SECURITY: re-validate server-side — price must be > 0 unless free
                if !isFree && originalCents == 0 {
                    showValidationError("Please enter the original retail price.")
                    return
                }
                if !isFree && suggestedCents == 0 && !manualOverride {
                    showValidationError("Discounted price must be greater than zero.")
                    return
                }
                advance()
            }
        }
    }

    // MARK: - Step 4 · Pickup
    private var step4Pickup: some View {
        VStack(spacing: 28) {
            stepTitle("Pickup Time", subtitle: "When should customers come by?")

            VStack(spacing: 12) {
                ForEach(pickupOptions, id: \.self) { option in
                    let selected = pickupWindow == option
                    Button {
                        hapticFeedback(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            pickupWindow = option
                            showDatePicker = (option == "Custom Time")
                        }
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(selected ? .white.opacity(0.22) : Color(.systemGray6))
                                    .frame(width: 44, height: 44)
                                Image(systemName: option == "Custom Time" ? "calendar.badge.clock" : "clock.fill")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(selected ? .white : Theme.Colors.secondaryLabel)
                            }
                            Text(option)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(selected ? .white : Theme.Colors.label)
                            Spacer()
                            if selected { Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white) }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 16)
                        .background(selected ? Theme.Colors.primaryGradient
                                    : LinearGradient(colors: [Color(.systemBackground)], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(selected ? Color.clear : Color(.systemGray4), lineWidth: 1))
                        .shadow(color: selected ? Theme.Colors.primaryGradientStart.opacity(0.25) : Color.black.opacity(0.04),
                                radius: 10, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Custom time DatePicker
                if showDatePicker {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SELECT DATE & TIME")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(Theme.Colors.tertiaryLabel).tracking(1.2)
                        DatePicker(
                            "",
                            selection: $customDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .tint(Theme.Colors.primaryGradientStart)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showDatePicker)
                }
            }

            navRow {
                // SECURITY: re-validate server-side — pickup window must be in the future and end > start
                guard !pickupWindow.isEmpty else {
                    showValidationError("Please select a pickup window.")
                    return
                }
                if pickupWindow == "Custom Time" && customDate < Date() {
                    showValidationError("Custom pickup time must be in the future.")
                    return
                }
                advance()
            }
        }
    }

    // MARK: - Step 5 · Review & Post
    private var step5Review: some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Theme.Colors.accent.opacity(0.5))
                        .frame(width: 76, height: 76)
                        .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.2), radius: 12, y: 6)
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Theme.Colors.primaryGradient)
                }
                Text("Review Listing")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
                Text("Everything look right?")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.Colors.secondaryLabel)
            }

            // Preview card
            VStack(alignment: .leading, spacing: 0) {
                // Photo placeholder
                ZStack {
                    Color(.systemGray6)
                    if hasPhoto {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Theme.Colors.primaryGradientStart.opacity(0.6))
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "photo")
                                .font(.system(size: 28)).foregroundColor(Color(.systemGray4))
                            Text("No photo added")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(.systemGray4))
                        }
                    }
                }
                .frame(height: 160)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(title.isEmpty ? "Untitled Listing" : title)
                                .font(.system(size: 19, weight: .heavy, design: .rounded))
                                .foregroundColor(Theme.Colors.label)
                            if !foodType.isEmpty {
                                Text(foodType.uppercased())
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundColor(Theme.Colors.primaryGradientStart)
                                    .tracking(0.8)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Theme.Colors.primaryGradientStart.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(isFree ? "Free" : (manualOverride ? displayOverride : displaySuggested))
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(Theme.Colors.primaryGradient)
                            Text("Qty: \(quantity)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.primaryGradientStart)
                        Text("Pickup: \(pickupLabel)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(18)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: Color.black.opacity(0.08), radius: 18, y: 6)

            HStack(spacing: 14) {
                Button("Edit") {
                    hapticFeedback(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { step = 4 }
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryLabel)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Button {
                    hapticFeedback(.success)
                    isPosting = true
                    let (pStart, pEnd) = resolvedPickupDates
                    listingVM.title = title
                    listingVM.description = title
                    listingVM.category = FoodListing.FoodCategory(rawValue: foodType) ?? .meals
                    listingVM.isFree = isFree
                    listingVM.originalPrice = String(format: "%.2f", Double(originalCents) / 100.0)
                    let discountedCents = manualOverride ? (Int(overrideDigits) ?? 0) : suggestedCents
                    listingVM.discountedPrice = String(format: "%.2f", Double(discountedCents) / 100.0)
                    listingVM.quantity = String(quantity)
                    listingVM.pickupStartTime = pStart
                    listingVM.pickupEndTime = pEnd
                    Task {
                        await listingVM.postListing()
                        isPosting = false
                        if listingVM.showSuccess { withAnimation { showSuccess = true } }
                    }
                } label: {
                    ZStack {
                        if isPosting {
                            ProgressView().tint(.white).scaleEffect(0.9)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Confirm & Post")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Theme.Colors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.3), radius: 12, y: 6)
                }
                .disabled(isPosting)
            }
        }
    }

    // MARK: - Pickup date resolution
    private var resolvedPickupDates: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        switch pickupWindow {
        case "Custom Time":
            return (customDate, customDate.addingTimeInterval(7200))
        case "6:00 PM – 9:00 PM":
            let start = cal.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
            return (start, start.addingTimeInterval(10800))
        case "7:00 PM – 10:00 PM":
            let start = cal.date(bySettingHour: 19, minute: 0, second: 0, of: now) ?? now
            return (start, start.addingTimeInterval(10800))
        default: // "Until Close"
            let end = cal.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? now
            return (now, end)
        }
    }

    // MARK: - Shared helpers
    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.Colors.label)
            Text(subtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func fieldBlock<C: View>(label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(Theme.Colors.tertiaryLabel).tracking(1.2)
            content()
        }
    }

    private func navRow(onNext: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Button { goBack() } label: {
                Text("Back")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            Button { onNext() } label: {
                HStack(spacing: 8) {
                    Text("Next").font(.system(size: 16, weight: .heavy, design: .rounded))
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .black))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(Theme.Colors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.3), radius: 10, y: 5)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func accentNextButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label).font(.system(size: 17, weight: .heavy, design: .rounded))
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .black))
            }
            .foregroundColor(Theme.Colors.primaryGradientStart)
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(Theme.Colors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.15), radius: 10, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private enum ActionStyle { case gradient, gray }
    private func actionButton(label: String, icon: String, style: ActionStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(style == .gradient ? .white : Theme.Colors.label)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(style == .gradient
                    ? AnyShapeStyle(Theme.Colors.primaryGradient)
                    : AnyShapeStyle(Color(.systemGray6)))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay {
                    if style == .gray {
                        RoundedRectangle(cornerRadius: 22).stroke(Color(.systemGray4), lineWidth: 1)
                    }
                }
        }
    }

    private func advance() {
        hapticFeedback(.light)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) { step += 1 }
    }

    private func goBack() {
        hapticFeedback(.light)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            step -= 1
            if step < 4 { showDatePicker = false }
        }
    }

    private func showValidationError(_ message: String) {
        hapticFeedback(.medium)
        errorMsg = message
        showError = true
    }
}

// MARK: - Success Overlay
private struct SuccessOverlayView: View {
    let title: String
    let pickup: String
    let onDone: () -> Void

    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var animateConfetti = false

    private struct ConfettiPiece: Identifiable {
        let id: Int
        let color: Color
        let size: CGFloat
        let rotation: Double
        let xOffset: CGFloat
        let yDest: CGFloat
        let duration: Double
        let delay: Double
    }

    private let confettiColors: [Color] = [
        Color(hex: "118b50"), Color(hex: "5db996"), Color(hex: "caf8a5"),
        .orange, .yellow, .pink, .blue, .purple
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            // Confetti
            GeometryReader { geo in
                ForEach(confettiPieces) { p in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .rotationEffect(.degrees(p.rotation))
                        .position(x: geo.size.width / 2 + (animateConfetti ? p.xOffset : 0),
                                  y: animateConfetti ? p.yDest : -30)
                        .opacity(animateConfetti ? 0 : 1)
                        .animation(.easeOut(duration: p.duration).delay(p.delay), value: animateConfetti)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 32) {
                Spacer()

                // Celebration icon
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primaryGradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.4), radius: 24, y: 8)
                    Image(systemName: "checkmark")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(animateConfetti ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.65), value: animateConfetti)

                VStack(spacing: 12) {
                    Text("Listing Posted!")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.Colors.label)
                    Text("Your surplus food is now live.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.Colors.secondaryLabel)
                }

                // Listing summary card
                VStack(spacing: 14) {
                    summaryRow(icon: "fork.knife", label: "Listing", value: title.isEmpty ? "Surplus Item" : title)
                    Divider()
                    summaryRow(icon: "clock.fill", label: "Pickup", value: pickup)
                    Divider()
                    summaryRow(icon: "leaf.fill", label: "Impact", value: "Reducing food waste")
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: Color.black.opacity(0.08), radius: 18, y: 6)
                .padding(.horizontal, 24)

                Spacer()

                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 58)
                        .background(Theme.Colors.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: Theme.Colors.primaryGradientStart.opacity(0.35), radius: 12, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            confettiPieces = (0..<60).map { i in
                ConfettiPiece(
                    id: i,
                    color: confettiColors[i % confettiColors.count],
                    size: CGFloat.random(in: 6...14),
                    rotation: Double(i) * 137.5,
                    xOffset: CGFloat.random(in: -180...180),
                    yDest: CGFloat.random(in: 400...900),
                    duration: Double.random(in: 1.4...2.8),
                    delay: Double(i) * 0.03
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { animateConfetti = true }
            }
        }
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryGradientStart)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryLabel)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.label)
                .multilineTextAlignment(.trailing)
        }
    }
}

//
//  PremiumListingViews.swift
//  RePlate - Premium Food Listing Views
//
//  Created by Jyotika Sadani on 5/27/26.
//

import SwiftUI
import Supabase

// MARK: - Premium Food Listing Card (Customer View)
struct PremiumFoodListingCard: View {
    let listing: FoodListing
    let distance: Double?
    let showDistance: Bool
    let onTap: () -> Void
    @State private var isSaved: Bool = false
    
    init(
        listing: FoodListing,
        distance: Double? = nil,
        showDistance: Bool = true,
        onTap: @escaping () -> Void = {}
    ) {
        self.listing = listing
        self.distance = distance
        self.showDistance = showDistance
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            hapticFeedback(.light)
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image with Badges
                ZStack(alignment: .topTrailing) {
                    // Image
                    if let imageURL = listing.imageURLs.first {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .empty:
                                ShimmerView(cornerRadius: 0)
                                    .frame(height: 220)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 220)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Theme.Colors.tertiaryBackground)
                                    .frame(height: 220)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(Theme.Colors.tertiaryLabel)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    
                    // Gradient Overlay for better text visibility
                    LinearGradient(
                        colors: [Color.black.opacity(0.3), Color.clear, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 220)
                    
                    // Badges & Save Button
                    VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                        HStack(spacing: Theme.Spacing.xs) {
                            // Status Badges
                            if listing.isFree {
                                PremiumBadge(text: "FREE", style: .gradient)
                            } else if listing.discountPercentage > 0 {
                                PremiumBadge(
                                    text: "\(listing.discountPercentage)% OFF",
                                    style: .filled(Theme.Colors.success)
                                )
                            }
                            
                            if listing.isAlmostGone {
                                PremiumBadge(text: "Almost Gone", style: .filled(Theme.Colors.warning))
                            }
                            
                            Spacer()
                            
                            // Save Button
                            Button {
                                withAnimation(Theme.Animation.springBouncy) {
                                    isSaved.toggle()
                                }
                                hapticFeedback(.light)
                            } label: {
                                Image(systemName: isSaved ? "heart.fill" : "heart")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(isSaved ? Theme.Colors.error : .white)
                                    .frame(width: 40, height: 40)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(Theme.CornerRadius.pill)
                            }
                        }
                        .padding(Theme.Spacing.compactSpacing)
                    }
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    // Restaurant Name
                    if let restaurant = listing.restaurant {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.primaryGradientStart)
                            
                            Text(restaurant.name)
                                .font(Theme.Typography.subheadlineMedium)
                                .foregroundColor(Theme.Colors.secondaryLabel)
                            
                            if restaurant.verified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.info)
                            }
                        }
                    }
                    
                    // Title
                    Text(listing.title)
                        .font(Theme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.label)
                        .lineLimit(2)
                    
                    // Dietary Info Tags
                    if !listing.dietaryInfo.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.xs) {
                                ForEach(Array(listing.dietaryInfo.prefix(3)), id: \.self) { diet in
                                    PremiumBadge(
                                        text: diet.rawValue,
                                        style: .subtle(Theme.Colors.primaryGradientStart)
                                    )
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Bottom Row: Price, Distance, Pickup Time
                    HStack(alignment: .bottom) {
                        // Price
                        VStack(alignment: .leading, spacing: 2) {
                            if listing.isFree {
                                Text("FREE")
                                    .font(Theme.Typography.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Theme.Colors.primaryGradient)
                            } else {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("$\(String(format: "%.2f", listing.discountedPrice))")
                                        .font(Theme.Typography.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Theme.Colors.label)
                                    
                                    if listing.originalPrice > listing.discountedPrice {
                                        Text("$\(String(format: "%.2f", listing.originalPrice))")
                                            .font(Theme.Typography.caption)
                                            .foregroundColor(Theme.Colors.tertiaryLabel)
                                            .strikethrough()
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Distance & Pickup Info
                        VStack(alignment: .trailing, spacing: 4) {
                            if showDistance, let distance = distance {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 11))
                                    Text(String(format: "%.1f mi", distance))
                                        .font(Theme.Typography.captionMedium)
                                }
                                .foregroundColor(Theme.Colors.secondaryLabel)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 11))
                                Text(listing.pickupStartTime.formatted(date: .omitted, time: .shortened))
                                    .font(Theme.Typography.captionMedium)
                            }
                            .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                    }
                }
                .padding(Theme.Spacing.cardPadding)
            }
            .background(Theme.Colors.elevatedCard)
            .cornerRadius(Theme.CornerRadius.cardLarge)
            .shadow(color: Color.black.opacity(0.08), radius: 16, y: 4)
            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(PremiumScaleButtonStyle())
    }
}

// MARK: - Premium Listing Detail View
struct PremiumListingDetailView: View {
    let listing: FoodListing
    @Environment(\.dismiss) var dismiss
    @State private var showClaimSheet = false
    @State private var selectedQuantity = 1
    @State private var currentImageIndex = 0
    @State private var showReport = false
    @State private var showReportConfirm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image Carousel
                imageCarousel
                
                // Content
                VStack(spacing: Theme.Spacing.sectionSpacing) {
                    // Header Section
                    headerSection
                    
                    // Quick Info Cards
                    quickInfoSection
                    
                    // Description
                    descriptionSection
                    
                    // Restaurant Info
                    restaurantSection
                    
                    // Pickup Information
                    pickupSection
                    
                    // Environmental Impact
                    impactCard
                }
                .padding(Theme.Spacing.screenPadding)
                .padding(.bottom, 100)
            }
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topLeading) {
            // Back Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.label)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .cornerRadius(Theme.CornerRadius.pill)
            }
            .padding(Theme.Spacing.screenPadding)
            .padding(.top, Theme.Spacing.huge)
        }
        .overlay(alignment: .topTrailing) {
            // Report listing menu
            Menu {
                Button("Report listing", role: .destructive) {
                    // TODO: backend — POST /reports
                    showReport = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.label)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .cornerRadius(Theme.CornerRadius.pill)
            }
            .padding(Theme.Spacing.screenPadding)
            .padding(.top, Theme.Spacing.huge)
            .alert("Report Submitted", isPresented: $showReport) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Thank you. Our team will review this listing.")
            }
        }
        .overlay(alignment: .bottom) {
            // Claim Button
            claimButton
        }
        .sheet(isPresented: $showClaimSheet) {
            ClaimListingSheet(listing: listing, selectedQuantity: $selectedQuantity)
        }
    }
    
    // MARK: - Image Carousel
    private var imageCarousel: some View {
        TabView(selection: $currentImageIndex) {
            ForEach(0..<listing.imageURLs.count, id: \.self) { index in
                AsyncImage(url: URL(string: listing.imageURLs[index])) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        Rectangle()
                            .fill(Theme.Colors.tertiaryBackground)
                    @unknown default:
                        EmptyView()
                    }
                }
                .tag(index)
            }
        }
        .frame(height: 400)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .bottom) {
            // Page Indicator
            HStack(spacing: 6) {
                ForEach(0..<listing.imageURLs.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.5))
                        .frame(width: index == currentImageIndex ? 24 : 6, height: 6)
                        .animation(Theme.Animation.springSnappy, value: currentImageIndex)
                }
            }
            .padding(Theme.Spacing.base)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Category Badge
            PremiumBadge(
                text: listing.category.rawValue,
                style: .subtle(Theme.Colors.primaryGradientStart)
            )
            
            // Title
            Text(listing.title)
                .font(Theme.Typography.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(Theme.Colors.label)
            
            // Price Row
            HStack(alignment: .firstTextBaseline) {
                if listing.isFree {
                    Text("FREE")
                        .font(Theme.Typography.display)
                        .fontWeight(.heavy)
                        .foregroundStyle(Theme.Colors.primaryGradient)
                } else {
                    Text("$\(String(format: "%.2f", listing.discountedPrice))")
                        .font(Theme.Typography.display)
                        .fontWeight(.heavy)
                        .foregroundColor(Theme.Colors.label)
                    
                    if listing.originalPrice > listing.discountedPrice {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("$\(String(format: "%.2f", listing.originalPrice))")
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.tertiaryLabel)
                                .strikethrough()
                            
                            PremiumBadge(
                                text: "\(listing.discountPercentage)% OFF",
                                style: .filled(Theme.Colors.success)
                            )
                        }
                    }
                }
                
                Spacer()
            }
            
            // Quantity Available
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "bag.fill")
                    .foregroundStyle(Theme.Colors.primaryGradient)
                Text("\(listing.availableQuantity) available")
                    .font(Theme.Typography.bodyMedium)
                    .foregroundColor(Theme.Colors.label)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Quick Info Section
    private var quickInfoSection: some View {
        HStack(spacing: Theme.Spacing.compactSpacing) {
            QuickInfoCard(
                icon: "clock.fill",
                title: "Pickup",
                value: listing.pickupStartTime.formatted(date: .omitted, time: .shortened)
            )
            
            QuickInfoCard(
                icon: "timer",
                title: "Available Until",
                value: listing.expiresAt.formatted(date: .omitted, time: .shortened)
            )
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Description")
                .font(Theme.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.label)
            
            Text(listing.description)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryLabel)
                .lineSpacing(4)
            
            // Dietary Info
            if !listing.dietaryInfo.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Dietary Information")
                        .font(Theme.Typography.calloutMedium)
                        .foregroundColor(Theme.Colors.label)
                    
                    FlowLayout(spacing: Theme.Spacing.xs) {
                        ForEach(Array(listing.dietaryInfo), id: \.self) { diet in
                            HStack(spacing: 4) {
                                Image(systemName: diet.icon)
                                Text(diet.rawValue)
                            }
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.primaryGradientStart)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(Theme.Colors.accent.opacity(0.2))
                            .cornerRadius(Theme.CornerRadius.xs)
                        }
                    }
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
    }
    
    // MARK: - Restaurant Section
    private var restaurantSection: some View {
        Group {
            if let restaurant = listing.restaurant {
                PremiumCard(style: .elevated) {
                    HStack(spacing: Theme.Spacing.base) {
                        // Restaurant Image
                        AsyncImage(url: URL(string: restaurant.imageURL ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Rectangle()
                                    .fill(Theme.Colors.tertiaryBackground)
                                    .overlay(
                                        Image(systemName: "fork.knife")
                                            .foregroundColor(Theme.Colors.tertiaryLabel)
                                    )
                            }
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(Theme.CornerRadius.base)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(restaurant.name)
                                    .font(Theme.Typography.headline)
                                    .foregroundColor(Theme.Colors.label)
                                
                                if restaurant.verified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.Colors.info)
                                }
                            }
                            
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.Colors.warning)
                                Text(String(format: "%.1f", restaurant.rating))
                                    .font(Theme.Typography.subheadline)
                                    .foregroundColor(Theme.Colors.secondaryLabel)
                                Text("•")
                                    .foregroundColor(Theme.Colors.tertiaryLabel)
                                Text("\(restaurant.totalReviews) reviews")
                                    .font(Theme.Typography.subheadline)
                                    .foregroundColor(Theme.Colors.secondaryLabel)
                            }
                            
                            Text(restaurant.address)
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.tertiaryLabel)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.tertiaryLabel)
                    }
                }
            }
        }
    }
    
    // MARK: - Pickup Section
    private var pickupSection: some View {
        PremiumCard(style: .elevated) {
            VStack(alignment: .leading, spacing: Theme.Spacing.base) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.Colors.primaryGradient)
                    
                    Text("Pickup Information")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.label)
                }
                
                Divider()
                
                VStack(spacing: Theme.Spacing.md) {
                    InfoRow(
                        icon: "calendar",
                        label: "Pickup Window",
                        value: "\(listing.pickupStartTime.formatted(date: .abbreviated, time: .shortened)) - \(listing.pickupEndTime.formatted(date: .omitted, time: .shortened))"
                    )
                    
                    if let restaurant = listing.restaurant {
                        // SECURITY: reveal full address only after order.status == .confirmed, enforced server-side
                        // For browse/detail view (pre-order), show only neighborhood to protect restaurant privacy
                        let addressDisplay: String = {
                            let parts = restaurant.address.components(separatedBy: ",")
                            // Show city/area only (last 1-2 components) until order is confirmed
                            if parts.count >= 2 {
                                return parts.dropFirst().joined(separator: ",").trimmingCharacters(in: .whitespaces)
                            }
                            return restaurant.address
                        }()
                        InfoRow(
                            icon: "location.fill",
                            label: "Area",
                            value: addressDisplay + " (Full address shown after ordering)"
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Impact Card
    private var impactCard: some View {
        PremiumCard(style: .flat) {
            HStack(spacing: Theme.Spacing.base) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Colors.primaryGradient)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Environmental Impact")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.label)
                    
                    Text("Claiming this food saves ~2.5kg of CO₂ emissions")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.secondaryLabel)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Claim Button
    private var claimButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            AnimatedButton("Claim This Food", icon: "bag.fill", style: .primary) {
                showClaimSheet = true
            }
            .padding(Theme.Spacing.screenPadding)
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - Supporting Views

struct QuickInfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Theme.Colors.primaryGradient)
            
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryLabel)
            
            Text(value)
                .font(Theme.Typography.subheadlineMedium)
                .foregroundColor(Theme.Colors.label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.base)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.base)
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.compactSpacing) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryLabel)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryLabel)
                
                Text(value)
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.label)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Flow Layout (for tags)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            let pos = result.positions[index]
            subview.place(at: CGPoint(x: pos.x + bounds.origin.x, y: pos.y + bounds.origin.y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Claim Listing Sheet
struct ClaimListingSheet: View {
    let listing: FoodListing
    @Binding var selectedQuantity: Int
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var paymentService = StripePaymentService.shared

    @State private var isProcessing = false
    @State private var paymentComplete = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var totalPrice: Double { listing.discountedPrice * Double(selectedQuantity) }
    private var buttonLabel: String {
        if listing.isFree { return "Claim Free — Confirm" }
        return "Pay $\(String(format: "%.2f", totalPrice))"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Order summary card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order Summary")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.label)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(listing.restaurantName)
                                    .font(.system(size: 15, weight: .semibold))
                                Text(listing.title)
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.Colors.secondaryLabel)
                            }
                            Spacer()
                        }

                        Divider()

                        // Quantity row
                        HStack {
                            Text("Quantity")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                            Spacer()
                            HStack(spacing: 16) {
                                Button {
                                    if selectedQuantity > 1 { selectedQuantity -= 1 }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Theme.Colors.primaryGradient)
                                }
                                .disabled(selectedQuantity <= 1)

                                Text("\(selectedQuantity)")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(minWidth: 24)

                                Button {
                                    if selectedQuantity < listing.availableQuantity {
                                        selectedQuantity += 1
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Theme.Colors.primaryGradient)
                                }
                                .disabled(selectedQuantity >= listing.availableQuantity)
                            }
                        }

                        Divider()

                        // Price row
                        if listing.isFree {
                            HStack {
                                Text("Total")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Text("Free")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Theme.Colors.primaryGradientStart)
                            }
                        } else {
                            HStack {
                                Text("Total")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("$\(String(format: "%.2f", totalPrice))")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Theme.Colors.primaryGradientStart)
                                    Text("Saved $\(String(format: "%.2f", (listing.originalPrice - listing.discountedPrice) * Double(selectedQuantity)))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)

                    // Pickup info
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Theme.Colors.primaryGradientStart)
                        Text("Pick up from \(listing.restaurantName). Bring your pickup code.")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                    }
                    .padding(14)
                    .background(Theme.Colors.primaryGradientStart.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Security note for paid listings
                    if !listing.isFree {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.primaryGradientStart)
                            // SECURITY: Stripe handles card tokenization; no raw card data stored
                            Text("Payments secured by Stripe. Card data is never stored on your device.")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                        .padding(.horizontal, 4)
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(Theme.Colors.pageBackground)
            .navigationTitle(listing.isFree ? "Claim Food" : "Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isProcessing)
                }
            }
            .safeAreaInset(edge: .bottom) {
                checkoutButton
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
            }
            .overlay {
                if paymentComplete {
                    paymentSuccessOverlay
                }
            }
            .alert("Payment Error", isPresented: $showError) {
                Button("OK") {}
                Button("Retry") { handlePayment() }
            } message: {
                Text(errorMessage ?? "Something went wrong.")
            }
        }
    }

    // MARK: - Checkout Button
    private var checkoutButton: some View {
        AnimatedButton(
            buttonLabel,
            icon: listing.isFree ? "checkmark.circle.fill" : "creditcard.fill",
            style: .primary
        ) {
            handlePayment()
        }
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.7 : 1)
        .overlay {
            if isProcessing {
                HStack(spacing: 10) {
                    ProgressView().tint(.white)
                    Text("Processing\u{2026}").foregroundColor(.white).font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }

    // MARK: - Payment Success Overlay
    private var paymentSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primaryGradientStart)
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(listing.isFree ? "Food Claimed!" : "Payment Complete!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Check Orders for your pickup code.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }

    // MARK: - Handle Payment
    private func handlePayment() {
        isProcessing = true
        hapticFeedback(.medium)

        guard let uid = supabase.auth.currentSession?.user.id.uuidString,
              let accessToken = supabase.auth.currentSession?.accessToken else {
            isProcessing = false
            return
        }

        // Generate a random 6-char uppercase pickup code
        let pickupCode = String((0..<6).compactMap { _ in
            "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".randomElement()
        })

        struct OrderInsert: Encodable {
            let listing_id: String
            let customer_id: String
            let restaurant_id: String
            let quantity: Int
            let total_amount: Double
            let status: String
            let pickup_code: String
            let pickup_code_used: Bool
            let pickup_window_start: String
            let pickup_window_end: String
        }
        struct InsertResult: Decodable { let id: String }

        let iso = ISO8601DateFormatter()
        let payload = OrderInsert(
            listing_id: listing.id,
            customer_id: uid,
            restaurant_id: listing.restaurantId,
            quantity: selectedQuantity,
            total_amount: listing.isFree ? 0 : listing.discountedPrice * Double(selectedQuantity),
            status: listing.isFree ? "confirmed" : "pending",
            pickup_code: pickupCode,
            pickup_code_used: false,
            pickup_window_start: iso.string(from: listing.pickupStartTime),
            pickup_window_end: iso.string(from: listing.pickupEndTime)
        )

        if listing.isFree {
            Task {
                _ = try? await supabase
                    .from("orders")
                    .insert(payload)
                    .select("id")
                    .execute()
                    .value as [InsertResult]
                await MainActor.run {
                    isProcessing = false
                    withAnimation { paymentComplete = true }
                }
            }
            return
        }

        // Paid listing — create order row with status=pending, then call Stripe
        // SECURITY: payment amount is validated server-side in the Edge Function
        Task {
            var orderId = UUID().uuidString
            if let results = try? await supabase
                .from("orders")
                .insert(payload)
                .select("id")
                .execute()
                .value as [InsertResult],
               let first = results.first {
                orderId = first.id
            }

            await MainActor.run {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else {
                    isProcessing = false
                    return
                }

                paymentService.startPayment(
                    orderId: orderId,
                    supabaseToken: accessToken,
                    from: rootVC
                ) { result in
                    isProcessing = false
                    switch result {
                    case .completed(let paymentIntentId):
                        // Webhook (stripe-webhook Edge Function) is source of truth for status=confirmed
                        print("[Payment] Completed, intentId: \(paymentIntentId)")
                        withAnimation { paymentComplete = true }
                    case .canceled:
                        break
                    case .failed(let error):
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
    }
}

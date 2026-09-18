//
//  ViewModels.swift
//  RePlate
//
//  Created by Jyotika Sadani on 5/26/26.
//

import SwiftUI
import Combine
import Supabase

// MARK: - Home View Model
@MainActor
class HomeViewModel: ObservableObject {
    @Published var listings: [FoodListing] = []
    @Published var featuredListings: [FoodListing] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var impactStats = ImpactStats.empty
    @Published var showMap = false
    
    func loadListings() async {
        if DemoData.isScreenshotMode {
            listings = DemoData.listings
            featuredListings = Array(DemoData.listings.prefix(3))
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            let rows: [ListingRow] = try await supabase
                .from("food_listings")
                .select()
                .eq("status", value: "active")
                .gte("pickup_end", value: ISO8601DateFormatter().string(from: Date()))
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            listings = rows.map { $0.toFoodListing() }
            featuredListings = Array(listings.prefix(3))
        } catch {
            listings = []
            featuredListings = []
        }
        impactStats = ImpactStats.empty
    }
    
    func refreshListings() async {
        await loadListings()
    }
    
    func toggleMapView() {
        showMap.toggle()
        hapticFeedback(.light)
    }
}

// MARK: - Restaurant Dashboard View Model
@MainActor
class RestaurantDashboardViewModel: ObservableObject {
    @Published var activeListings: [FoodListing] = []
    @Published var pendingOrders: [Order] = []
    @Published var todayStats: DashboardStats = .empty
    @Published var isLoading = false
    @Published var hasUnreadNotifications: Bool = false
    
    struct DashboardStats {
        var activeListings: Int
        var pendingOrders: Int
        var revenueToday: Double
        var mealsSaved: Int
        var co2Reduced: Double
        
        static var empty: DashboardStats {
            DashboardStats(activeListings: 0, pendingOrders: 0, revenueToday: 0, mealsSaved: 0, co2Reduced: 0)
        }
    }
    
    func loadDashboard() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let uid = supabase.auth.currentSession?.user.id.uuidString else { return }

        do {
            let rows: [ListingRow] = try await supabase
                .from("food_listings")
                .select()
                .eq("restaurant_id", value: uid)
                .eq("status", value: "active")
                .execute()
                .value
            activeListings = rows.map { $0.toFoodListing() }
        } catch {
            activeListings = []
        }

        pendingOrders = []
        hasUnreadNotifications = false
        todayStats = DashboardStats(
            activeListings: activeListings.count,
            pendingOrders: 0,
            revenueToday: 0,
            mealsSaved: 0,
            co2Reduced: 0
        )
    }
    
    func refreshDashboard() async {
        await loadDashboard()
    }
}

// MARK: - Restaurant Profile View Model

@MainActor
class RestaurantProfileViewModel: ObservableObject {
    @Published var cuisine: String = ""
    @Published var address: String = ""
    @Published var phone: String = ""
    @Published var isLoading = false

    private struct RestaurantFields: Decodable {
        let cuisine: [String]
        let address: String?
        let phoneNumber: String?
        enum CodingKeys: String, CodingKey {
            case cuisine, address
            case phoneNumber = "phone_number"
        }
    }

    func load() async {
        guard let uid = supabase.auth.currentSession?.user.id.uuidString else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let row: RestaurantFields = try await supabase
                .from("restaurants")
                .select("cuisine, address, phone_number")
                .eq("owner_id", value: uid)
                .single()
                .execute()
                .value
            cuisine = row.cuisine.joined(separator: ", ")
            address = row.address ?? ""
            phone = row.phoneNumber ?? ""
        } catch { }
    }
}

// MARK: - Post Listing View Model
@MainActor
class PostListingViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var category: FoodListing.FoodCategory = .meals
    @Published var originalPrice = ""
    @Published var discountedPrice = ""
    @Published var quantity = "1"
    @Published var isFree = false
    @Published var selectedImages: [UIImage] = []
    @Published var pickupStartTime = Date().addingTimeInterval(3600)
    @Published var pickupEndTime = Date().addingTimeInterval(7200)
    @Published var selectedDietaryInfo: Set<FoodListing.DietaryInfo> = []
    @Published var isPosting = false
    @Published var showSuccess = false
    
    var canPost: Bool {
        !title.isEmpty &&
        !quantity.isEmpty &&
        (isFree || !discountedPrice.isEmpty)
    }

    func postListing() async {
        guard canPost else { return }
        isPosting = true
        defer { isPosting = false }

        guard let uid = supabase.auth.currentSession?.user.id.uuidString else { return }

        struct RestaurantFields: Decodable {
            let name: String
            let address: String?
        }
        var restaurantName = ""
        var restaurantAddress = ""
        if let row: RestaurantFields = try? await supabase
            .from("restaurants")
            .select("name, address")
            .eq("owner_id", value: uid)
            .single()
            .execute()
            .value {
            restaurantName = row.name
            restaurantAddress = row.address ?? ""
        }

        // Upload first listing photo if provided
        var uploadedImageUrl: String? = nil
        if let firstImage = selectedImages.first,
           let jpegData = firstImage.jpegData(compressionQuality: 0.8) {
            let imagePath = "\(uid)/\(UUID().uuidString).jpg"
            try? await supabase.storage.from("listing-images")
                .upload(imagePath, data: jpegData,
                        options: FileOptions(contentType: "image/jpeg", upsert: false))
            if let imageUrl = try? supabase.storage.from("listing-images").getPublicURL(path: imagePath) {
                uploadedImageUrl = imageUrl.absoluteString
            }
        }

        struct ListingInsert: Encodable {
            let restaurant_id: String
            let title: String
            let description: String
            let category: String
            let original_price: Double?
            let discounted_price: Double?
            let is_free: Bool
            let quantity: Int
            let quantity_remaining: Int
            let pickup_start: String
            let pickup_end: String
            let status: String
            let dietary_info: [String]
            let restaurant_name: String
            let address: String
            let image_url: String?
        }

        let iso = ISO8601DateFormatter()
        let qty = Int(quantity) ?? 1
        let payload = ListingInsert(
            restaurant_id: uid,
            title: title,
            description: description,
            category: category.rawValue,
            original_price: isFree ? nil : Double(originalPrice),
            discounted_price: isFree ? nil : Double(discountedPrice),
            is_free: isFree,
            quantity: qty,
            quantity_remaining: qty,
            pickup_start: iso.string(from: pickupStartTime),
            pickup_end: iso.string(from: pickupEndTime),
            status: "active",
            dietary_info: selectedDietaryInfo.map { $0.rawValue },
            restaurant_name: restaurantName,
            address: restaurantAddress,
            image_url: uploadedImageUrl
        )

        do {
            try await supabase.from("food_listings").insert(payload).execute()
            hapticFeedback(.success)
            showSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.resetForm()
            }
        } catch { }
    }
    
    func resetForm() {
        title = ""
        description = ""
        category = .meals
        originalPrice = ""
        discountedPrice = ""
        quantity = "1"
        isFree = false
        selectedImages = []
        pickupStartTime = Date().addingTimeInterval(3600)
        pickupEndTime = Date().addingTimeInterval(7200)
        selectedDietaryInfo = []
    }
    
    func suggestPrice() {
        // AI-based pricing suggestion
        if !originalPrice.isEmpty, let original = Double(originalPrice) {
            let suggested = original * 0.5
            discountedPrice = String(format: "%.2f", suggested)
        }
    }
}

// MARK: - Orders View Model
@MainActor
class OrdersViewModel: ObservableObject {
    @Published var pendingOrders: [Order] = []
    @Published var completedOrders: [Order] = []
    @Published var isLoading = false
    @Published var selectedTab = 0

    func loadOrders() async {
        isLoading = true
        defer { isLoading = false }

        if DemoData.isScreenshotMode {
            pendingOrders = DemoData.orders.filter {
                $0.status == .pending || $0.status == .confirmed || $0.status == .ready
            }
            completedOrders = []
            return
        }

        guard let uid = supabase.auth.currentSession?.user.id.uuidString else { return }

        do {
            let rows: [OrderRow] = try await supabase
                .from("orders")
                .select("id, listing_id, customer_id, restaurant_id, quantity, total_amount, status, pickup_code, pickup_window_start, pickup_window_end, notes, payment_id, created_at, completed_at")
                .eq("customer_id", value: uid)
                .order("created_at", ascending: false)
                .execute()
                .value
            let orders = rows.map { $0.toOrder() }
            pendingOrders = orders.filter { $0.status == .pending || $0.status == .confirmed || $0.status == .ready }
            completedOrders = orders.filter { $0.status == .completed || $0.status == .cancelled || $0.status == .noShow }
        } catch {
            // Fetch failed — leave empty state
        }
    }

    func cancelOrder(_ order: Order) {
        withAnimation {
            pendingOrders.removeAll { $0.id == order.id }
            var cancelled = order
            cancelled.status = .cancelled
            completedOrders.insert(cancelled, at: 0)
        }
        hapticFeedback(.success)
        Task {
            try? await supabase
                .from("orders")
                .update(["status": "cancelled"])
                .eq("id", value: order.id)
                .execute()
        }
    }

    func updateOrderStatus(orderId: String, status: Order.OrderStatus) async {
        let dbStatus: String
        switch status {
        case .pending: dbStatus = "pending"
        case .confirmed: dbStatus = "confirmed"
        case .ready: dbStatus = "ready"
        case .completed: dbStatus = "completed"
        case .cancelled, .noShow: dbStatus = "cancelled"
        }
        try? await supabase
            .from("orders")
            .update(["status": dbStatus])
            .eq("id", value: orderId)
            .execute()
        hapticFeedback(.success)
        await loadOrders()
    }

    func markAsNoShow(orderId: String) async {
        await updateOrderStatus(orderId: orderId, status: .noShow)
    }
}

// MARK: - Search View Model
@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [FoodListing] = []
    @Published var recentSearches: [String] = []
    @Published var filters = SearchFilters()
    @Published var isLoading = false
    @Published var showFilters = false
    
    func search() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let rows: [ListingRow] = try await supabase
                .from("food_listings")
                .select()
                .eq("status", value: "active")
                .ilike("title", value: "%\(searchQuery)%")
                .order("created_at", ascending: false)
                .limit(30)
                .execute()
                .value
            searchResults = rows.map { $0.toFoodListing() }
        } catch {
            searchResults = []
        }

        if !recentSearches.contains(searchQuery) {
            recentSearches.insert(searchQuery, at: 0)
            if recentSearches.count > 5 { recentSearches.removeLast() }
        }
    }
    
    func applyFilters() async {
        showFilters = false
        await search()
    }
    
    func clearFilters() {
        filters = SearchFilters()
    }
}

// MARK: - Profile View Model
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var showEditProfile = false
    @Published var showSettings = false
    
    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }

        if DemoData.isScreenshotMode {
            user = DemoData.user
            return
        }

        try? await Task.sleep(nanoseconds: 500_000_000)

        // Load from auth service
        user = RePlateAuthService.shared.currentUser
    }
    
    func updateProfile(name: String, email: String, phoneNumber: String?) async {
        isLoading = true
        defer { isLoading = false }
        RePlateAuthService.shared.updateCurrentUser(name: name, email: email, phoneNumber: phoneNumber)
        hapticFeedback(.success)
        await loadProfile()
    }
    
    func exportData() async {
        // Export user data
        hapticFeedback(.success)
    }
    
    func deleteAccount() async {
        _ = await RePlateAuthService.shared.deleteAccount()
    }
}

// MARK: - Messages View Model
@MainActor
class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false

    private struct ConvRow: Decodable {
        let id: String
        let orderId: String?
        let customerId: String
        let restaurantId: String
        let updatedAt: String
        let restaurants: RestaurantJoin?

        struct RestaurantJoin: Decodable { let name: String }

        enum CodingKeys: String, CodingKey {
            case id
            case orderId = "order_id"
            case customerId = "customer_id"
            case restaurantId = "restaurant_id"
            case updatedAt = "updated_at"
            case restaurants
        }
    }

    func loadConversations() async {
        isLoading = true
        defer { isLoading = false }
        guard supabase.auth.currentSession != nil else {
            if DemoData.isScreenshotMode { conversations = DemoData.conversations }
            return
        }
        do {
            let rows: [ConvRow] = try await supabase
                .from("conversations")
                .select("id, order_id, customer_id, restaurant_id, updated_at, restaurants(name)")
                .order("updated_at", ascending: false)
                .execute().value
            let iso = ISO8601DateFormatter()
            conversations = rows.map { row in
                var conv = Conversation(
                    id: row.id,
                    orderId: row.orderId ?? "",
                    order: nil,
                    participantIds: [row.customerId, row.restaurantId],
                    participants: nil,
                    lastMessage: nil,
                    unreadCount: 0,
                    updatedAt: iso.date(from: row.updatedAt) ?? Date()
                )
                conv.restaurantName = row.restaurants?.name
                return conv
            }
        } catch {
            // Fetch failed — leave empty state
        }
    }

    func markAsRead(conversationId: String) async {}
}

// MockData is defined in MockData.swift

// MARK: - Supabase row decodable for orders

private struct OrderRow: Decodable {
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

// MARK: - Supabase row decodable for food_listings

private struct ListingRow: Decodable {
    let id: String
    let restaurantId: String
    let title: String
    let description: String
    let category: String
    let originalPrice: Double?
    let discountedPrice: Double?
    let isFree: Bool
    let quantity: Int
    let quantityRemaining: Int
    let pickupStart: Date
    let pickupEnd: Date
    let status: String
    let dietaryInfo: [String]
    let imageUrl: String?
    let restaurantName: String?
    let address: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, description, category, quantity, status, address
        case restaurantId = "restaurant_id"
        case originalPrice = "original_price"
        case discountedPrice = "discounted_price"
        case isFree = "is_free"
        case quantityRemaining = "quantity_remaining"
        case pickupStart = "pickup_start"
        case pickupEnd = "pickup_end"
        case dietaryInfo = "dietary_info"
        case imageUrl = "image_url"
        case restaurantName = "restaurant_name"
        case createdAt = "created_at"
    }

    func toFoodListing() -> FoodListing {
        let cat = FoodListing.FoodCategory(rawValue: category.capitalized)
            ?? FoodListing.FoodCategory.meals
        let dietary = dietaryInfo.compactMap { FoodListing.DietaryInfo(rawValue: $0) }

        let restaurant = Restaurant(
            id: restaurantId,
            name: restaurantName ?? "Unknown Restaurant",
            description: "",
            address: address ?? "",
            location: .init(latitude: 0, longitude: 0),
            phoneNumber: "",
            email: "",
            imageURL: nil,
            coverImageURL: nil,
            cuisine: [],
            rating: 0,
            totalReviews: 0,
            verified: false,
            activeListingsCount: 0,
            isPremium: false
        )

        return FoodListing(
            id: id,
            restaurantId: restaurantId,
            restaurant: restaurant,
            title: title,
            description: description,
            category: cat,
            imageURLs: imageUrl.map { [$0] } ?? [],
            originalPrice: originalPrice ?? 0,
            discountedPrice: discountedPrice ?? 0,
            isFree: isFree,
            quantity: quantity,
            availableQuantity: quantityRemaining,
            pickupStartTime: pickupStart,
            pickupEndTime: pickupEnd,
            status: FoodListing.ListingStatus(rawValue: status) ?? .active,
            createdAt: createdAt,
            expiresAt: pickupEnd,
            tags: [],
            dietaryInfo: dietary
        )
    }
}

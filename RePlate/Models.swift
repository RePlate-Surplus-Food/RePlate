//
//  Models.swift
//  RePlate
//
//  Created by Jyotika Sadani on 5/26/26.
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - User
struct User: Identifiable, Codable {
    let id: String
    var email: String
    var name: String
    var phoneNumber: String?
    var profileImageURL: String?
    var accountType: AccountType
    var createdAt: Date
    var verifiedRestaurant: Bool

    // Stripe Connect — set after calling create-connect-account Edge Function.
    // TODO: Load from your database on sign-in instead of storing only in memory.
    var stripeAccountId: String?

    // Stats
    var mealsSaved: Int
    var co2Reduced: Double // in kg
    var foodRescued: Double // in lbs
    
    enum AccountType: String, Codable, CaseIterable {
        case customer
        case restaurant
        
        var displayName: String {
            switch self {
            case .customer: return "Customer"
            case .restaurant: return "Restaurant"
            }
        }
        
        var icon: String {
            switch self {
            case .customer: return "person.fill"
            case .restaurant: return "fork.knife"
            }
        }
    }
}

// MARK: - Restaurant
struct Restaurant: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var address: String
    var location: LocationCoordinate
    var phoneNumber: String
    var email: String
    var imageURL: String?
    var coverImageURL: String?
    var cuisine: [String]
    var rating: Double
    var totalReviews: Int
    var verified: Bool
    var activeListingsCount: Int
    var isPremium: Bool
    
    struct LocationCoordinate: Codable {
        let latitude: Double
        let longitude: Double
        
        var clCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}

// MARK: - Food Listing
struct FoodListing: Identifiable, Codable {
    let id: String
    var restaurantId: String
    var restaurant: Restaurant?
    var title: String
    var description: String
    var category: FoodCategory
    var imageURLs: [String]
    var originalPrice: Double
    var discountedPrice: Double
    var isFree: Bool
    var quantity: Int
    var availableQuantity: Int
    var pickupStartTime: Date
    var pickupEndTime: Date
    var status: ListingStatus
    var createdAt: Date
    var expiresAt: Date
    var tags: [String]
    var dietaryInfo: [DietaryInfo]
    
    var discountPercentage: Int {
        guard originalPrice > 0 else { return 0 }
        return Int(((originalPrice - discountedPrice) / originalPrice) * 100)
    }

    /// Convenience alias used in UI — same calculation as discountPercentage but as Double.
    var savingsPercentage: Double {
        guard originalPrice > 0 else { return 0 }
        return ((originalPrice - discountedPrice) / originalPrice) * 100
    }

    /// Display name for the restaurant; falls back gracefully when the join is absent.
    var restaurantName: String {
        restaurant?.name ?? "Unknown Restaurant"
    }

    var isAlmostGone: Bool {
        availableQuantity <= 2
    }
    
    var isExpiringSoon: Bool {
        expiresAt.timeIntervalSinceNow < 3600 // Less than 1 hour
    }
    
    enum ListingStatus: String, Codable {
        case active
        case claimed
        case completed
        case expired
        case cancelled
    }
    
    enum FoodCategory: String, Codable, CaseIterable {
        // Meal times
        case breakfast   = "Breakfast"
        case lunch       = "Lunch"
        case dinner      = "Dinner"
        case snacks      = "Snacks"
        // Food types
        case meals       = "Meals"
        case bakery      = "Bakery"
        case desserts    = "Desserts"
        case produce     = "Produce"
        case beverages   = "Beverages"
        // Cuisines
        case indian      = "Indian"
        case italian     = "Italian"
        case mexican     = "Mexican"
        case chinese     = "Chinese"
        case japanese    = "Japanese"
        case korean      = "Korean"
        case thai        = "Thai"
        case american    = "American"
        case mediterranean = "Mediterranean"
        case asian       = "Asian"
        // Catch-all
        case other       = "Other"

        var icon: String {
            switch self {
            case .breakfast:     return "sunrise.fill"
            case .lunch:         return "sun.max.fill"
            case .dinner:        return "moon.stars.fill"
            case .snacks:        return "takeoutbag.and.cup.and.straw"
            case .meals:         return "fork.knife"
            case .bakery:        return "birthday.cake"
            case .desserts:      return "birthday.cake.fill"
            case .produce:       return "carrot"
            case .beverages:     return "cup.and.saucer"
            case .indian:        return "flame.fill"
            case .italian:       return "fork.knife.circle.fill"
            case .mexican:       return "leaf.arrow.circlepath"
            case .chinese:       return "cup.and.saucer.fill"
            case .japanese:      return "fish.fill"
            case .korean:        return "flame.circle.fill"
            case .thai:          return "leaf.circle.fill"
            case .american:      return "takeoutbag.and.cup.and.straw.fill"
            case .mediterranean: return "sun.horizon.fill"
            case .asian:         return "globe.asia.australia.fill"
            case .other:         return "bag"
            }
        }
    }
    
    enum DietaryInfo: String, Codable, CaseIterable {
        case vegetarian = "Vegetarian"
        case vegan = "Vegan"
        case glutenFree = "Gluten-Free"
        case dairyFree = "Dairy-Free"
        case nutFree = "Nut-Free"
        case halal = "Halal"
        case kosher = "Kosher"
        case jain = "Jain"

        var icon: String {
            switch self {
            case .vegetarian: return "leaf"
            case .vegan: return "leaf.fill"
            case .glutenFree: return "g.circle"
            case .dairyFree: return "d.circle"
            case .nutFree: return "n.circle"
            case .halal: return "h.circle"
            case .kosher: return "k.circle"
            case .jain: return "j.circle"
            }
        }
    }
}

// MARK: - Order
struct Order: Identifiable, Codable {
    let id: String
    var listingId: String
    var listing: FoodListing?
    var customerId: String
    var customer: User?
    var restaurantId: String
    var restaurant: Restaurant?
    var quantity: Int
    var totalAmount: Double
    var status: OrderStatus
    var pickupCode: String
    var pickupTime: Date
    var pickupWindowStart: Date
    var pickupWindowEnd: Date
    var createdAt: Date
    var completedAt: Date?
    var notes: String?
    var paymentId: String?
    
    var isPickupTimeApproaching: Bool {
        let timeUntilPickup = pickupWindowStart.timeIntervalSinceNow
        return timeUntilPickup > 0 && timeUntilPickup < 1800 // 30 minutes
    }
    
    var isOverdue: Bool {
        pickupWindowEnd < Date()
    }
    
    enum OrderStatus: String, Codable {
        case pending = "Pending"
        case confirmed = "Confirmed"
        case ready = "Ready for Pickup"
        case completed = "Completed"
        case cancelled = "Cancelled"
        case noShow = "No Show"
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .confirmed: return .blue
            case .ready: return .green
            case .completed: return .gray
            case .cancelled: return .red
            case .noShow: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "clock"
            case .confirmed: return "checkmark.circle"
            case .ready: return "bag.badge.checkmark"
            case .completed: return "checkmark.circle.fill"
            case .cancelled: return "xmark.circle"
            case .noShow: return "exclamationmark.triangle"
            }
        }
    }
}

// MARK: - Message
struct Message: Identifiable, Codable {
    let id: String
    var orderId: String
    var senderId: String
    var receiverId: String
    var content: String
    var timestamp: Date
    var read: Bool
    var messageType: MessageType
    
    enum MessageType: String, Codable {
        case text
        case system
        case image
    }
}

// MARK: - Conversation
struct Conversation: Identifiable, Codable {
    let id: String
    var orderId: String
    var order: Order?
    var participantIds: [String]
    var participants: [User]?
    var lastMessage: Message?
    var unreadCount: Int
    var updatedAt: Date
    var restaurantName: String? = nil
}

// MARK: - Notification Model
struct AppNotification: Identifiable, Codable {
    let id: String
    var userId: String
    var title: String
    var body: String
    var type: NotificationType
    var relatedId: String?
    var timestamp: Date
    var read: Bool
    var actionURL: String?
    
    enum NotificationType: String, Codable {
        case newListing
        case orderConfirmed
        case orderReady
        case pickupReminder
        case orderCompleted
        case orderCancelled
        case message
        case impactMilestone
        case listingExpiring
    }
}

// MARK: - Impact Stats
struct ImpactStats: Codable {
    var totalMealsSaved: Int
    var totalCO2Reduced: Double // kg
    var totalFoodRescued: Double // lbs
    var totalUsers: Int
    var totalRestaurants: Int
    var totalOrders: Int
    
    static var empty: ImpactStats {
        ImpactStats(
            totalMealsSaved: 0,
            totalCO2Reduced: 0,
            totalFoodRescued: 0,
            totalUsers: 0,
            totalRestaurants: 0,
            totalOrders: 0
        )
    }
}

// MARK: - Search Filters
struct SearchFilters {
    var categories: Set<FoodListing.FoodCategory> = []
    var maxDistance: Double? // in miles
    var maxPrice: Double?
    var pickupTime: DateRange?
    var dietaryRestrictions: Set<FoodListing.DietaryInfo> = []
    var freeOnly: Bool = false
    
    struct DateRange {
        let start: Date
        let end: Date
    }
    
    var isActive: Bool {
        !categories.isEmpty ||
        maxDistance != nil ||
        maxPrice != nil ||
        pickupTime != nil ||
        !dietaryRestrictions.isEmpty ||
        freeOnly
    }
}

// MARK: - Payment Method
struct PaymentMethod: Identifiable, Codable {
    let id: String
    var type: PaymentType
    var last4: String
    var brand: String?
    var expiryMonth: Int?
    var expiryYear: Int?
    var isDefault: Bool
    
    enum PaymentType: String, Codable {
        case card
        case applePay
        case googlePay
        case paypal
    }

    var displayName: String {
        switch type {
        case .card:
            return "\(brand ?? "Card") \u{2022}\u{2022}\u{2022}\u{2022} \(last4)"
        case .applePay:
            return "Apple Pay"
        case .googlePay:
            return "Google Pay"
        case .paypal:
            return "PayPal (\(last4))"
        }
    }

    // Display-only expiry string (MM/YY). Nil when expiry fields are absent.
    // SECURITY: expiry is display metadata only — raw card data is never stored here.
    var expiryDisplay: String? {
        guard let month = expiryMonth, let year = expiryYear else { return nil }
        return String(format: "%02d/%02d", month, year % 100)
    }
}

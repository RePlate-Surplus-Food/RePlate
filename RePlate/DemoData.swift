//
//  DemoData.swift
//  RePlate
//
//  Toggle isScreenshotMode = true before taking App Store screenshots,
//  then set it back to false before shipping.
//

import Foundation

enum DemoData {
    static var isScreenshotMode = false
    static var holdSplash = false

    // MARK: - Demo Listings
    static var listings: [FoodListing] {
        let now = Date()
        let soon = now.addingTimeInterval(3600)
        let later = now.addingTimeInterval(7200)

        func makeRestaurant(id: String, name: String, address: String) -> Restaurant {
            Restaurant(
                id: id, name: name, description: "", address: address,
                location: .init(latitude: 37.78, longitude: -122.41),
                phoneNumber: "", email: "", imageURL: nil, coverImageURL: nil,
                cuisine: [], rating: 4.8, totalReviews: 312, verified: true,
                activeListingsCount: 2, isPremium: false
            )
        }

        return [
            FoodListing(
                id: "demo-1",
                restaurantId: "r1",
                restaurant: makeRestaurant(id: "r1", name: "Panera Bread", address: "142 Main St"),
                title: "Sourdough Surprise Bag",
                description: "Assorted artisan bread loaves, bagels, and pastries baked fresh this morning.",
                category: .bakery,
                imageURLs: [],
                originalPrice: 18.00,
                discountedPrice: 5.99,
                isFree: false,
                quantity: 5,
                availableQuantity: 3,
                pickupStartTime: soon,
                pickupEndTime: later,
                status: .active,
                createdAt: now,
                expiresAt: later,
                tags: ["Fresh", "Bakery"],
                dietaryInfo: [.vegetarian]
            ),
            FoodListing(
                id: "demo-2",
                restaurantId: "r2",
                restaurant: makeRestaurant(id: "r2", name: "Green Bowl Bistro", address: "88 Market Ave"),
                title: "Lunch Rescue Box",
                description: "Chef's daily salads, grain bowls, and seasonal wraps — surplus from today's lunch rush.",
                category: .lunch,
                imageURLs: [],
                originalPrice: 24.00,
                discountedPrice: 8.49,
                isFree: false,
                quantity: 4,
                availableQuantity: 2,
                pickupStartTime: soon,
                pickupEndTime: later,
                status: .active,
                createdAt: now,
                expiresAt: later,
                tags: ["Healthy", "Fresh"],
                dietaryInfo: [.vegan, .glutenFree]
            ),
            FoodListing(
                id: "demo-3",
                restaurantId: "r3",
                restaurant: makeRestaurant(id: "r3", name: "Spice Garden Indian Kitchen", address: "310 Oak Blvd"),
                title: "Curry & Rice Feast Box",
                description: "Dal makhani, butter chicken, basmati rice, naan — enough for 2 people.",
                category: .indian,
                imageURLs: [],
                originalPrice: 32.00,
                discountedPrice: 9.99,
                isFree: false,
                quantity: 6,
                availableQuantity: 4,
                pickupStartTime: soon,
                pickupEndTime: later,
                status: .active,
                createdAt: now,
                expiresAt: later,
                tags: ["Hot", "Spicy"],
                dietaryInfo: [.vegetarian]
            ),
            FoodListing(
                id: "demo-4",
                restaurantId: "r4",
                restaurant: makeRestaurant(id: "r4", name: "Bella Napoli Pizzeria", address: "55 Elm Street"),
                title: "Pizza Slice Bundle",
                description: "Assorted slices: Margherita, Pepperoni, Veggie Supreme — wood-fired and fresh.",
                category: .italian,
                imageURLs: [],
                originalPrice: 22.00,
                discountedPrice: 6.99,
                isFree: false,
                quantity: 8,
                availableQuantity: 5,
                pickupStartTime: soon,
                pickupEndTime: later,
                status: .active,
                createdAt: now,
                expiresAt: later,
                tags: ["Hot", "Popular"],
                dietaryInfo: []
            ),
            FoodListing(
                id: "demo-5",
                restaurantId: "r5",
                restaurant: makeRestaurant(id: "r5", name: "Sweet Crumbs Bakery", address: "27 Blossom Lane"),
                title: "Dessert Mystery Box",
                description: "Assorted cupcakes, cookies, macarons, and brownies. A sweet surprise in every box!",
                category: .desserts,
                imageURLs: [],
                originalPrice: 20.00,
                discountedPrice: 5.49,
                isFree: false,
                quantity: 10,
                availableQuantity: 6,
                pickupStartTime: soon,
                pickupEndTime: later,
                status: .active,
                createdAt: now,
                expiresAt: later,
                tags: ["Sweet", "Variety"],
                dietaryInfo: [.vegetarian]
            ),
        ]
    }

    // MARK: - Demo Orders
    static var orders: [Order] {
        let now = Date()
        let pickupStart = now.addingTimeInterval(1800)
        let pickupEnd = now.addingTimeInterval(3600)

        let listing = listings[0]

        return [
            Order(
                id: "order-demo-1",
                listingId: "demo-1",
                listing: listing,
                customerId: "user-demo",
                customer: nil,
                restaurantId: "r1",
                restaurant: listing.restaurant,
                quantity: 1,
                totalAmount: 5.99,
                status: .ready,
                pickupCode: "RP-4821",
                pickupTime: pickupStart,
                pickupWindowStart: pickupStart,
                pickupWindowEnd: pickupEnd,
                createdAt: now.addingTimeInterval(-1800),
                completedAt: nil,
                notes: nil,
                paymentId: nil
            ),
            Order(
                id: "order-demo-2",
                listingId: "demo-3",
                listing: listings[2],
                customerId: "user-demo",
                customer: nil,
                restaurantId: "r3",
                restaurant: listings[2].restaurant,
                quantity: 1,
                totalAmount: 9.99,
                status: .confirmed,
                pickupCode: "RP-7043",
                pickupTime: pickupStart.addingTimeInterval(3600),
                pickupWindowStart: pickupStart.addingTimeInterval(3600),
                pickupWindowEnd: pickupEnd.addingTimeInterval(3600),
                createdAt: now.addingTimeInterval(-900),
                completedAt: nil,
                notes: nil,
                paymentId: nil
            ),
        ]
    }

    // MARK: - Demo Conversations
    static var conversations: [Conversation] {
        let now = Date()

        let panera = Message(
            id: "msg-1", orderId: "order-demo-1",
            senderId: "r1", receiverId: "user-demo",
            content: "Your Sourdough Surprise Bag is ready for pickup! 🎉",
            timestamp: now.addingTimeInterval(-600),
            read: false, messageType: .text
        )
        let spice = Message(
            id: "msg-2", orderId: "order-demo-2",
            senderId: "r3", receiverId: "user-demo",
            content: "Order confirmed! Pickup window is 7–8 PM. See you soon 🍛",
            timestamp: now.addingTimeInterval(-1800),
            read: true, messageType: .text
        )
        let sweet = Message(
            id: "msg-3", orderId: "order-demo-3",
            senderId: "r5", receiverId: "user-demo",
            content: "Thanks for rescuing food with us! Come back tomorrow 🧁",
            timestamp: now.addingTimeInterval(-86400),
            read: true, messageType: .text
        )

        return [
            Conversation(
                id: "conv-1", orderId: "order-demo-1",
                order: orders[0],
                participantIds: ["user-demo", "r1"],
                participants: nil,
                lastMessage: panera,
                unreadCount: 1,
                updatedAt: panera.timestamp
            ),
            Conversation(
                id: "conv-2", orderId: "order-demo-2",
                order: orders[1],
                participantIds: ["user-demo", "r3"],
                participants: nil,
                lastMessage: spice,
                unreadCount: 0,
                updatedAt: spice.timestamp
            ),
            Conversation(
                id: "conv-3", orderId: "order-demo-3",
                order: nil,
                participantIds: ["user-demo", "r5"],
                participants: nil,
                lastMessage: sweet,
                unreadCount: 0,
                updatedAt: sweet.timestamp
            ),
        ]
    }

    // MARK: - Demo User
    static var user: User {
        User(
            id: "user-demo",
            email: "alex@example.com",
            name: "Alex Rivera",
            phoneNumber: nil,
            profileImageURL: nil,
            accountType: .customer,
            createdAt: Date().addingTimeInterval(-86400 * 90),
            verifiedRestaurant: false,
            stripeAccountId: nil,
            mealsSaved: 47,
            co2Reduced: 38.2,
            foodRescued: 84.5
        )
    }
}

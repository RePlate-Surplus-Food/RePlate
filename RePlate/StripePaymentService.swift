//
//  StripePaymentService.swift
//  RePlate
//
//  ─── HOW TO ACTIVATE REAL STRIPE PAYMENTS ──────────────────────────────────
//  Step 1  Xcode → File → Add Package Dependencies
//          URL: https://github.com/stripe/stripe-ios
//          Add product: StripePaymentSheet
//
//  Step 2  Uncomment the `import StripePaymentSheet` line below.
//
//  Step 3  In RePlateApp.swift, uncomment:
//            STPAPIClient.shared.publishableKey = StripeConfig.publishableKey
//
//  Step 4  Set stripeSDKInstalled = true (search for that constant below).
//
//  Step 5  Supabase Edge Functions already deployed — nothing else needed on server.
//  ───────────────────────────────────────────────────────────────────────────

import SwiftUI
import Foundation
import Combine

import StripePaymentSheet

private let stripeSDKInstalled = true

// MARK: - Payment Result
enum PaymentResult {
    case completed(paymentIntentId: String)
    case canceled
    case failed(Error)
}

// MARK: - Payment Service
@MainActor
class StripePaymentService: ObservableObject {
    static let shared = StripePaymentService()

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Create Order + Launch PaymentSheet
    // Call this when a customer taps "Pay $X".
    // orderId must already exist in Supabase with status = pending.
    func startPayment(
        orderId: String,
        supabaseToken: String,
        from viewController: UIViewController,
        completion: @escaping (PaymentResult) -> Void
    ) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let (clientSecret, amountCents) = try await fetchPaymentIntent(
                    orderId: orderId,
                    supabaseToken: supabaseToken
                )

                await MainActor.run {
                    self.isLoading = false
                    self.presentPaymentSheet(clientSecret: clientSecret, from: viewController, completion: completion)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    completion(.failed(error))
                }
            }
        }
    }

    // MARK: - Fetch PaymentIntent from Edge Function
    private func fetchPaymentIntent(orderId: String, supabaseToken: String) async throws -> (clientSecret: String, amountCents: Int) {
        // OWASP A03: validate orderId format before touching the network
        guard Validators.isUUID(orderId) else {
            throw PaymentError.serverError("Invalid order identifier.")
        }

        guard let url = URL(string: StripeConfig.createPaymentIntentURL) else {
            throw PaymentError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(supabaseToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        // OWASP A05: 30-second timeout prevents indefinite hangs on slow/malicious endpoints
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: ["orderId": orderId])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PaymentError.networkError
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        // Free listing — no payment sheet needed
        if json["free"] as? Bool == true {
            throw PaymentError.listingIsFree
        }

        // Surface rate-limit errors so the UI can show a helpful message
        if httpResponse.statusCode == 429 {
            throw PaymentError.serverError("Too many requests. Please try again in a moment.")
        }

        guard httpResponse.statusCode == 200,
              let clientSecret = json["clientSecret"] as? String,
              let amountCents  = json["amountCents"]  as? Int else {
            let msg = json["error"] as? String ?? "Unknown error"
            throw PaymentError.serverError(msg)
        }

        return (clientSecret, amountCents)
    }

    // MARK: - Present PaymentSheet
    private func presentPaymentSheet(
        clientSecret: String,
        from viewController: UIViewController,
        completion: @escaping (PaymentResult) -> Void
    ) {
        STPAPIClient.shared.publishableKey = StripeConfig.publishableKey

        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "RePlate"
        config.allowsDelayedPaymentMethods = false

        let paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
        paymentSheet.present(from: viewController) { result in
            switch result {
            case .completed:
                let piId = clientSecret.components(separatedBy: "_secret_").first ?? clientSecret
                completion(.completed(paymentIntentId: piId))
            case .canceled:
                completion(.canceled)
            case .failed(let error):
                completion(.failed(error))
            }
        }
    }

    // MARK: - Card Tokenization
    // Converts card fields into a Stripe PaymentMethod ID (pm_xxx).
    // The app ONLY ever sees pm_xxx — no raw card numbers leave the device.
    func tokenizeCard(
        number: String,
        expMonth: Int,
        expYear: Int,
        cvc: String,
        name: String
    ) async throws -> (paymentMethodId: String, last4: String, brand: String) {

        if stripeSDKInstalled {
            // ── REAL IMPLEMENTATION ───────────────────────────────────────────
            // Uncomment this entire block after completing all 5 setup steps:
            /*
            let cardParams = STPPaymentMethodCardParams()
            cardParams.number = number
            cardParams.expMonth = NSNumber(value: expMonth)
            cardParams.expYear  = NSNumber(value: expYear)
            cardParams.cvc      = cvc

            let billing = STPPaymentMethodBillingDetails()
            billing.name = name

            let pmParams = STPPaymentMethodParams(
                card: cardParams,
                billingDetails: billing,
                metadata: nil
            )

            return try await withCheckedThrowingContinuation { continuation in
                STPAPIClient.shared.createPaymentMethod(with: pmParams) { paymentMethod, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let pm = paymentMethod else {
                        continuation.resume(throwing: PaymentError.networkError)
                        return
                    }
                    let brand = pm.card?.brand.stringValue ?? "Card"
                    let last4 = pm.card?.last4 ?? String(number.filter(\.isNumber).suffix(4))
                    continuation.resume(returning: (pm.stripeId, last4, brand))
                }
            }
            */
            throw PaymentError.serverError("Stripe SDK not yet imported — check setup steps.")
        }

        // ── STUB (active until stripeSDKInstalled = true) ─────────────────
        // Simulates a 1.2-second network round-trip for UI testing.
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        let rawDigits = number.filter(\.isNumber)
        let last4 = String(rawDigits.suffix(4))
        let brand: String
        if rawDigits.hasPrefix("4")                           { brand = "Visa" }
        else if rawDigits.hasPrefix("5") || rawDigits.hasPrefix("2") { brand = "Mastercard" }
        else if rawDigits.hasPrefix("34") || rawDigits.hasPrefix("37") { brand = "Amex" }
        else if rawDigits.hasPrefix("6")                      { brand = "Discover" }
        else                                                  { brand = "Card" }
        return ("pm_stub_\(UUID().uuidString.prefix(8))", last4, brand)
    }

    // MARK: - Save Payment Method (display-only, no raw card data)
    // Call after a successful payment to save brand + last4 for display in Profile.
    // SECURITY: never pass or store raw card numbers — Stripe handles card tokenization.
    func savePaymentMethod(
        userId: String,
        brand: String,
        last4: String,
        expMonth: Int,
        expYear: Int,
        supabaseToken: String
    ) async {
        // TODO: POST to Supabase payment_methods table via supabase-swift client
        // Example (uncomment after adding supabase-swift package):
        // try? await supabase
        //     .from("payment_methods")
        //     .upsert([
        //         "user_id": userId,
        //         "type": "card",
        //         "brand": brand,
        //         "last4": last4,
        //         "exp_month": expMonth,
        //         "exp_year": expYear,
        //         "is_default": true
        //     ])
        //     .execute()
        print("[Stripe] Would save payment method: \(brand) \u{2022}\u{2022}\u{2022}\u{2022}\(last4) to Supabase")
    }
}

// MARK: - Payment Errors
enum PaymentError: LocalizedError {
    case invalidURL
    case networkError
    case serverError(String)
    case listingIsFree

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Payment service URL is invalid."
        case .networkError: return "Network error. Please try again."
        case .serverError(let msg): return "Payment error: \(msg)"
        case .listingIsFree: return "This listing is free — no payment required."
        }
    }
}

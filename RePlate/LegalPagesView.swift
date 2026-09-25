//
//  LegalPagesView.swift
//  RePlate
//
//  Full legal content for all policy pages.
//  Effective Date: June 2026
//

import SwiftUI

// MARK: - Legal Page Router
struct LegalPageView: View {
    let page: LegalPage

    enum LegalPage: String, CaseIterable, Identifiable {
        var id: String { rawValue }

        case privacyPolicy      = "Privacy Policy"
        case termsOfService     = "Terms of Service"
        case communityGuidelines = "Community Guidelines"
        case foodSafetyPolicy   = "Food Safety Policy"
        case refundPolicy       = "Refund Policy"
        case dataPolicy         = "Data Policy"
        case faq                = "FAQs"

        var icon: String {
            switch self {
            case .privacyPolicy:       return "lock.shield.fill"
            case .termsOfService:      return "doc.text.fill"
            case .communityGuidelines: return "person.3.fill"
            case .foodSafetyPolicy:    return "cross.fill"
            case .refundPolicy:        return "arrow.uturn.left.circle.fill"
            case .dataPolicy:          return "externaldrive.fill"
            case .faq:                 return "questionmark.circle.fill"
            }
        }
    }

    // NON-BINDING TEMPLATE — must be reviewed by a qualified legal professional before real-world use.
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Theme.Colors.primaryGradient)
                                .frame(width: 56, height: 56)
                            Image(systemName: page.icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(page.rawValue)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(Theme.Colors.label)
                            Text("Effective June 1, 2026")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                    }

                    // Non-binding disclaimer banner
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "92400e"))
                        Text("Non-binding template — must be reviewed by a qualified legal professional before real-world use.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .italic()
                            .foregroundColor(Color(hex: "92400e"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: "fef3c7"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "fde68a"), lineWidth: 1))
                }
                .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 20)

                Divider().padding(.horizontal, 24)

                // Content
                VStack(alignment: .leading, spacing: 0) {
                    switch page {
                    case .privacyPolicy:       PrivacyPolicyContent()
                    case .termsOfService:      TermsOfServiceContent()
                    case .communityGuidelines: CommunityGuidelinesContent()
                    case .foodSafetyPolicy:    FoodSafetyPolicyContent()
                    case .refundPolicy:        RefundPolicyContent()
                    case .dataPolicy:          DataPolicyContent()
                    case .faq:                 FAQContent()
                    }
                }
                .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 60)
            }
        }
        .background(Theme.Colors.pageBackground)
        .navigationTitle(page.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared legal text components
private struct Section: View {
    let title: String
    let content: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.label)
            Text(content)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryLabel)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 20)
    }
}

private struct BulletList: View {
    let items: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Text("•")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.Colors.primaryGradientStart)
                    Text(item)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Theme.Colors.secondaryLabel)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Privacy Policy
private struct PrivacyPolicyContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Section(title: "1. Introduction",
                    content: "RePlate, Inc. (\"RePlate,\" \"we,\" \"our,\" or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and related services (collectively, the \"Platform\"). Please read this policy carefully.")

            Section(title: "2. Information We Collect",
                    content: "We collect information you provide directly, information collected automatically, and information from third parties.")

            BulletList(items: [
                "Account information: name, email address, phone number, account type (customer or restaurant), and profile photo.",
                "Restaurant information: business name, address, operating hours, food service permit numbers, and verification documents.",
                "Transaction data: order history, payment amounts, pickup confirmations, and cancellation records.",
                "Usage data: app interactions, features accessed, search queries, and session duration.",
                "Location data: with your permission, precise GPS coordinates to show nearby listings and calculate distances.",
                "Device data: device type, OS version, IP address, and unique device identifiers.",
                "Communications: messages exchanged between customers and restaurants through the Platform.",
            ])

            Section(title: "3. How We Use Your Information",
                    content: "We use the collected information to provide, improve, and personalise our services.")

            BulletList(items: [
                "Create and manage your account.",
                "Process transactions and send related notices.",
                "Connect customers with nearby surplus food listings.",
                "Facilitate communication between customers and restaurants.",
                "Send notifications about orders, pickups, and listing updates.",
                "Improve platform safety and prevent fraud.",
                "Comply with legal obligations.",
                "Measure environmental impact and generate aggregate impact statistics.",
            ])

            Section(title: "4. Information Sharing",
                    content: "We do not sell your personal information. We may share information with service providers who assist in operating the Platform (e.g., payment processors, cloud storage), with other users only as necessary for completing a transaction (e.g., sharing your name with a restaurant for pickup confirmation), and with law enforcement when required by law.")

            Section(title: "5. Data Retention",
                    content: "We retain your information for as long as your account is active or as needed to provide services. You may request deletion of your account and associated data at any time through the app settings.")

            Section(title: "6. Your Rights",
                    content: "Depending on your jurisdiction, you may have rights to access, correct, port, or delete your personal data. To exercise these rights, contact us at replateog@gmail.com.")

            Section(title: "7. Security",
                    content: "We use industry-standard encryption and security practices to protect your data. However, no system is completely secure, and we cannot guarantee the absolute security of your information.")

            Section(title: "8. Children's Privacy",
                    content: "The Platform is not directed to children under 13. We do not knowingly collect personal information from children under 13. If we become aware that we have collected such information, we will delete it promptly.")

            Section(title: "9. Contact Us",
                    content: "Questions about this policy? Contact us at replateog@gmail.com or write to RePlate, Inc., Privacy Team, McKinney, TX.")
        }
    }
}

// MARK: - Terms of Service
private struct TermsOfServiceContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Section(title: "1. Acceptance of Terms",
                    content: "By creating an account or using RePlate, you agree to these Terms of Service (\"Terms\"). If you do not agree, do not use the Platform. These Terms constitute a legally binding agreement between you and RePlate, Inc.")

            Section(title: "2. Eligibility",
                    content: "You must be at least 18 years old to use RePlate. By using the Platform, you represent that you meet this requirement. Restaurant accounts must be operated by an authorised representative of the business.")

            Section(title: "3. Accounts",
                    content: "You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account. Notify us immediately of any unauthorised access. You may not share or transfer your account.")

            Section(title: "4. Restaurant Obligations",
                    content: "Restaurants using RePlate agree to:")

            BulletList(items: [
                "Complete verification before posting listings.",
                "Ensure all food meets applicable safety and health standards.",
                "Post accurate descriptions, quantities, and pickup windows.",
                "Honour all confirmed orders.",
                "Maintain food at safe temperatures until pickup.",
                "Comply with all local health department regulations.",
                "Not discriminate against customers.",
            ])

            Section(title: "5. Customer Obligations",
                    content: "Customers using RePlate agree to:")

            BulletList(items: [
                "Arrive within the designated pickup window.",
                "Use the correct pickup code to confirm collection.",
                "Not resell food purchased through RePlate.",
                "Treat restaurant staff with respect.",
                "Report food safety concerns promptly.",
            ])

            Section(title: "6. Prohibited Activities",
                    content: "Users may not post false or misleading information, manipulate pricing or availability, create fake accounts, harass other users, use the Platform for commercial resale, or attempt to circumvent platform security.")

            Section(title: "7. Payments",
                    content: "RePlate processes payments through third-party payment providers. By making a purchase, you agree to the payment provider's terms. RePlate charges restaurants a service fee on completed orders.")

            Section(title: "8. Disclaimers",
                    content: "RePlate is a technology platform connecting restaurants and customers. We do not prepare, inspect, or guarantee the quality of food. All food is consumed at the user's own risk. RePlate makes no warranties about the accuracy of listings.")

            Section(title: "9. Limitation of Liability",
                    content: "To the maximum extent permitted by law, RePlate shall not be liable for indirect, incidental, consequential, or punitive damages. Our total liability shall not exceed the amount you paid to RePlate in the 12 months preceding the claim.")

            Section(title: "10. Termination",
                    content: "We may suspend or terminate accounts that violate these Terms. You may delete your account at any time through app settings.")

            Section(title: "11. Governing Law",
                    content: "These Terms are governed by the laws of Texas, USA. Disputes shall be resolved through binding arbitration in McKinney, TX.")

            Section(title: "12. Contact",
                    content: "Legal questions: replateog@gmail.com")
        }
    }
}

// MARK: - Community Guidelines
private struct CommunityGuidelinesContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Section(title: "Our Mission",
                    content: "RePlate exists to reduce food waste and build stronger communities. Our community guidelines help ensure the Platform remains safe, fair, and beneficial for everyone.")

            Section(title: "For Restaurants",
                    content: "Great restaurant partners on RePlate:")

            BulletList(items: [
                "Post food that is fresh, safe, and accurately described.",
                "Set realistic pickup windows and honour them.",
                "Respond to customer messages within a reasonable timeframe.",
                "Keep their profile information up to date.",
                "Participate in good faith — no listing food they don't have.",
                "Treat every customer with respect regardless of background.",
            ])

            Section(title: "For Customers",
                    content: "Great customers on RePlate:")

            BulletList(items: [
                "Pick up orders within the confirmed window.",
                "Communicate promptly if plans change.",
                "Leave honest, constructive reviews.",
                "Respect restaurant staff and premises.",
                "Report food quality concerns rather than taking matters into their own hands.",
                "Not abuse the refund or cancellation system.",
            ])

            Section(title: "Zero Tolerance",
                    content: "The following behaviours result in immediate account suspension:")

            BulletList(items: [
                "Harassment, threats, or abusive language directed at any user.",
                "Fraudulent listings or fake reviews.",
                "Discrimination based on race, religion, gender, sexual orientation, disability, or any other protected characteristic.",
                "Reselling food purchased through RePlate for commercial profit.",
                "Submitting false verification documents.",
                "Intentional food safety violations.",
            ])

            Section(title: "Reporting",
                    content: "Use the in-app report feature to flag violations. Our moderation team reviews all reports within 24 hours. Serious violations are escalated immediately.")

            Section(title: "Consequences",
                    content: "Depending on severity: first offences may result in a warning, repeated violations in temporary suspension, and serious violations in permanent ban. Illegal activity is reported to law enforcement.")
        }
    }
}

// MARK: - Food Safety Policy
private struct FoodSafetyPolicyContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Section(title: "Our Commitment",
                    content: "Food safety is the foundation of RePlate. We require all participating restaurants to comply with applicable food safety laws and follow best practices for surplus food distribution.")

            Section(title: "Restaurant Requirements",
                    content: "All restaurants on RePlate must:")

            BulletList(items: [
                "Hold a valid food service permit in their jurisdiction.",
                "Pass all required health inspections.",
                "Maintain food at safe temperatures (below 40°F / 4°C for cold foods, above 140°F / 60°C for hot foods) until pickup.",
                "Clearly label all allergens in listing descriptions.",
                "Not post food that has been previously served to customers.",
                "Ensure food packaging is sealed and tamper-evident where required.",
                "Discard food that shows signs of spoilage, contamination, or improper storage.",
                "Train staff handling surplus food in basic food safety practices.",
            ])

            Section(title: "Allergen Disclosure",
                    content: "Restaurants must disclose all common allergens in their listings including: nuts, dairy, eggs, wheat/gluten, soy, shellfish, fish, and sesame. Customers with severe allergies should contact the restaurant directly before ordering.")

            Section(title: "Food Expiry",
                    content: "All listings must specify a pickup window. Food listings automatically expire at the end of the stated pickup window. Restaurants must remove listings for food that is no longer available or safe for consumption.")

            Section(title: "Customer Responsibility",
                    content: "Customers accept that surplus food may have a shorter shelf life than freshly prepared items. Customers should consume food promptly, store it properly, and report concerns immediately.")

            Section(title: "Reporting Food Safety Issues",
                    content: "Report food safety concerns immediately through the in-app reporting feature or by emailing replateog@gmail.com. Serious health concerns should also be reported to local health authorities.")

            Section(title: "Enforcement",
                    content: "Restaurants with verified food safety violations are immediately suspended pending investigation. Confirmed violations result in permanent removal from the Platform and may be reported to regulatory authorities.")
        }
    }
}

// MARK: - Refund Policy
private struct RefundPolicyContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Section(title: "Overview",
                    content: "RePlate facilitates transactions between restaurants and customers. Our refund policy is designed to be fair to both parties while accounting for the nature of surplus food.")

            Section(title: "Eligible Refunds",
                    content: "You are entitled to a full refund if:")

            BulletList(items: [
                "The restaurant cancels your order.",
                "The restaurant closes before your pickup window without notice.",
                "The food you received is unsafe, spoiled, or significantly different from the listing description.",
                "You arrive during the pickup window but the restaurant cannot fulfil the order.",
                "A technical error causes a duplicate charge.",
            ])

            Section(title: "Non-Eligible Situations",
                    content: "Refunds are generally not available if:")

            BulletList(items: [
                "You miss the pickup window without notifying the restaurant.",
                "You change your mind after the order is confirmed.",
                "Food meets the listing description but you dislike the taste.",
                "You request a refund after consuming all or most of the food.",
                "The order was fulfilled as described.",
            ])

            Section(title: "How to Request a Refund",
                    content: "1. Open the order in the Orders tab.\n2. Tap 'Report Issue'.\n3. Select the reason and provide any supporting details or photos.\n4. Submit your request.\n\nOur team will review within 1–2 business days.")

            Section(title: "Refund Processing",
                    content: "Approved refunds are returned to your original payment method within 3–7 business days, depending on your bank. RePlate credits may be offered as an alternative with faster processing.")

            Section(title: "Disputes",
                    content: "If you disagree with a refund decision, you may escalate to replateog@gmail.com within 14 days of the original decision. Escalated cases are reviewed by our Trust & Safety team.")

            Section(title: "Platform Service Fees",
                    content: "RePlate's platform service fee is non-refundable except in cases where the order was cancelled by the restaurant or a technical error occurred on our side.")
        }
    }
}

// MARK: - Data Policy
private struct DataPolicyContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Section(title: "Data We Collect",
                    content: "This policy provides additional detail on how RePlate collects, processes, and protects your data beyond our Privacy Policy.")

            Section(title: "Categories of Data",
                    content: "We process the following categories of personal data:")

            BulletList(items: [
                "Identity data: name, username, profile photo.",
                "Contact data: email address, phone number.",
                "Location data: GPS coordinates (with permission), address.",
                "Financial data: payment card details (processed by our payment provider; we do not store card numbers).",
                "Behavioural data: app usage patterns, click events, feature engagement.",
                "Device data: device model, OS, push notification tokens.",
                "Communication data: in-app messages between users.",
                "Verification data: business documents, permits (restaurants only).",
            ])

            Section(title: "Legal Basis for Processing",
                    content: "We process your data on the following bases: contract performance (to deliver our service), legitimate interests (to improve the Platform and prevent fraud), legal obligation (to comply with applicable law), and consent (for optional features such as marketing communications).")

            Section(title: "Data Transfers",
                    content: "Your data may be processed in the United States and other countries where our service providers operate. We ensure appropriate safeguards are in place for international transfers.")

            Section(title: "Third-Party Services",
                    content: "We use carefully selected third-party providers for:")

            BulletList(items: [
                "Payment processing (Stripe)",
                "Cloud storage (AWS)",
                "Push notifications (APNs / FCM)",
                "Analytics (privacy-respecting, aggregated)",
                "Fraud prevention",
            ])

            Section(title: "Your Data Rights",
                    content: "You have the right to: access a copy of your data, correct inaccurate data, request deletion, restrict processing, port your data to another service, and object to processing for direct marketing. To exercise any right, visit Settings > Privacy > Manage My Data or email replateog@gmail.com.")

            Section(title: "Data Deletion",
                    content: "When you delete your account: profile data is deleted within 30 days, transaction records are retained for 7 years for legal and tax compliance, aggregated anonymised impact statistics may be retained indefinitely.")

            Section(title: "Cookies & Tracking",
                    content: "The RePlate mobile app uses local storage (not browser cookies) to maintain your session and preferences. We use analytics SDKs that collect anonymised, aggregated usage data. We do not use cross-app tracking.")

            Section(title: "Contact",
                    content: "For data-related questions: replateog@gmail.com\nData Protection Officer: replateog@gmail.com")
        }
    }
}

// MARK: - FAQ
private struct FAQContent: View {
    private struct FAQItem: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }
    @State private var expanded: UUID?

    private let items: [FAQItem] = [
        FAQItem(
            question: "What is RePlate?",
            answer: "RePlate is a food waste reduction platform that connects restaurants with surplus food to nearby customers at a discounted price. Restaurants reduce waste, customers save money, and the community wins."
        ),
        FAQItem(
            question: "How do I place an order?",
            answer: "Browse listings on the Home tab, tap a listing you like, choose a quantity, and check out. You'll receive a pickup code to show the restaurant when you arrive during the pickup window."
        ),
        FAQItem(
            question: "How do discounts work?",
            answer: "Restaurants set a discounted price on surplus food — typically 50–70% off the original price. You pay that price at checkout and pick up the food directly from the restaurant."
        ),
        FAQItem(
            question: "What happens if I can't pick up my order?",
            answer: "Please cancel as early as possible so the restaurant can relist the food. See our Refund Policy for full details on cancellations and refunds."
        ),
        FAQItem(
            question: "How do restaurants get verified?",
            answer: "Restaurants must submit a business license, food service permit, health inspection report, tax documentation, and government-issued ID. Our team reviews each submission, typically within 2–3 business days."
        ),
        FAQItem(
            question: "Is my payment information secure?",
            answer: "Yes. Payments are processed by Stripe, a PCI DSS Level 1 certified provider. RePlate never stores your card number — only a tokenised reference from Stripe."
        ),
        FAQItem(
            question: "How do I report a problem with a restaurant or user?",
            answer: "Tap the ⋯ button in any conversation to report or block a user. You can also email replateog@gmail.com or use Help & Support > Report a Problem in your Profile tab."
        ),
        FAQItem(
            question: "How do I delete my account?",
            answer: "Go to Profile > Settings > Delete Account. Your profile data is deleted within 30 days. Transaction records are retained for 7 years for legal compliance."
        ),
        FAQItem(
            question: "How can I contact support?",
            answer: "Email us at replateog@gmail.com. You can also reach us via Profile > Help & Support > Contact Support."
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            expanded = expanded == item.id ? nil : item.id
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(item.question)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.Colors.label)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: expanded == item.id ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.Colors.secondaryLabel)
                        }
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if expanded == item.id {
                        Text(item.answer)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 14)
                    }

                    Divider()
                }
            }
        }
    }
}

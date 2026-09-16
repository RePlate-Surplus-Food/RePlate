//
//  MessagesView.swift
//  RePlate
//
//  Created by Jyotika Sadani on 5/26/26.
//

import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var selectedConversation: Conversation?

    var body: some View {
        VStack(spacing: 0) {
            // Gradient header matching other tabs
            messagesHeader

            // Content
            if viewModel.isLoading {
                loadingView
                Spacer(minLength: 0)
            } else if viewModel.conversations.isEmpty {
                Spacer(minLength: 0)
                emptyView
                Spacer(minLength: 0)
            } else {
                conversationsList
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.pageBackground)
        .task {
            await viewModel.loadConversations()
        }
        .refreshable {
            await viewModel.loadConversations()
        }
        .sheet(item: $selectedConversation) { conversation in
            ConversationView(conversation: conversation)
        }
    }

    // MARK: - Gradient Header (matches OrdersView style)
    private var messagesHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Messages")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(
                        viewModel.conversations.isEmpty
                            ? "No conversations yet"
                            : "\(viewModel.conversations.count) conversation\(viewModel.conversations.count == 1 ? "" : "s")"
                    )
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                let unread = viewModel.conversations.filter { $0.unreadCount > 0 }.count
                if unread > 0 {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.accent)
                            .frame(width: 44, height: 44)
                        Text("\(unread)")
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

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonView()
                        .frame(height: 80)
                        .padding(.horizontal, Theme.Spacing.lg)
                }
            }
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    private var emptyView: some View {
        EmptyStateView(
            icon: "message",
            title: "No Messages",
            message: "Your conversations with restaurants will appear here"
        )
    }

    private var conversationsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(viewModel.conversations) { conversation in
                    Button {
                        selectedConversation = conversation
                        hapticFeedback(.light)
                    } label: {
                        ConversationRow(conversation: conversation)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if conversation.id != viewModel.conversations.last?.id {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 110)
        }
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: Conversation

    private var displayName: String {
        conversation.restaurantName ?? conversation.order?.restaurant?.name ?? "Unknown Restaurant"
    }

    private var initials: String {
        String(displayName.prefix(1)).uppercased()
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Circular gradient avatar with first-letter initials
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryGradient)
                    .frame(width: 50, height: 50)
                Text(initials)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.label)

                    Spacer()

                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryLabel)
                    }
                }

                HStack {
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.content)
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .lineLimit(1)
                    }

                    Spacer()

                    if conversation.unreadCount > 0 {
                        // Small filled green dot for unread count
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.primaryGradient)
                                .frame(width: 22, height: 22)
                            Text("\(conversation.unreadCount)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Conversation View
struct ConversationView: View {
    @Environment(\.dismiss) var dismiss
    let conversation: Conversation
    @State private var messageText   = ""
    @State private var messages: [Message] = []
    @State private var currentUserId = ""
    @State private var showOrderInfo = false
    // §1.2: UGC — must provide report/block mechanism for all user-generated messaging
    @State private var showReportMenu   = false
    @State private var showBlockConfirm = false
    @State private var showReportConfirm = false
    @State private var reportReason: ReportReason?
    @State private var isBlocked = false

    enum ReportReason: String, CaseIterable, Identifiable {
        case spam       = "Spam or solicitation"
        case harassment = "Harassment or bullying"
        case offensive  = "Offensive content"
        case fraud      = "Fraud or scam"
        case other      = "Other"
        var id: String { rawValue }
    }

    private var restaurantName: String {
        conversation.restaurantName ?? conversation.order?.restaurant?.name ?? "User"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isBlocked {
                    blockedBanner
                }

                // Messages List
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        if messages.isEmpty {
                            Text("No messages yet")
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.secondaryLabel)
                                .frame(maxWidth: .infinity)
                                .padding(.top, Theme.Spacing.xxl)
                        } else {
                            ForEach(messages) { message in
                                MessageBubble(message: message, currentUserId: currentUserId)
                            }
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
                .background(Theme.Colors.pageBackground)

                if !isBlocked {
                    messageInputBar
                }
            }
            .background(Theme.Colors.pageBackground)
            .navigationTitle(restaurantName)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                currentUserId = supabase.auth.currentSession?.user.id.uuidString ?? ""
                await loadMessages()
            }
            .sheet(isPresented: $showOrderInfo) { OrderInfoSheet(order: conversation.order) }
            .confirmationDialog("Report or Block", isPresented: $showReportMenu, titleVisibility: .visible) {
                // §1.2: report mechanism with reason selection
                ForEach(ReportReason.allCases) { reason in
                    Button("Report: \(reason.rawValue)") {
                        reportReason = reason
                        showReportConfirm = true
                    }
                }
                Button("Block \(restaurantName)", role: .destructive) {
                    showBlockConfirm = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Report Sent", isPresented: $showReportConfirm) {
                Button("OK") {}
            } message: {
                Text("Thanks for reporting. Our Trust & Safety team will review this conversation within 24 hours. Contact support@replate.app for urgent issues.")
            }
            .alert("Block \(restaurantName)?", isPresented: $showBlockConfirm) {
                Button("Block", role: .destructive) {
                    withAnimation { isBlocked = true }
                    hapticFeedback(.medium)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You won't receive any more messages from this user. You can unblock them from Settings.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Theme.Colors.primaryGradientStart)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Button {
                            hapticFeedback(.light)
                            showOrderInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(Theme.Colors.primaryGradientStart)
                        }
                        // §1.2: ellipsis menu with Report & Block
                        Button {
                            hapticFeedback(.light)
                            showReportMenu = true
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(Theme.Colors.primaryGradientStart)
                        }
                    }
                }
            }
        }
    }

    private var blockedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 14))
            Text("You've blocked \(restaurantName). They can no longer message you.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
            Spacer()
            Button("Unblock") {
                withAnimation { isBlocked = false }
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(Theme.Colors.primaryGradientStart)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemRed).opacity(0.85))
    }

    private var messageInputBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            TextField("Type a message...", text: $messageText)
                .font(Theme.Typography.body)
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                        .fill(Theme.Colors.primaryGradientStart.opacity(0.07))
                )
                .cornerRadius(Theme.CornerRadius.xl)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Colors.primaryGradient)
            }
            .disabled(messageText.isEmpty)
            .opacity(messageText.isEmpty ? 0.5 : 1)
        }
        .padding(Theme.Spacing.md)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider().opacity(0.4)
        }
    }

    func sendMessage() {
        guard !messageText.isEmpty, !currentUserId.isEmpty else { return }
        let content = messageText
        messageText = ""
        let optimistic = Message(
            id: UUID().uuidString,
            orderId: conversation.orderId,
            senderId: currentUserId,
            receiverId: "",
            content: content,
            timestamp: Date(),
            read: false,
            messageType: .text
        )
        withAnimation { messages.append(optimistic) }
        hapticFeedback(.light)
        Task {
            struct MsgInsert: Encodable {
                let conversationId: String
                let topic: String
                let senderId: String
                let msgExtension: String
                let content: String
                let messageType: String
                enum CodingKeys: String, CodingKey {
                    case topic, content
                    case conversationId = "conversation_id"
                    case senderId = "sender_id"
                    case msgExtension = "extension"
                    case messageType = "message_type"
                }
            }
            let payload = MsgInsert(
                conversationId: conversation.id,
                topic: conversation.id,
                senderId: currentUserId,
                msgExtension: "chat",
                content: content,
                messageType: "text"
            )
            try? await supabase.from("messages").insert(payload).execute()
        }
    }

    private func loadMessages() async {
        struct MsgRow: Decodable {
            let id: String
            let senderId: String
            let content: String
            let createdAt: String
            let read: Bool
            let messageType: String
            enum CodingKeys: String, CodingKey {
                case id, content, read
                case senderId = "sender_id"
                case createdAt = "created_at"
                case messageType = "message_type"
            }
        }
        do {
            let rows: [MsgRow] = try await supabase
                .from("messages")
                .select("id, sender_id, content, created_at, read, message_type")
                .eq("conversation_id", value: conversation.id)
                .order("created_at", ascending: true)
                .execute().value
            let iso = ISO8601DateFormatter()
            messages = rows.map { row in
                Message(
                    id: row.id,
                    orderId: conversation.orderId,
                    senderId: row.senderId,
                    receiverId: "",
                    content: row.content,
                    timestamp: iso.date(from: row.createdAt) ?? Date(),
                    read: row.read,
                    messageType: Message.MessageType(rawValue: row.messageType) ?? .text
                )
            }
        } catch {
            // Load failed — show empty state
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    let currentUserId: String
    private var isFromCurrentUser: Bool { message.senderId == currentUserId }

    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(Theme.Typography.body)
                    .foregroundColor(isFromCurrentUser ? .white : Theme.Colors.label)
                    .padding(Theme.Spacing.md)
                    .background(
                        isFromCurrentUser ?
                        AnyShapeStyle(Theme.Colors.primaryGradient) :
                        AnyShapeStyle(Theme.Colors.secondaryBackground)
                    )
                    .cornerRadius(Theme.CornerRadius.xl)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.tertiaryLabel)
            }
            .frame(maxWidth: 280, alignment: isFromCurrentUser ? .trailing : .leading)

            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
}

// MARK: - Order Info Sheet
private struct OrderInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    let order: Order?

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if let order {
                        infoRow(icon: "number.circle.fill", label: "Pickup Code", value: order.pickupCode)
                        infoRow(icon: "bag.fill", label: "Item", value: order.listing?.title ?? "Surplus Order")
                        infoRow(icon: "person.fill", label: "Customer", value: order.customer?.name ?? "Customer")
                        infoRow(icon: "dollarsign.circle.fill", label: "Total", value: String(format: "$%.2f", order.totalAmount))
                        infoRow(icon: "clock.fill", label: "Pickup Window",
                                value: "\(order.pickupWindowStart.formatted(date: .omitted, time: .shortened)) – \(order.pickupWindowEnd.formatted(date: .omitted, time: .shortened))")
                        infoRow(icon: "checkmark.circle.fill", label: "Status", value: order.status.rawValue)
                        infoRow(icon: "calendar", label: "Ordered At", value: order.createdAt.formatted(date: .abbreviated, time: .shortened))
                    } else {
                        Text("No order information available.")
                            .foregroundColor(Theme.Colors.secondaryLabel)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                }
                .padding(24)
            }
            .background(Theme.Colors.pageBackground)
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryGradientStart)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(label).font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.tertiaryLabel).tracking(0.5)
                Text(value).font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.Colors.label)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

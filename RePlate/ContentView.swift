//
//  ContentView.swift
//  RePlate
//
//  Created by Jyotika Sadani on 5/26/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                Group {
                    if !appState.hasCompletedOnboarding {
                        OnboardingView()
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    } else if !appState.isAuthenticated {
                        AuthenticationView()
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    } else {
                        MainTabView()
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    }
                }
                .animation(.easeInOut(duration: 0.35), value: appState.isAuthenticated)
                .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
            }
        }
        .preferredColorScheme(appState.colorScheme.colorScheme)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.5)) { showSplash = false }
            }
        }
    }
}

// MARK: - Splash Screen
struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 24
    @State private var titleOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var triggerDing: Bool = false
    @State private var showRays: Bool = false

    var body: some View {
        ZStack {
            SplashBlobBackground()

            VStack(spacing: 22) {
                ZStack {
                    if showRays { DingRays() }

                    RePlateIconView(size: 180)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .keyframeAnimator(
                            initialValue: 0.0,
                            trigger: triggerDing
                        ) { content, angle in
                            content.rotationEffect(.degrees(angle))
                        } keyframes: { _ in
                            CubicKeyframe(0,   duration: 0.05)
                            CubicKeyframe(-8,  duration: 0.10)
                            CubicKeyframe(6,   duration: 0.10)
                            CubicKeyframe(-4,  duration: 0.09)
                            CubicKeyframe(2.5, duration: 0.09)
                            CubicKeyframe(0,   duration: 0.12)
                        }
                }

                Text("RePlate")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)

                Text("Rescue food. Save the planet.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.80))
                    .opacity(taglineOpacity)
            }
        }
        .onAppear {
            // Logo springs in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.58)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            // Ding wobble + rays after logo lands
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                triggerDing = true
                showRays   = true
            }
            // Title slides up
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.52)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
            // Tagline fades last
            withAnimation(.easeIn(duration: 0.4).delay(0.78)) {
                taglineOpacity = 1.0
            }
        }
    }
}

// MARK: - Ding Rays
private struct DingRays: View {
    @State private var radius: CGFloat = 18
    @State private var opacity: Double = 1.0
    @State private var length: CGFloat = 12

    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Capsule()
                    .fill(Color.white.opacity(0.90))
                    .frame(width: 2.5, height: length)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(i) * 45))
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                radius  = 90
                opacity = 0
                length  = 22
            }
        }
    }
}

// MARK: - Animated Blob Background
private struct SplashBlobBackground: View {
    @State private var phase = false

    var body: some View {
        ZStack {
            // Rich forest green base gradient
            LinearGradient(
                colors: [Theme.Colors.primaryDark, Theme.Colors.primaryGradientStart],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            // Blob 1 — teal burst
            Circle()
                .fill(Theme.Colors.primaryGradientEnd.opacity(0.70))
                .frame(width: 400)
                .blur(radius: 80)
                .offset(x: phase ? -55 : 70, y: phase ? -200 : -100)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: phase)

            // Blob 2 — lime accent glow
            Circle()
                .fill(Theme.Colors.accent.opacity(0.55))
                .frame(width: 320)
                .blur(radius: 75)
                .offset(x: phase ? 110 : -80, y: phase ? 140 : 250)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: phase)

            // Blob 3 — primary light shimmer
            Circle()
                .fill(Theme.Colors.primaryLight.opacity(0.60))
                .frame(width: 280)
                .blur(radius: 70)
                .offset(x: phase ? -120 : 90, y: phase ? 60 : -140)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true).delay(1), value: phase)

            // Blob 4 — deep dark contrast
            Circle()
                .fill(Theme.Colors.primaryDark.opacity(0.65))
                .frame(width: 240)
                .blur(radius: 65)
                .offset(x: phase ? 140 : -50, y: phase ? -90 : 170)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true).delay(0.5), value: phase)
        }
        .onAppear { phase = true }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            // Base background fills entire screen including safe areas, eliminating white bands
            Theme.Colors.pageBackground
                .ignoresSafeArea()

            TabView(selection: $appState.selectedTab) {
                // Home
                if appState.currentUser?.accountType == .restaurant {
                    RestaurantDashboardView()
                        .tag(AppState.Tab.home)
                } else {
                    HomeView()
                        .tag(AppState.Tab.home)
                }

                // Search / Insights
                if appState.currentUser?.accountType == .restaurant {
                    RestaurantInsightsView()
                        .tag(AppState.Tab.search)
                } else {
                    SearchView()
                        .tag(AppState.Tab.search)
                }

                // Orders
                if appState.currentUser?.accountType == .restaurant {
                    RestaurantOrdersView()
                        .tag(AppState.Tab.orders)
                } else {
                    OrdersView()
                        .tag(AppState.Tab.orders)
                }

                // Messages
                MessagesView()
                    .tag(AppState.Tab.messages)

                // Profile
                if appState.currentUser?.accountType == .restaurant {
                    RestaurantProfileView()
                        .tag(AppState.Tab.profile)
                } else {
                    ProfileView()
                        .tag(AppState.Tab.profile)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            // Extend TabView edge-to-edge so its frame doesn't leave grey strips
            // at the top (status bar) or bottom (home indicator) safe-area margins.
            .ignoresSafeArea()
            .background(Theme.Colors.pageBackground)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $appState.selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: AppState.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                    hapticFeedback(.light)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab ? tab.iconFilled : tab.icon)
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == tab ? Theme.Colors.primaryGradientStart : Theme.Colors.secondaryLabel)
                            .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)

                        Text(tab.rawValue)
                            .font(Theme.Typography.caption2)
                            .foregroundColor(selectedTab == tab ? Theme.Colors.primaryGradientStart : Theme.Colors.secondaryLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 18, y: -2)
        )
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

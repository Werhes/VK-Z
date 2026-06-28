import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var playerManager = AudioPlayerManager.shared
    @Namespace private var tabAnimation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                PlaylistsView()
                    .tag(0)
                
                MixView()
                    .tag(1)
                
                SearchView()
                    .tag(2)
                
                PlayerView()
                    .tag(3)
            }
            
            // Custom Tab Bar
            VStack(spacing: 0) {
                if playerManager.currentTrack != nil && selectedTab != 3 {
                    MiniPlayerView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 4)
                }
                
                customTabBar
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "square.stack",
                selectedIcon: "square.stack.fill",
                title: "Моя музыка",
                tag: 0,
                selectedTab: $selectedTab,
                namespace: tabAnimation
            )
            
            TabBarButton(
                icon: "waveform.circle",
                selectedIcon: "waveform.circle.fill",
                title: "Микс",
                tag: 1,
                selectedTab: $selectedTab,
                namespace: tabAnimation
            )
            
            TabBarButton(
                icon: "magnifyingglass.circle",
                selectedIcon: "magnifyingglass.circle.fill",
                title: "Поиск",
                tag: 2,
                selectedTab: $selectedTab,
                namespace: tabAnimation
            )
            
            TabBarButton(
                icon: "play.circle",
                selectedIcon: "play.circle.fill",
                title: "Сейчас",
                tag: 3,
                selectedTab: $selectedTab,
                namespace: tabAnimation
            )
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 34)
        .background(
            ZStack {
                Color.black.opacity(0.7)
                AppColors.glassGradient
            }
        )
        .background(.ultraThinMaterial)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let selectedIcon: String
    let title: String
    let tag: Int
    @Binding var selectedTab: Int
    let namespace: Namespace.ID
    
    var isSelected: Bool { selectedTab == tag }
    
    var body: some View {
        Button(action: {
            withAnimation(AppAnimation.spring) {
                selectedTab = tag
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(AppColors.primaryGradient)
                            .frame(width: 38, height: 38)
                            .matchedGeometryEffect(id: "tab_bg", in: namespace)
                    }
                    
                    Image(systemName: isSelected ? selectedIcon : icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                }
                .frame(width: 44, height: 38)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mini Player
struct MiniPlayerView: View {
    @StateObject private var player = AudioPlayerManager.shared
    @State private var showFullPlayer = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.surfaceLight)
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(AppColors.primaryGradient)
                        .frame(width: geometry.size.width * CGFloat(player.duration > 0 ? player.currentTime / player.duration : 0), height: 3)
                }
            }
            .frame(height: 3)
            
            Button(action: { showFullPlayer = true }) {
                HStack(spacing: 12) {
                    // Cover art
                    AsyncImage(url: player.currentTrack?.coverUrl) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            ZStack {
                                AppColors.surfaceLight
                                Image(systemName: "music.note")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        case .empty:
                            ZStack {
                                AppColors.surfaceLight
                                ProgressView()
                                    .tint(AppColors.textSecondary)
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 48, height: 48)
                    .cornerRadius(12)
                    
                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.currentTrack?.title ?? "")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(player.currentTrack?.artist ?? "")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Controls
                    HStack(spacing: 4) {
                        Button(action: { player.togglePlayPause() }) {
                            Image(systemName: player.playerState == .playing ? "pause.fill" : "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(AppColors.surfaceLight)
                                .clipShape(Circle())
                        }
                        
                        Button(action: { player.nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(width: 40, height: 44)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        Color.black.opacity(0.6)
                        AppColors.glassGradient
                    }
                )
                .background(.ultraThinMaterial)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .fullScreenCover(isPresented: $showFullPlayer) {
            PlayerView()
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
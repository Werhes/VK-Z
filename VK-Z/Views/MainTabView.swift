import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var playerManager = AudioPlayerManager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                PlaylistsView()
                    .tabItem {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == 0 ? "square.stack.fill" : "square.stack")
                                .font(.system(size: 20))
                            Text("Моя музыка")
                                .font(.custom("VKSansDisplay-Regular", size: 10))
                        }
                    }
                    .tag(0)
                
                MixView()
                    .tabItem {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == 1 ? "waveform.circle.fill" : "waveform.circle")
                                .font(.system(size: 20))
                            Text("Микс")
                                .font(.custom("VKSansDisplay-Regular", size: 10))
                        }
                    }
                    .tag(1)
                
                SearchView()
                    .tabItem {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == 2 ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                                .font(.system(size: 20))
                            Text("Поиск")
                                .font(.custom("VKSansDisplay-Regular", size: 10))
                        }
                    }
                    .tag(2)
                
                PlayerView()
                    .tabItem {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == 3 ? "play.circle.fill" : "play.circle")
                                .font(.system(size: 20))
                            Text("Сейчас")
                                .font(.custom("VKSansDisplay-Regular", size: 10))
                        }
                    }
                    .tag(3)
            }
            .tint(.blue)
            .background(Color.vkBackground)
            
            // Mini Player
            if playerManager.currentTrack != nil && selectedTab != 3 {
                MiniPlayerView()
                    .transition(.move(edge: .bottom))
                    .padding(.bottom, 49)
            }
        }
    }
}

// MARK: - Mini Player
struct MiniPlayerView: View {
    @StateObject private var player = AudioPlayerManager.shared
    @State private var showFullPlayer = false
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            Button(action: { showFullPlayer = true }) {
                HStack(spacing: 12) {
                    AsyncImage(url: player.currentTrack?.coverUrl) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "music.note")
                                .font(.title3)
                                .foregroundColor(.gray)
                        case .empty:
                            ProgressView()
                                .tint(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 44, height: 44)
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.currentTrack?.title ?? "")
                            .font(.custom("VKSansDisplay-Medium", size: 14))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(player.currentTrack?.artist ?? "")
                            .font(.custom("VKSansDisplay-Regular", size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: { player.togglePlayPause() }) {
                        Image(systemName: player.playerState == .playing ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }
                    
                    Button(action: { player.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.vkCardBackground)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .fullScreenCover(isPresented: $showFullPlayer) {
            PlayerView()
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static let vkBackground = Color(red: 0.05, green: 0.07, blue: 0.12)
    static let vkCardBackground = Color(red: 0.10, green: 0.13, blue: 0.20)
    static let vkSurface = Color(red: 0.15, green: 0.18, blue: 0.25)
    static let vkAccent = Color.blue
    static let vkTextPrimary = Color.white
    static let vkTextSecondary = Color.gray
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
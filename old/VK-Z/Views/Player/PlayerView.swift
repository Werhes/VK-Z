import SwiftUI

// MARK: - VK Mix Button Action
private func createMixFromCurrentTrack() {
    guard let track = AudioPlayerManager.shared.currentTrack else { return }
    
    VKApiService.shared.createMix(trackId: track.id, ownerId: track.ownerId) { result in
        DispatchQueue.main.async {
            switch result {
            case .success(let tracks):
                AudioPlayerManager.shared.setQueue(tracks: tracks)
            case .failure:
                break
            }
        }
    }
}

// MARK: - Full Screen Player View
struct PlayerView: View {
    @StateObject private var player = AudioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGFloat = 0
    @State private var showQueue = false
    @State private var isCoverAnimating = false
    @State private var coverScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Animated background
            AppColors.background.ignoresSafeArea()
            
            // Background blur from cover art
            if let track = player.currentTrack {
                AsyncImage(url: track.coverUrl) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 80)
                            .opacity(0.3)
                            .ignoresSafeArea()
                    }
                }
            }
            
            if let track = player.currentTrack {
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Сейчас играет")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Cover Art
                    coverArtView(track: track)
                    
                    Spacer()
                    
                    // Track Info
                    trackInfoView(track: track)
                    
                    // Progress Bar
                    progressBarView
                        .padding(.top, 8)
                    
                    // Controls
                    controlsView
                        .padding(.top, 16)
                    
                    // Bottom Controls
                    bottomControlsView
                        .padding(.top, 12)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 { dragOffset = value.translation.height }
                        }
                        .onEnded { value in
                            if value.translation.height > 150 { dismiss() }
                            else { withAnimation(AppAnimation.spring) { dragOffset = 0 } }
                        }
                )
            } else {
                emptyPlayerView
            }
        }
        .overlay(alignment: .bottom) {
            if showQueue {
                queueView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: player.playerState) { _, newState in
            withAnimation(AppAnimation.smooth) {
                isCoverAnimating = newState == .playing
            }
        }
    }
    
    private func coverArtView(track: VKTrack) -> some View {
        ZStack {
            AsyncImage(url: track.coverUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(isCoverAnimating ? 1.0 : 0.95)
                case .failure:
                    ZStack {
                        AppColors.surfaceLight
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
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
            .frame(width: 320, height: 320)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.5), radius: 30, y: 15)
            .scaleEffect(coverScale)
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        coverScale = min(max(scale, 0.8), 1.2)
                    }
                    .onEnded { _ in
                        withAnimation(AppAnimation.spring) {
                            coverScale = 1.0
                        }
                    }
            )
        }
    }
    
    private func trackInfoView(track: VKTrack) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(track.title)
                    .font(.custom("VKSansDisplay-Bold", size: 24))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.custom("VKSansDisplay-Medium", size: 17))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                
                // VK Mix Button
                Button(action: { createMixFromCurrentTrack() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.system(size: 12))
                        Text("Создать микс")
                            .font(.custom("VKSansDisplay-Medium", size: 13))
                    }
                    .foregroundColor(AppColors.accentPurple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AppColors.accentPurple.opacity(0.12))
                    .cornerRadius(10)
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.textSecondary)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding(.top, 20)
    }
    
    private var progressBarView: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.surfaceLight)
                    .frame(height: 5)
                
                Capsule()
                    .fill(AppColors.primaryGradient)
                    .frame(
                        width: max(CGFloat(player.duration > 0 ? player.currentTime / player.duration : 0) * (UIScreen.main.bounds.width - 48), 0),
                        height: 5
                    )
            }
            .overlay(
                // Slider overlay for interaction
                Slider(
                    value: Binding(
                        get: { player.currentTime },
                        set: { player.seek(to: $0) }
                    ),
                    in: 0...max(player.duration, 1)
                )
                .tint(.clear)
                .background(Capsule().fill(.clear).frame(height: 5))
            )
            
            HStack {
                Text(formatTime(player.currentTime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
                Text(formatTime(player.duration))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
    
    private var controlsView: some View {
        HStack(spacing: 28) {
            Button(action: { player.toggleShuffle() }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 20))
                    .foregroundColor(player.isShuffled ? AppColors.accentBlue : AppColors.textSecondary)
            }
            
            Button(action: { player.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }
            
            Button(action: { player.togglePlayPause() }) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 76, height: 76)
                        .shadow(color: .white.opacity(0.2), radius: 15, y: 5)
                    
                    Image(systemName: player.playerState == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                        .offset(x: player.playerState == .playing ? 0 : 2)
                }
            }
            
            Button(action: { player.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }
            
            Button(action: { player.toggleRepeatMode() }) {
                ZStack {
                    Image(systemName: "repeat")
                        .font(.system(size: 20))
                        .foregroundColor(player.repeatMode != .off ? AppColors.accentBlue : AppColors.textSecondary)
                    if player.repeatMode == .one {
                        Text("1")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(AppColors.accentBlue)
                            .offset(y: 6)
                    }
                }
            }
        }
    }
    
    private var bottomControlsView: some View {
        HStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.surfaceLight)
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(AppColors.primaryGradient)
                        .frame(width: CGFloat(player.volume) * 120, height: 4)
                }
                .frame(width: 120)
                .overlay(
                    Slider(
                        value: Binding(
                            get: { player.volume },
                            set: { player.setVolume($0) }
                        ),
                        in: 0...1
                    )
                    .tint(.clear)
                )
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            
            Button(action: { withAnimation(AppAnimation.spring) { showQueue.toggle() } }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18))
                    .foregroundColor(showQueue ? AppColors.accentBlue : AppColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.surfaceLight)
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 20)
    }
    
    private var queueView: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(AppColors.textTertiary)
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            HStack {
                Text("Очередь")
                    .font(.custom("VKSansDisplay-Bold", size: 20))
                    .foregroundColor(.white)
                Spacer()
                Text("\(player.queue.count) треков")
                    .font(.custom("VKSansDisplay-Regular", size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(player.queue.enumerated()), id: \.element.id) { index, track in
                        HStack(spacing: 12) {
                            AsyncImage(url: track.coverUrl) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    ZStack {
                                        AppColors.surfaceLight
                                        Image(systemName: "music.note")
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
                            .frame(width: 44, height: 44)
                            .cornerRadius(10)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(track.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(index == player.currentIndex ? AppColors.accentBlue : .white)
                                    .lineLimit(1)
                                Text(track.artist)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if index == player.currentIndex {
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.caption)
                                    .foregroundColor(AppColors.accentBlue)
                            }
                            
                            Button(action: { player.removeFromQueue(at: index) }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        
                        if index < player.queue.count - 1 {
                            Divider()
                                .background(AppColors.surfaceLight)
                                .padding(.leading, 76)
                        }
                    }
                }
            }
        }
        .frame(height: 380)
        .background(
            ZStack {
                Color.black.opacity(0.8)
                AppColors.glassGradient
            }
        )
        .background(.ultraThinMaterial)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }
    
    private var emptyPlayerView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.surfaceLight)
                    .frame(width: 140, height: 140)
                
                Image(systemName: "music.note")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.textTertiary)
            }
            
            VStack(spacing: 8) {
                Text("Ничего не играет")
                    .font(.custom("VKSansDisplay-Bold", size: 24))
                    .foregroundColor(.white)
                
                Text("Выберите трек из плейлиста\nили найдите через поиск")
                    .font(.custom("VKSansDisplay-Regular", size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    PlayerView()
        .preferredColorScheme(.dark)
}
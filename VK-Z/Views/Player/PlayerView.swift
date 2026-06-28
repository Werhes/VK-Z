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
    
    var body: some View {
        ZStack {
            Color.vkBackground.ignoresSafeArea()
            
            if let track = player.currentTrack {
                VStack(spacing: 0) {
                    dragHandle
                    Spacer()
                    coverArtView(track: track)
                    Spacer()
                    trackInfoView(track: track)
                    progressBarView
                    controlsView
                    bottomControlsView
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
                            else { withAnimation(.spring()) { dragOffset = 0 } }
                        }
                )
            } else {
                emptyPlayerView
            }
        }
        .overlay(alignment: .bottom) {
            if showQueue {
                queueView.transition(.move(edge: .bottom))
            }
        }
    }
    
    private var dragHandle: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
        }
    }
    
    private func coverArtView(track: VKTrack) -> some View {
        AsyncImage(url: track.coverUrl) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .failure:
                ZStack {
                    Color.vkSurface
                    Image(systemName: "music.note").font(.system(size: 60)).foregroundColor(.gray)
                }
            case .empty:
                ZStack {
                    Color.vkSurface
                    ProgressView().tint(.gray)
                }
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 300, height: 300)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
    }
    
    private func trackInfoView(track: VKTrack) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.custom("VKSansDisplay-Bold", size: 22))
                    .foregroundColor(.white).lineLimit(1)
                Text(track.artist)
                    .font(.custom("VKSansDisplay-Medium", size: 16))
                    .foregroundColor(.gray).lineLimit(1)
                
                // VK Mix Button
                Button(action: { createMixFromCurrentTrack() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.system(size: 12))
                        Text("Создать микс")
                            .font(.custom("VKSansDisplay-Medium", size: 13))
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.15))
                    .cornerRadius(8)
                }
                .padding(.top, 4)
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2).foregroundColor(.gray)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding(.top, 24)
    }
    
    private var progressBarView: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.seek(to: $0) }
                ),
                in: 0...max(player.duration, 1)
            )
            .tint(.white)
            .background(Capsule().fill(Color.white.opacity(0.2)).frame(height: 4))
            
            HStack {
                Text(formatTime(player.currentTime))
                    .font(.custom("VKSansDisplay-Regular", size: 12)).foregroundColor(.gray)
                Spacer()
                Text(formatTime(player.duration))
                    .font(.custom("VKSansDisplay-Regular", size: 12)).foregroundColor(.gray)
            }
        }
        .padding(.top, 16)
    }
    
    private var controlsView: some View {
        HStack(spacing: 32) {
            Button(action: { player.toggleShuffle() }) {
                Image(systemName: "shuffle")
                    .font(.title2)
                    .foregroundColor(player.isShuffled ? .blue : .gray)
            }
            
            Button(action: { player.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28)).foregroundColor(.white)
            }
            
            Button(action: { player.togglePlayPause() }) {
                ZStack {
                    Circle().fill(Color.white).frame(width: 72, height: 72)
                    Image(systemName: player.playerState == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 30)).foregroundColor(.black)
                        .offset(x: player.playerState == .playing ? 0 : 2)
                }
            }
            
            Button(action: { player.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28)).foregroundColor(.white)
            }
            
            Button(action: { player.toggleRepeatMode() }) {
                ZStack {
                    Image(systemName: "repeat")
                        .font(.title2)
                        .foregroundColor(player.repeatMode != .off ? .blue : .gray)
                    if player.repeatMode == .one {
                        Text("1")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.blue).offset(y: 6)
                    }
                }
            }
        }
        .padding(.top, 20)
    }
    
    private var bottomControlsView: some View {
        HStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill").font(.caption).foregroundColor(.gray)
                Slider(
                    value: Binding(
                        get: { player.volume },
                        set: { player.setVolume($0) }
                    ),
                    in: 0...1
                )
                .tint(.white)
                Image(systemName: "speaker.wave.3.fill").font(.caption).foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            
            Button(action: { withAnimation { showQueue.toggle() } }) {
                Image(systemName: "list.bullet")
                    .font(.title3)
                    .foregroundColor(showQueue ? .blue : .gray)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 40)
    }
    
    private var queueView: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.5)).frame(width: 40, height: 5).padding(.top, 12)
            
            HStack {
                Text("Очередь")
                    .font(.custom("VKSansDisplay-Bold", size: 18)).foregroundColor(.white)
                Spacer()
                Text("\(player.queue.count) треков")
                    .font(.custom("VKSansDisplay-Regular", size: 13)).foregroundColor(.gray)
            }
            .padding(.horizontal, 20).padding(.top, 16)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(player.queue.enumerated()), id: \.element.id) { index, track in
                        HStack(spacing: 12) {
                            AsyncImage(url: track.coverUrl) { phase in
                                switch phase {
                                case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                                case .failure:
                                    ZStack {
                                        Color.vkSurface
                                        Image(systemName: "music.note").foregroundColor(.gray)
                                    }
                                case .empty:
                                    ZStack {
                                        Color.vkSurface
                                        ProgressView().tint(.gray)
                                    }
                                @unknown default: EmptyView()
                                }
                            }
                            .frame(width: 40, height: 40).cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(.custom("VKSansDisplay-Medium", size: 14))
                                    .foregroundColor(index == player.currentIndex ? .blue : .white).lineLimit(1)
                                Text(track.artist)
                                    .font(.custom("VKSansDisplay-Regular", size: 12))
                                    .foregroundColor(.gray).lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if index == player.currentIndex {
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.caption).foregroundColor(.blue)
                            }
                            
                            Button(action: { player.removeFromQueue(at: index) }) {
                                Image(systemName: "xmark").font(.caption).foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        
                        if index < player.queue.count - 1 {
                            Divider().background(Color.white.opacity(0.05)).padding(.leading, 72)
                        }
                    }
                }
            }
        }
        .frame(height: 350)
        .background(Color.vkCardBackground)
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }
    
    private var emptyPlayerView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "music.note").font(.system(size: 80)).foregroundColor(.gray.opacity(0.3))
            Text("Ничего не играет")
                .font(.custom("VKSansDisplay-Bold", size: 22)).foregroundColor(.white)
            Text("Выберите трек из плейлиста\nили найдите через поиск")
                .font(.custom("VKSansDisplay-Regular", size: 15))
                .foregroundColor(.gray).multilineTextAlignment(.center).lineSpacing(4)
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
    PlayerView().preferredColorScheme(.dark)
}
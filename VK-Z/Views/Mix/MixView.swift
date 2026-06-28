import SwiftUI

// MARK: - VK Mix View
struct MixView: View {
    @StateObject private var viewModel = MixViewModel()
    @State private var selectedMix: VKMix?
    @State private var showMixDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerView
                    
                    if viewModel.isLoading && viewModel.mixes.isEmpty {
                        loadingView
                    } else if viewModel.mixes.isEmpty {
                        emptyStateView
                    } else {
                        mixesGrid
                    }
                }
                .padding(.bottom, 120)
            }
            .background(AppColors.background)
            .refreshable { viewModel.loadMixes() }
            .navigationDestination(isPresented: $showMixDetail) {
                if let mix = selectedMix {
                    MixDetailView(mix: mix)
                }
            }
        }
        .onAppear { viewModel.loadMixes() }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGradient)
                        .frame(width: 44, height: 44)
                        .shadow(color: AppColors.accentPurple.opacity(0.4), radius: 10, y: 4)
                    
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("VK Микс")
                        .font(.custom("VKSansDisplay-Bold", size: 34))
                        .foregroundColor(.white)
                    
                    Text("Персональные подборки на основе ваших треков")
                        .font(.custom("VKSansDisplay-Regular", size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<4) { _ in
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.surfaceLight)
                        .frame(width: 120, height: 120)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.surfaceLight)
                            .frame(width: 140, height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.surfaceLight)
                            .frame(width: 100, height: 12)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.surfaceLight)
                            .frame(width: 180, height: 12)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accentPurple.opacity(0.2), AppColors.accentBlue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColors.primaryGradient)
            }
            
            VStack(spacing: 8) {
                Text("Миксы скоро появятся")
                    .font(.custom("VKSansDisplay-Bold", size: 22))
                    .foregroundColor(.white)
                
                Text("Слушайте музыку, чтобы мы могли\nсоздавать для вас персональные подборки")
                    .font(.custom("VKSansDisplay-Regular", size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button(action: { viewModel.loadMixes() }) {
                Text("Обновить")
                    .font(.custom("VKSansDisplay-Medium", size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(AppColors.primaryGradient)
                    .cornerRadius(14)
                    .shadow(color: AppColors.accentBlue.opacity(0.3), radius: 10, y: 4)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var mixesGrid: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.mixes) { mix in
                MixCardView(mix: mix)
                    .onTapGesture {
                        selectedMix = mix
                        showMixDetail = true
                    }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Mix Card
struct MixCardView: View {
    let mix: VKMix
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Cover
            ZStack {
                AsyncImage(url: mix.displayCover) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(AppColors.primaryGradient)
                            Image(systemName: "waveform")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(AppColors.surfaceLight)
                            ProgressView()
                                .tint(AppColors.textSecondary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .frame(width: 110, height: 110)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(mix.title)
                    .font(.custom("VKSansDisplay-Bold", size: 17))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let subtitle = mix.subtitle {
                    Text(subtitle)
                        .font(.custom("VKSansDisplay-Regular", size: 13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
                
                if let artists = mix.artists, !artists.isEmpty {
                    Text(artists.joined(separator: ", "))
                        .font(.custom("VKSansDisplay-Regular", size: 12))
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                }
                
                if let count = mix.trackCount {
                    HStack(spacing: 4) {
                        Image(systemName: "music.note")
                            .font(.system(size: 10))
                        Text("\(count) треков")
                            .font(.custom("VKSansDisplay-Regular", size: 12))
                    }
                    .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(AppAnimation.spring, value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: { })
    }
}

// MARK: - Mix Detail View
struct MixDetailView: View {
    let mix: VKMix
    @StateObject private var viewModel = MixViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var tracks: [VKTrack] = []
    @State private var isLoading = true
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(spacing: 20) {
                    ZStack {
                        AsyncImage(url: mix.displayCover) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                ZStack {
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(AppColors.primaryGradient)
                                    Image(systemName: "waveform")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            case .empty:
                                ZStack {
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(AppColors.surfaceLight)
                                    ProgressView()
                                        .tint(AppColors.textSecondary)
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    .frame(width: 220, height: 220)
                    .cornerRadius(24)
                    .shadow(color: AppColors.accentPurple.opacity(0.3), radius: 25, y: 12)
                    
                    VStack(spacing: 6) {
                        Text(mix.title)
                            .font(.custom("VKSansDisplay-Bold", size: 26))
                            .foregroundColor(.white)
                        
                        if let subtitle = mix.subtitle {
                            Text(subtitle)
                                .font(.custom("VKSansDisplay-Regular", size: 14))
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        if let desc = mix.description {
                            Text(desc)
                                .font(.custom("VKSansDisplay-Regular", size: 13))
                                .foregroundColor(AppColors.textTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    // Play button
                    Button(action: {
                        viewModel.playMix(mix, tracks: tracks)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                            Text("Слушать микс")
                                .font(.custom("VKSansDisplay-Medium", size: 16))
                        }
                        .accentButtonStyle()
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                // Tracks
                if isLoading {
                    VStack(spacing: 12) {
                        ForEach(0..<5) { _ in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppColors.surfaceLight)
                                    .frame(width: 44, height: 44)
                                VStack(alignment: .leading, spacing: 6) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppColors.surfaceLight)
                                        .frame(width: 160, height: 12)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppColors.surfaceLight)
                                        .frame(width: 100, height: 10)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                } else if !tracks.isEmpty {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                            TrackRowView(track: track, index: index + 1)
                                .onTapGesture { viewModel.playTrack(track) }
                            if index < tracks.count - 1 {
                                Divider()
                                    .background(AppColors.surfaceLight)
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background(AppColors.cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Назад")
                    }
                    .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .onAppear {
            loadTracks()
        }
    }
    
    private func loadTracks() {
        guard tracks.isEmpty else { return }
        
        if let mixTracks = mix.tracks, !mixTracks.isEmpty {
            tracks = mixTracks
            isLoading = false
            return
        }
        
        VKApiService.shared.getMixTracks(mixId: mix.id) { result in
            DispatchQueue.main.async {
                isLoading = false
                if case .success(let loadedTracks) = result {
                    tracks = loadedTracks
                }
            }
        }
    }
}

// MARK: - ViewModel
final class MixViewModel: ObservableObject {
    @Published var mixes: [VKMix] = []
    @Published var isLoading = false
    
    private let api = VKApiService.shared
    private let player = AudioPlayerManager.shared
    
    func loadMixes() {
        isLoading = true
        
        api.getMixes { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if case .success(let mixes) = result {
                    self?.mixes = mixes
                }
            }
        }
    }
    
    func playTrack(_ track: VKTrack) {
        player.setQueue(tracks: [track])
    }
    
    func playMix(_ mix: VKMix, tracks: [VKTrack]) {
        guard !tracks.isEmpty else { return }
        player.setQueue(tracks: tracks)
    }
}

#Preview {
    MixView()
        .preferredColorScheme(.dark)
}
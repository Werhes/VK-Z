import SwiftUI

// MARK: - VK Mix View
struct MixView: View {
    @StateObject private var viewModel = MixViewModel()
    @State private var selectedMix: VKMix?
    @State private var showMixDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerView
                    
                    if viewModel.isLoading && viewModel.mixes.isEmpty {
                        loadingView
                    } else if viewModel.mixes.isEmpty {
                        emptyStateView
                    } else {
                        mixesGrid
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color.vkBackground)
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
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Text("VK Микс")
                    .font(.custom("VKSansDisplay-Bold", size: 34))
                    .foregroundColor(.white)
            }
            
            Text("Персональные подборки на основе ваших треков")
                .font(.custom("VKSansDisplay-Regular", size: 14))
                .foregroundColor(.gray)
                .padding(.top, 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<4) { _ in
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.vkSurface)
                        .frame(width: 120, height: 120)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.vkSurface)
                            .frame(width: 140, height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.vkSurface)
                            .frame(width: 100, height: 12)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.vkSurface)
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
        VStack(spacing: 20) {
            Spacer().frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            
            Text("Миксы скоро появятся")
                .font(.custom("VKSansDisplay-Bold", size: 20))
                .foregroundColor(.white)
            
            Text("Слушайте музыку, чтобы мы могли\nсоздавать для вас персональные подборки")
                .font(.custom("VKSansDisplay-Regular", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Button(action: { viewModel.loadMixes() }) {
                Text("Обновить")
                    .font(.custom("VKSansDisplay-Medium", size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(12)
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
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Image(systemName: "waveform")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.vkSurface)
                            ProgressView().tint(.gray)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .frame(width: 100, height: 100)
            .cornerRadius(16)
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(mix.title)
                    .font(.custom("VKSansDisplay-Bold", size: 17))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let subtitle = mix.subtitle {
                    Text(subtitle)
                        .font(.custom("VKSansDisplay-Regular", size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                if let artists = mix.artists, !artists.isEmpty {
                    Text(artists.joined(separator: ", "))
                        .font(.custom("VKSansDisplay-Regular", size: 12))
                        .foregroundColor(.gray.opacity(0.7))
                        .lineLimit(1)
                }
                
                if let count = mix.trackCount {
                    Text("\(count) треков")
                        .font(.custom("VKSansDisplay-Regular", size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color.vkCardBackground)
        .cornerRadius(20)
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
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        AsyncImage(url: mix.displayCover) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [.purple, .blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Image(systemName: "waveform")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            case .empty:
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.vkSurface)
                                    ProgressView().tint(.gray)
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    .frame(width: 200, height: 200)
                    .cornerRadius(20)
                    .shadow(color: .purple.opacity(0.3), radius: 20, y: 10)
                    
                    Text(mix.title)
                        .font(.custom("VKSansDisplay-Bold", size: 24))
                        .foregroundColor(.white)
                    
                    if let subtitle = mix.subtitle {
                        Text(subtitle)
                            .font(.custom("VKSansDisplay-Regular", size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let desc = mix.description {
                        Text(desc)
                            .font(.custom("VKSansDisplay-Regular", size: 13))
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Play button
                    Button(action: {
                        viewModel.playMix(mix, tracks: tracks)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Слушать микс")
                                .font(.custom("VKSansDisplay-Medium", size: 16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                // Tracks
                if isLoading {
                    VStack(spacing: 12) {
                        ForEach(0..<5) { _ in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 8).fill(Color.vkSurface).frame(width: 44, height: 44)
                                VStack(alignment: .leading, spacing: 6) {
                                    RoundedRectangle(cornerRadius: 4).fill(Color.vkSurface).frame(width: 160, height: 12)
                                    RoundedRectangle(cornerRadius: 4).fill(Color.vkSurface).frame(width: 100, height: 10)
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
                                Divider().background(Color.white.opacity(0.05)).padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color.vkCardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(Color.vkBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left").foregroundColor(.white)
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
    MixView().preferredColorScheme(.dark)
}
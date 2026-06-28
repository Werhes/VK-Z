import SwiftUI

// MARK: - Playlists View (Главный экран)
struct PlaylistsView: View {
    @StateObject private var viewModel = PlaylistsViewModel()
    @State private var selectedPlaylist: VKPlaylist?
    @State private var showPlaylistDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    headerView
                    
                    if viewModel.isLoading && viewModel.playlists.isEmpty {
                        loadingView
                    } else {
                        if !viewModel.recommendations.isEmpty {
                            sectionView(
                                title: "Для вас",
                                subtitle: "Рекомендации на основе ваших треков",
                                items: viewModel.recommendations
                            ) { track in
                                viewModel.playTrack(track)
                            }
                        }
                        
                        if !viewModel.popular.isEmpty {
                            popularSection
                        }
                        
                        if !viewModel.playlists.isEmpty {
                            playlistsGrid
                        }
                        
                        if !viewModel.recentTracks.isEmpty {
                            sectionView(
                                title: "Недавно добавленные",
                                subtitle: "Последние добавленные треки",
                                items: viewModel.recentTracks
                            ) { track in
                                viewModel.playTrack(track)
                            }
                        }
                    }
                }
                .padding(.bottom, 120)
            }
            .background(AppColors.background)
            .refreshable { viewModel.loadData() }
            .navigationDestination(isPresented: $showPlaylistDetail) {
                if let playlist = selectedPlaylist {
                    PlaylistDetailView(playlist: playlist)
                }
            }
        }
        .onAppear { viewModel.loadData() }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGradient)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Моя музыка")
                        .font(.custom("VKSansDisplay-Bold", size: 34))
                        .foregroundColor(.white)
                    
                    Text("\(viewModel.totalTracks) треков")
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
            ForEach(0..<5) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.surfaceLight)
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.surfaceLight)
                            .frame(width: 150, height: 14)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.surfaceLight)
                            .frame(width: 100, height: 12)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
    }
    
    private func sectionView(title: String, subtitle: String? = nil, items: [VKTrack], onTap: @escaping (VKTrack) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("VKSansDisplay-Bold", size: 22))
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.custom("VKSansDisplay-Regular", size: 13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button("Все") { }
                    .font(.custom("VKSansDisplay-Medium", size: 14))
                    .foregroundColor(AppColors.accentBlue)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(items) { track in
                        TrackCardView(track: track)
                            .onTapGesture { onTap(track) }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Популярное")
                        .font(.custom("VKSansDisplay-Bold", size: 22))
                        .foregroundColor(.white)
                    
                    Text("Что слушают другие")
                        .font(.custom("VKSansDisplay-Regular", size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Button("Все") { }
                    .font(.custom("VKSansDisplay-Medium", size: 14))
                    .foregroundColor(AppColors.accentBlue)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.popular) { track in
                        TrackCardView(track: track)
                            .onTapGesture { viewModel.playTrack(track) }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var playlistsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Плейлисты")
                        .font(.custom("VKSansDisplay-Bold", size: 22))
                        .foregroundColor(.white)
                    
                    Text("Ваши подборки")
                        .font(.custom("VKSansDisplay-Regular", size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Button("Все") { }
                    .font(.custom("VKSansDisplay-Medium", size: 14))
                    .foregroundColor(AppColors.accentBlue)
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 14
            ) {
                ForEach(viewModel.playlists.prefix(6)) { playlist in
                    PlaylistCardView(playlist: playlist)
                        .onTapGesture {
                            selectedPlaylist = playlist
                            showPlaylistDetail = true
                        }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Track Card
struct TrackCardView: View {
    let track: VKTrack
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
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
                                .font(.title2)
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
                .frame(width: 160, height: 160)
                .cornerRadius(16)
                
                // Play button overlay
                Circle()
                    .fill(AppColors.primaryGradient)
                    .frame(width: 36, height: 36)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
                    .offset(x: -8, y: -8)
                    .opacity(isPressed ? 1.0 : 0.0)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 160)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(AppAnimation.spring, value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: { })
    }
}

// MARK: - Playlist Card
struct PlaylistCardView: View {
    let playlist: VKPlaylist
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: playlist.coverUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ZStack {
                            AppColors.surfaceLight
                            Image(systemName: "music.note.list")
                                .font(.title2)
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
                .frame(height: 170)
                .cornerRadius(16)
                
                // Play button overlay
                Circle()
                    .fill(AppColors.primaryGradient)
                    .frame(width: 36, height: 36)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
                    .offset(x: -8, y: -8)
                    .opacity(isPressed ? 1.0 : 0.0)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(playlist.trackCount) треков")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 4)
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(AppAnimation.spring, value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: { })
    }
}

// MARK: - Playlist Detail
struct PlaylistDetailView: View {
    let playlist: VKPlaylist
    @StateObject private var viewModel = PlaylistsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(spacing: 20) {
                    ZStack(alignment: .bottomTrailing) {
                        AsyncImage(url: playlist.coverUrl) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                ZStack {
                                    AppColors.surfaceLight
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 40))
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
                        .frame(width: 200, height: 200)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
                    }
                    
                    VStack(spacing: 6) {
                        Text(playlist.title)
                            .font(.custom("VKSansDisplay-Bold", size: 26))
                            .foregroundColor(.white)
                        
                        if let desc = playlist.description {
                            Text(desc)
                                .font(.custom("VKSansDisplay-Regular", size: 14))
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Text("\(playlist.trackCount) треков")
                            .font(.custom("VKSansDisplay-Regular", size: 13))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Button(action: { viewModel.playPlaylist(playlist) }) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                            Text("Слушать все")
                                .font(.custom("VKSansDisplay-Medium", size: 16))
                        }
                        .accentButtonStyle()
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                if let tracks = playlist.tracks {
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
    }
}

// MARK: - Track Row
struct TrackRowView: View {
    let track: VKTrack
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppColors.textTertiary)
                .frame(width: 24)
            
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
            .frame(width: 44, height: 44)
            .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(track.formattedDuration)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppColors.textTertiary)
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.leading, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.cardBackground)
    }
}

// MARK: - ViewModel
final class PlaylistsViewModel: ObservableObject {
    @Published var playlists: [VKPlaylist] = []
    @Published var recommendations: [VKTrack] = []
    @Published var popular: [VKTrack] = []
    @Published var recentTracks: [VKTrack] = []
    @Published var isLoading = false
    @Published var totalTracks = 0
    
    private let api = VKApiService.shared
    private let player = AudioPlayerManager.shared
    
    func loadData() {
        isLoading = true
        let group = DispatchGroup()
        
        group.enter()
        api.getPlaylists { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let playlists) = result { self?.playlists = playlists }
                group.leave()
            }
        }
        
        group.enter()
        api.getRecommendations { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let tracks) = result { self?.recommendations = Array(tracks.prefix(10)) }
                group.leave()
            }
        }
        
        group.enter()
        api.getPopular { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let tracks) = result { self?.popular = Array(tracks.prefix(10)) }
                group.leave()
            }
        }
        
        group.enter()
        api.getAudio { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let tracks) = result {
                    self?.recentTracks = Array(tracks.prefix(10))
                    self?.totalTracks = tracks.count
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
    
    func playTrack(_ track: VKTrack) {
        player.setQueue(tracks: [track])
    }
    
    func playPlaylist(_ playlist: VKPlaylist) {
        guard let tracks = playlist.tracks else { return }
        player.setQueue(tracks: tracks)
    }
}

#Preview {
    PlaylistsView()
        .preferredColorScheme(.dark)
}
import SwiftUI

// MARK: - Playlists View (Главный экран)
struct PlaylistsView: View {
    @StateObject private var viewModel = PlaylistsViewModel()
    @State private var selectedPlaylist: VKPlaylist?
    @State private var showPlaylistDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerView
                    
                    if viewModel.isLoading && viewModel.playlists.isEmpty {
                        loadingView
                    } else {
                        if !viewModel.recommendations.isEmpty {
                            sectionView(
                                title: "Для вас",
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
                                items: viewModel.recentTracks
                            ) { track in
                                viewModel.playTrack(track)
                            }
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color.vkBackground)
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
        VStack(alignment: .leading, spacing: 4) {
            Text("Моя музыка")
                .font(.custom("VKSansDisplay-Bold", size: 34))
                .foregroundColor(.white)
            
            Text("\(viewModel.totalTracks) треков")
                .font(.custom("VKSansDisplay-Regular", size: 15))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ForEach(0..<5) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.vkSurface)
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.vkSurface)
                            .frame(width: 150, height: 14)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.vkSurface)
                            .frame(width: 100, height: 12)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
    }
    
    private func sectionView(title: String, items: [VKTrack], onTap: @escaping (VKTrack) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.custom("VKSansDisplay-Bold", size: 22))
                    .foregroundColor(.white)
                Spacer()
                Button("Все") { }
                    .font(.custom("VKSansDisplay-Medium", size: 14))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Популярное")
                    .font(.custom("VKSansDisplay-Bold", size: 22))
                    .foregroundColor(.white)
                Spacer()
                Button("Все") { }
                    .font(.custom("VKSansDisplay-Medium", size: 14))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Плейлисты")
                    .font(.custom("VKSansDisplay-Bold", size: 22))
                    .foregroundColor(.white)
                Spacer()
                Button("Все") { }
                    .font(.custom("VKSansDisplay-Medium", size: 14))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: track.coverUrl) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.vkSurface
                        Image(systemName: "music.note").font(.title).foregroundColor(.gray)
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
            .frame(width: 150, height: 150)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.custom("VKSansDisplay-Medium", size: 13))
                    .foregroundColor(.white).lineLimit(1)
                Text(track.artist)
                    .font(.custom("VKSansDisplay-Regular", size: 12))
                    .foregroundColor(.gray).lineLimit(1)
            }
            .padding(.horizontal, 2)
        }
        .frame(width: 150)
    }
}

// MARK: - Playlist Card
struct PlaylistCardView: View {
    let playlist: VKPlaylist
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: playlist.coverUrl) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.vkSurface
                        Image(systemName: "music.note.list").font(.title).foregroundColor(.gray)
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
            .frame(height: 170)
            .cornerRadius(12)
            
            Text(playlist.title)
                .font(.custom("VKSansDisplay-Medium", size: 14))
                .foregroundColor(.white).lineLimit(1)
            
            Text("\(playlist.trackCount) треков")
                .font(.custom("VKSansDisplay-Regular", size: 12))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Playlist Detail
struct PlaylistDetailView: View {
    let playlist: VKPlaylist
    @StateObject private var viewModel = PlaylistsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 16) {
                    AsyncImage(url: playlist.coverUrl) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        case .failure:
                            ZStack {
                                Color.vkSurface
                                Image(systemName: "music.note.list").font(.system(size: 40)).foregroundColor(.gray)
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
                    .frame(width: 200, height: 200)
                    .cornerRadius(16)
                    
                    Text(playlist.title)
                        .font(.custom("VKSansDisplay-Bold", size: 24))
                        .foregroundColor(.white)
                    
                    if let desc = playlist.description {
                        Text(desc)
                            .font(.custom("VKSansDisplay-Regular", size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("\(playlist.trackCount) треков")
                        .font(.custom("VKSansDisplay-Regular", size: 13))
                        .foregroundColor(.gray)
                    
                    Button(action: { viewModel.playPlaylist(playlist) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Слушать все")
                                .font(.custom("VKSansDisplay-Medium", size: 16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.blue)
                        .cornerRadius(14)
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
    }
}

// MARK: - Track Row
struct TrackRowView: View {
    let track: VKTrack
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.custom("VKSansDisplay-Regular", size: 14))
                .foregroundColor(.gray)
                .frame(width: 24)
            
            AsyncImage(url: track.coverUrl) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
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
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 44, height: 44)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.custom("VKSansDisplay-Medium", size: 15))
                    .foregroundColor(.white).lineLimit(1)
                Text(track.artist)
                    .font(.custom("VKSansDisplay-Regular", size: 13))
                    .foregroundColor(.gray).lineLimit(1)
            }
            
            Spacer()
            
            Text(track.formattedDuration)
                .font(.custom("VKSansDisplay-Regular", size: 12))
                .foregroundColor(.gray)
            
            Button(action: {}) {
                Image(systemName: "ellipsis").foregroundColor(.gray).padding(.leading, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.vkCardBackground)
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
    PlaylistsView().preferredColorScheme(.dark)
}
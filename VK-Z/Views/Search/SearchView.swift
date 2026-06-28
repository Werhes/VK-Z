import SwiftUI

// MARK: - Search View
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                
                if searchText.isEmpty {
                    emptyStateView
                } else {
                    searchResultsView
                }
            }
            .background(Color.vkBackground)
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                TextField("Поиск треков, альбомов...", text: $searchText)
                    .font(.custom("VKSansDisplay-Regular", size: 16))
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .focused($isSearchFocused)
                    .onChange(of: searchText) { _, newValue in
                        viewModel.search(query: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.vkCardBackground)
            .cornerRadius(12)
            
            if isSearchFocused {
                Button("Отмена") {
                    searchText = ""
                    isSearchFocused = false
                    viewModel.clearSearch()
                }
                .font(.custom("VKSansDisplay-Medium", size: 15))
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Поиск по жанрам")
                        .font(.custom("VKSansDisplay-Bold", size: 22))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Genre.allCases, id: \.self) { genre in
                                Button(action: {
                                    searchText = genre.rawValue
                                    viewModel.search(query: genre.rawValue)
                                }) {
                                    Text(genre.rawValue)
                                        .font(.custom("VKSansDisplay-Medium", size: 14))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.vkSurface)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                if !viewModel.popularTracks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Популярные треки")
                            .font(.custom("VKSansDisplay-Bold", size: 22))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.popularTracks.enumerated()), id: \.element.id) { index, track in
                                TrackRowView(track: track, index: index + 1)
                                    .onTapGesture { viewModel.playTrack(track) }
                                if index < viewModel.popularTracks.count - 1 {
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
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
    
    private var searchResultsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if viewModel.isSearching {
                VStack(spacing: 16) {
                    ForEach(0..<8) { _ in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8).fill(Color.vkSurface).frame(width: 44, height: 44)
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4).fill(Color.vkSurface).frame(width: 180, height: 12)
                                RoundedRectangle(cornerRadius: 4).fill(Color.vkSurface).frame(width: 120, height: 10)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 16)
            } else if viewModel.searchResults.isEmpty {
                VStack(spacing: 16) {
                    Spacer().frame(height: 60)
                    Image(systemName: "music.note.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Ничего не найдено")
                        .font(.custom("VKSansDisplay-Medium", size: 18))
                        .foregroundColor(.gray)
                    Text("Попробуйте изменить запрос")
                        .font(.custom("VKSansDisplay-Regular", size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0) {
                    HStack {
                        Text("Результаты поиска")
                            .font(.custom("VKSansDisplay-Bold", size: 22))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        Spacer()
                    }
                    
                    ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, track in
                        TrackRowView(track: track, index: index + 1)
                            .onTapGesture { viewModel.playTrack(track) }
                        if index < viewModel.searchResults.count - 1 {
                            Divider().background(Color.white.opacity(0.05)).padding(.leading, 60)
                        }
                    }
                }
                .background(Color.vkCardBackground)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .padding(.bottom, 100)
    }
}

// MARK: - Genres
enum Genre: String, CaseIterable {
    case rock = "Рок"
    case pop = "Поп"
    case rap = "Рэп"
    case electronic = "Электроника"
    case jazz = "Джаз"
    case classical = "Классика"
    case indie = "Инди"
    case rnb = "R&B"
    case metal = "Метал"
    case lounge = "Lounge"
}

// MARK: - ViewModel
final class SearchViewModel: ObservableObject {
    @Published var searchResults: [VKTrack] = []
    @Published var popularTracks: [VKTrack] = []
    @Published var isSearching = false
    
    private let api = VKApiService.shared
    private let player = AudioPlayerManager.shared
    private var searchTask: Task<Void, Never>?
    
    init() { loadPopular() }
    
    func loadPopular() {
        api.getPopular { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let tracks) = result {
                    self?.popularTracks = Array(tracks.prefix(20))
                }
            }
        }
    }
    
    func search(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        searchTask?.cancel()
        isSearching = true
        
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self?.api.searchAudio(query: query) { result in
                    DispatchQueue.main.async {
                        self?.isSearching = false
                        if case .success(let tracks) = result {
                            self?.searchResults = tracks
                        } else {
                            self?.searchResults = []
                        }
                    }
                }
            }
        }
    }
    
    func clearSearch() {
        searchTask?.cancel()
        searchResults = []
        isSearching = false
    }
    
    func playTrack(_ track: VKTrack) {
        player.setQueue(tracks: [track])
    }
}

#Preview {
    SearchView().preferredColorScheme(.dark)
}
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
            .background(AppColors.background)
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.system(size: 16, weight: .medium))
                
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
                            .foregroundColor(AppColors.textTertiary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppColors.surfaceLight)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSearchFocused ? AppColors.accentBlue.opacity(0.3) : .clear, lineWidth: 1)
            )
            
            if isSearchFocused {
                Button("Отмена") {
                    searchText = ""
                    isSearchFocused = false
                    viewModel.clearSearch()
                }
                .font(.custom("VKSansDisplay-Medium", size: 15))
                .foregroundColor(AppColors.accentBlue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private var emptyStateView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Genres
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppColors.warmGradient)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "music.note.list")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Поиск по жанрам")
                                .font(.custom("VKSansDisplay-Bold", size: 22))
                                .foregroundColor(.white)
                            
                            Text("Выберите жанр для поиска")
                                .font(.custom("VKSansDisplay-Regular", size: 13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
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
                                        .background(AppColors.surfaceLight)
                                        .cornerRadius(22)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 22)
                                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Popular tracks
                if !viewModel.popularTracks.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.coolGradient)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Популярные треки")
                                    .font(.custom("VKSansDisplay-Bold", size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Что в тренде")
                                    .font(.custom("VKSansDisplay-Regular", size: 13))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.popularTracks.enumerated()), id: \.element.id) { index, track in
                                TrackRowView(track: track, index: index + 1)
                                    .onTapGesture { viewModel.playTrack(track) }
                                if index < viewModel.popularTracks.count - 1 {
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
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
    }
    
    private var searchResultsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if viewModel.isSearching {
                VStack(spacing: 16) {
                    ForEach(0..<8) { _ in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.surfaceLight)
                                .frame(width: 44, height: 44)
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppColors.surfaceLight)
                                    .frame(width: 180, height: 12)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppColors.surfaceLight)
                                    .frame(width: 120, height: 10)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 16)
            } else if viewModel.searchResults.isEmpty {
                VStack(spacing: 20) {
                    Spacer().frame(height: 60)
                    
                    ZStack {
                        Circle()
                            .fill(AppColors.surfaceLight)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "music.note.magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    VStack(spacing: 6) {
                        Text("Ничего не найдено")
                            .font(.custom("VKSansDisplay-Medium", size: 18))
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Попробуйте изменить запрос")
                            .font(.custom("VKSansDisplay-Regular", size: 14))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.accentBlue)
                            
                            Text("Результаты поиска")
                                .font(.custom("VKSansDisplay-Bold", size: 20))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        
                        Spacer()
                        
                        Text("\(viewModel.searchResults.count)")
                            .font(.custom("VKSansDisplay-Regular", size: 13))
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.trailing, 20)
                    }
                    
                    ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, track in
                        TrackRowView(track: track, index: index + 1)
                            .onTapGesture { viewModel.playTrack(track) }
                        if index < viewModel.searchResults.count - 1 {
                            Divider()
                                .background(AppColors.surfaceLight)
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(AppColors.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .padding(.bottom, 120)
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
    SearchView()
        .preferredColorScheme(.dark)
}
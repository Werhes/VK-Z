import Foundation

// MARK: - VK Audio Track
struct VKTrack: Identifiable, Codable, Equatable {
    let id: Int
    let ownerId: Int
    let artist: String
    let title: String
    let duration: Int
    let url: String?
    let albumId: Int?
    let albumTitle: String?
    let genreId: Int?
    let trackCovers: [String]?
    let lyricsId: Int?
    let isExplicit: Bool?
    let isLicensed: Bool?
    let isFeatured: Bool?
    let isHq: Bool?
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var coverUrl: URL? {
        guard let covers = trackCovers, let urlString = covers.last else { return nil }
        return URL(string: urlString)
    }
    
    var audioUrl: URL? {
        guard let urlString = url else { return nil }
        return URL(string: urlString)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case artist
        case title
        case duration
        case url
        case albumId = "album_id"
        case albumTitle = "album_title"
        case genreId = "genre_id"
        case trackCovers = "track_covers"
        case lyricsId = "lyrics_id"
        case isExplicit = "is_explicit"
        case isLicensed = "is_licensed"
        case isFeatured = "is_featured"
        case isHq = "is_hq"
    }
}

// MARK: - VK Playlist
struct VKPlaylist: Identifiable, Codable, Equatable {
    let id: Int
    let ownerId: Int
    let title: String
    let description: String?
    let tracks: [VKTrack]?
    let trackCount: Int
    let photoUrl: String?
    let accessKey: String?
    let isFavorite: Bool?
    
    var coverUrl: URL? {
        guard let urlString = photoUrl else { return nil }
        return URL(string: urlString)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case title
        case description
        case tracks
        case trackCount = "track_count"
        case photoUrl = "photo_url"
        case accessKey = "access_key"
        case isFavorite = "is_favorite"
    }
}

// MARK: - VK User
struct VKUser: Codable {
    let id: Int
    let firstName: String
    let lastName: String
    let photoUrl: String?
    let photoUrlBig: String?
    
    var fullName: String { "\(firstName) \(lastName)" }
    var avatarUrl: URL? {
        guard let urlString = photoUrlBig ?? photoUrl else { return nil }
        return URL(string: urlString)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case photoUrl = "photo_url"
        case photoUrlBig = "photo_url_big"
    }
}

// MARK: - VK Audio Section (Catalog)
struct VKCatalogSection: Identifiable, Codable {
    let id: String
    let title: String
    let type: String
    let playlists: [VKPlaylist]?
    let tracks: [VKTrack]?
}

// MARK: - API Response Wrappers
struct VKApiResponse<T: Codable>: Codable {
    let response: T?
    let error: VKApiError?
}

struct VKApiError: Codable {
    let errorCode: Int
    let errorMsg: String
    
    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case errorMsg = "error_msg"
    }
}

struct VKMusicResponse: Codable {
    let count: Int
    let items: [VKTrack]
}

struct VKPlaylistsResponse: Codable {
    let count: Int
    let items: [VKPlaylist]
}

struct VKSearchResponse: Codable {
    let count: Int
    let items: [VKTrack]
}

// MARK: - VK Mix (умный плейлист/радио)
struct VKMix: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let description: String?
    let icon: String?
    let coverUrl: String?
    let color: String?
    let tracks: [VKTrack]?
    let trackCount: Int?
    let isMix: Bool?
    let isFollowed: Bool?
    let artists: [String]?
    
    var displayCover: URL? {
        if let urlString = coverUrl { return URL(string: urlString) }
        return tracks?.first?.coverUrl
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case description
        case icon
        case coverUrl = "cover_url"
        case color
        case tracks
        case trackCount = "track_count"
        case isMix = "is_mix"
        case isFollowed = "is_followed"
        case artists
    }
}

struct VKMixResponse: Codable {
    let count: Int
    let items: [VKMix]
}

struct VKMixTracksResponse: Codable {
    let count: Int
    let items: [VKTrack]
}

// MARK: - Player State
enum PlayerRepeatMode: String, Codable {
    case off
    case all
    case one
}

enum PlayerState {
    case stopped
    case playing
    case paused
    case loading
    case error(String)
}

// MARK: - Auth State
enum AuthState {
    case unauthenticated
    case authenticating
    case authenticated(token: String, userId: Int)
    case error(String)
}
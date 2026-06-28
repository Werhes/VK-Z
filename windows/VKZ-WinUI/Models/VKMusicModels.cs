using Newtonsoft.Json;
using System;
using System.Collections.Generic;

namespace VKZ.Models
{
    public class VKTrack
    {
        [JsonProperty("id")]
        public long Id { get; set; }

        [JsonProperty("owner_id")]
        public long OwnerId { get; set; }

        [JsonProperty("artist")]
        public string Artist { get; set; } = string.Empty;

        [JsonProperty("title")]
        public string Title { get; set; } = string.Empty;

        [JsonProperty("duration")]
        public int Duration { get; set; }

        [JsonProperty("url")]
        public string? Url { get; set; }

        [JsonProperty("album_id")]
        public long? AlbumId { get; set; }

        [JsonProperty("album")]
        public VKAlbum? Album { get; set; }

        [JsonProperty("genre_id")]
        public int? GenreId { get; set; }

        [JsonProperty("date")]
        public long? Date { get; set; }

        [JsonProperty("is_explicit")]
        public bool IsExplicit { get; set; }

        [JsonProperty("track_code")]
        public string? TrackCode { get; set; }

        [JsonIgnore]
        public string FormattedDuration
        {
            get
            {
                var ts = TimeSpan.FromSeconds(Duration);
                return ts.Hours > 0
                    ? $"{ts.Hours}:{ts.Minutes:D2}:{ts.Seconds:D2}"
                    : $"{ts.Minutes}:{ts.Seconds:D2}";
            }
        }

        [JsonIgnore]
        public Uri? CoverUrl
        {
            get
            {
                if (Album?.Thumb?.Photo340 != null)
                    return new Uri(Album.Thumb.Photo340);
                if (Album?.Thumb?.Photo270 != null)
                    return new Uri(Album.Thumb.Photo270);
                if (Album?.Thumb?.Photo135 != null)
                    return new Uri(Album.Thumb.Photo135);
                return null;
            }
        }

        [JsonIgnore]
        public Uri? AudioUrl => Url != null ? new Uri(Url) : null;

        public override bool Equals(object? obj)
        {
            if (obj is VKTrack other)
                return Id == other.Id && OwnerId == other.OwnerId;
            return false;
        }

        public override int GetHashCode() => HashCode.Combine(Id, OwnerId);
    }

    public class VKAlbum
    {
        [JsonProperty("id")]
        public long Id { get; set; }

        [JsonProperty("title")]
        public string Title { get; set; } = string.Empty;

        [JsonProperty("thumb")]
        public VKThumb? Thumb { get; set; }
    }

    public class VKThumb
    {
        [JsonProperty("photo_135")]
        public string? Photo135 { get; set; }

        [JsonProperty("photo_270")]
        public string? Photo270 { get; set; }

        [JsonProperty("photo_340")]
        public string? Photo340 { get; set; }

        [JsonProperty("photo_600")]
        public string? Photo600 { get; set; }
    }

    public class VKPlaylist
    {
        [JsonProperty("id")]
        public long Id { get; set; }

        [JsonProperty("owner_id")]
        public long OwnerId { get; set; }

        [JsonProperty("title")]
        public string Title { get; set; } = string.Empty;

        [JsonProperty("description")]
        public string? Description { get; set; }

        [JsonProperty("plays")]
        public int? Plays { get; set; }

        [JsonProperty("count")]
        public int Count { get; set; }

        [JsonProperty("photo")]
        public VKThumb? Photo { get; set; }

        [JsonProperty("access_key")]
        public string? AccessKey { get; set; }

        [JsonIgnore]
        public Uri? CoverUrl
        {
            get
            {
                if (Photo?.Photo600 != null)
                    return new Uri(Photo.Photo600);
                if (Photo?.Photo340 != null)
                    return new Uri(Photo.Photo340);
                if (Photo?.Photo270 != null)
                    return new Uri(Photo.Photo270);
                if (Photo?.Photo135 != null)
                    return new Uri(Photo.Photo135);
                return null;
            }
        }

        public override bool Equals(object? obj)
        {
            if (obj is VKPlaylist other)
                return Id == other.Id && OwnerId == other.OwnerId;
            return false;
        }

        public override int GetHashCode() => HashCode.Combine(Id, OwnerId);
    }

    public class VKUser
    {
        [JsonProperty("id")]
        public long Id { get; set; }

        [JsonProperty("first_name")]
        public string FirstName { get; set; } = string.Empty;

        [JsonProperty("last_name")]
        public string LastName { get; set; } = string.Empty;

        [JsonProperty("photo_100")]
        public string? Photo100 { get; set; }

        [JsonProperty("photo_200")]
        public string? Photo200 { get; set; }

        [JsonIgnore]
        public Uri? AvatarUrl
        {
            get
            {
                if (Photo200 != null)
                    return new Uri(Photo200);
                if (Photo100 != null)
                    return new Uri(Photo100);
                return null;
            }
        }

        [JsonIgnore]
        public string FullName => $"{FirstName} {LastName}";
    }

    public class VKCatalogSection
    {
        [JsonProperty("id")]
        public string Id { get; set; } = string.Empty;

        [JsonProperty("name")]
        public string Name { get; set; } = string.Empty;
    }

    public class VKApiResponse<T>
    {
        [JsonProperty("response")]
        public VKResponseData<T>? Response { get; set; }

        [JsonProperty("error")]
        public VKApiError? Error { get; set; }
    }

    public class VKResponseData<T>
    {
        [JsonProperty("count")]
        public int Count { get; set; }

        [JsonProperty("items")]
        public List<T> Items { get; set; } = new();
    }

    public class VKApiError
    {
        [JsonProperty("error_code")]
        public int ErrorCode { get; set; }

        [JsonProperty("error_msg")]
        public string ErrorMsg { get; set; } = string.Empty;
    }

    public class VKMusicResponse
    {
        [JsonProperty("count")]
        public int Count { get; set; }

        [JsonProperty("items")]
        public List<VKTrack> Items { get; set; } = new();
    }

    public class VKPlaylistsResponse
    {
        [JsonProperty("count")]
        public int Count { get; set; }

        [JsonProperty("items")]
        public List<VKPlaylist> Items { get; set; } = new();
    }

    public class VKSearchResponse
    {
        [JsonProperty("count")]
        public int Count { get; set; }

        [JsonProperty("items")]
        public List<VKTrack> Items { get; set; } = new();
    }

    public class VKMix
    {
        [JsonProperty("id")]
        public string Id { get; set; } = string.Empty;

        [JsonProperty("title")]
        public string Title { get; set; } = string.Empty;

        [JsonProperty("description")]
        public string? Description { get; set; }

        [JsonProperty("icon")]
        public string? Icon { get; set; }

        [JsonProperty("color")]
        public string? Color { get; set; }

        [JsonProperty("cover")]
        public VKThumb? Cover { get; set; }

        [JsonIgnore]
        public Uri? DisplayCover
        {
            get
            {
                if (Cover?.Photo600 != null)
                    return new Uri(Cover.Photo600);
                if (Cover?.Photo340 != null)
                    return new Uri(Cover.Photo340);
                if (Icon != null)
                    return new Uri(Icon);
                return null;
            }
        }

        public override bool Equals(object? obj)
        {
            if (obj is VKMix other)
                return Id == other.Id;
            return false;
        }

        public override int GetHashCode() => Id.GetHashCode();
    }

    public class VKMixResponse
    {
        [JsonProperty("count")]
        public int Count { get; set; }

        [JsonProperty("items")]
        public List<VKMix> Items { get; set; } = new();
    }

    public class VKMixTracksResponse
    {
        [JsonProperty("count")]
        public int Count { get; set; }

        [JsonProperty("items")]
        public List<VKTrack> Items { get; set; } = new();
    }

    public enum PlayerRepeatMode
    {
        None,
        One,
        All
    }

    public enum PlayerState
    {
        Stopped,
        Playing,
        Paused,
        Loading
    }

    public enum AuthState
    {
        Unauthorized,
        Authorizing,
        Authorized,
        Error
    }
}
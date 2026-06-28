using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;

namespace VKZ.Models
{
    public class VKTrack
    {
        [JsonProperty("id")]
        public long Id { get; set; }

        [JsonProperty("owner_id")]
        public long OwnerId { get; set; }

        [JsonProperty("title")]
        public string Title { get; set; } = string.Empty;

        [JsonProperty("artist")]
        public string Artist { get; set; } = string.Empty;

        [JsonProperty("duration")]
        public int Duration { get; set; }

        [JsonProperty("url")]
        public string? Url { get; set; }

        [JsonProperty("track_code")]
        public string? TrackCode { get; set; }

        [JsonProperty("access_key")]
        public string? AccessKey { get; set; }

        [JsonProperty("album_id")]
        public long? AlbumId { get; set; }

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
        public string? CoverUrl
        {
            get
            {
                if (AlbumId == null || OwnerId == 0) return null;
                return $"https://music.vk.com/api/audio.getCover?owner_id={OwnerId}&album_id={AlbumId}";
            }
        }

        [JsonIgnore]
        public string AudioUrl => Url ?? string.Empty;

        [JsonIgnore]
        public string FullId => $"{OwnerId}_{Id}";

        public override bool Equals(object? obj) =>
            obj is VKTrack other && OwnerId == other.OwnerId && Id == other.Id;

        public override int GetHashCode() => HashCode.Combine(OwnerId, Id);
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

        [JsonProperty("access_key")]
        public string? AccessKey { get; set; }

        [JsonProperty("count")]
        public int Count { get; set; }

        [JsonProperty("photo")]
        public VKPhoto? Photo { get; set; }

        [JsonIgnore]
        public string? CoverUrl => Photo?.Photo600 ?? Photo?.Photo300;

        [JsonIgnore]
        public string FullId => $"{OwnerId}_{Id}";
    }

    public class VKPhoto
    {
        [JsonProperty("photo_300")]
        public string? Photo300 { get; set; }

        [JsonProperty("photo_600")]
        public string? Photo600 { get; set; }

        [JsonProperty("photo_1200")]
        public string? Photo1200 { get; set; }
    }

    public class VKUser
    {
        [JsonProperty("id")]
        public long Id { get; set; }

        [JsonProperty("first_name")]
        public string FirstName { get; set; } = string.Empty;

        [JsonProperty("last_name")]
        public string LastName { get; set; } = string.Empty;

        [JsonProperty("photo_200")]
        public string? Photo200 { get; set; }

        [JsonIgnore]
        public string FullName => $"{FirstName} {LastName}";

        [JsonIgnore]
        public string? AvatarUrl => Photo200;
    }

    public class VKMix
    {
        [JsonProperty("id")]
        public string Id { get; set; } = string.Empty;

        [JsonProperty("title")]
        public string Title { get; set; } = string.Empty;

        [JsonProperty("description")]
        public string? Description { get; set; }

        [JsonProperty("cover_url")]
        public string? CoverUrl { get; set; }

        [JsonProperty("color")]
        public string? Color { get; set; }

        [JsonProperty("track_count")]
        public int TrackCount { get; set; }
    }

    public class VKApiResponse<T>
    {
        [JsonProperty("response")]
        public T? Response { get; set; }

        [JsonProperty("error")]
        public VKApiError? Error { get; set; }
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
        [JsonProperty("items")]
        public List<VKTrack> Items { get; set; } = new();
    }

    public class VKPlaylistsResponse
    {
        [JsonProperty("items")]
        public List<VKPlaylist> Items { get; set; } = new();
    }

    public class VKSearchResponse
    {
        [JsonProperty("items")]
        public List<VKTrack> Items { get; set; } = new();
    }

    public class VKMixResponse
    {
        [JsonProperty("items")]
        public List<VKMix> Items { get; set; } = new();
    }

    public class VKMixTracksResponse
    {
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
        Idle,
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
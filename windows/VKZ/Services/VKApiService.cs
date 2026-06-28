using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using VkNet;
using VkNet.Abstractions;
using VkNet.AudioBypassService.Extensions;
using VkNet.Enums.Filters;
using VkNet.Model;
using VkNet.Model.RequestParams;
using VKZ.Models;

namespace VKZ.Services
{
    public sealed class VKApiService
    {
        private static readonly Lazy<VKApiService> _instance = new(() => new VKApiService());
        public static VKApiService Instance => _instance.Value;

        private IVkApi? _api;
        private IVkApiInvoke? _apiInvoke;
        private bool _isAuth;

        public bool IsAuthorized => _isAuth;
        public long? UserId => _api?.UserId;

        private VKApiService() { }

        public async Task AuthorizeAsync(string token)
        {
            var services = new ServiceCollection();
            services.AddAudioBypass();
            var provider = services.BuildServiceProvider();

            _api = new VkApi(provider);
            await _api.AuthorizeAsync(new ApiAuthParams
            {
                AccessToken = token
            });

            _apiInvoke = _api.Invoke;
            _isAuth = true;
        }

        public async Task AuthorizeWithLoginAsync(string login, string password, Func<Task<string>> twoFactorFunc)
        {
            var services = new ServiceCollection();
            services.AddAudioBypass();
            var provider = services.BuildServiceProvider();

            _api = new VkApi(provider);
            _api.OnTwoFactor += async (sender, args) =>
            {
                args.Code = await twoFactorFunc();
                args.RememberDevice = true;
            };

            await _api.AuthorizeAsync(new ApiAuthParams
            {
                Login = login,
                Password = password,
                Settings = Settings.Audio
            });

            _apiInvoke = _api.Invoke;
            _isAuth = true;
        }

        public async Task<VKUser?> GetCurrentUserAsync()
        {
            if (_api == null) return null;

            var users = await _api.Users.GetAsync(new List<long>(), ProfileFields.Photo200);
            var user = users?.FirstOrDefault();
            if (user == null) return null;

            return new VKUser
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Photo200 = user.Photo200?.AbsoluteUri
            };
        }

        public async Task<List<VKTrack>> GetAudioAsync(long? playlistId = null, long? ownerId = null, int offset = 0, int count = 100)
        {
            var audio = await _api!.Audio.GetAsync(new AudioGetParams
            {
                PlaylistId = playlistId,
                OwnerId = ownerId,
                Offset = offset,
                Count = count
            });
            return audio.Select(a => new VKTrack
            {
                Id = a.Id,
                OwnerId = a.OwnerId,
                Title = a.Title,
                Artist = a.Artist,
                Duration = a.Duration,
                Url = a.Url?.AbsoluteUri,
                TrackCode = a.TrackCode,
                AccessKey = a.AccessKey,
                AlbumId = a.AlbumId
            }).ToList();
        }

        public async Task<List<VKPlaylist>> GetPlaylistsAsync(long ownerId, int count = 100)
        {
            var playlists = await _api!.Audio.GetPlaylistsAsync(ownerId, count);
            return playlists.Select(p => new VKPlaylist
            {
                Id = p.Id,
                OwnerId = p.OwnerId,
                Title = p.Title,
                Description = p.Description,
                AccessKey = p.AccessKey,
                Count = p.Count,
                Photo = p.Photo != null ? new VKPhoto
                {
                    Photo300 = p.Photo.Photo300?.AbsoluteUri,
                    Photo600 = p.Photo.Photo600?.AbsoluteUri,
                    Photo1200 = p.Photo.Photo1200?.AbsoluteUri
                } : null
            }).ToList();
        }

        public async Task<List<VKTrack>> SearchAudioAsync(string query, int count = 50)
        {
            var result = await _api!.Audio.SearchAsync(new AudioSearchParams
            {
                Query = query,
                Count = count,
                Autocomplete = true
            });
            return result.Select(a => new VKTrack
            {
                Id = a.Id,
                OwnerId = a.OwnerId,
                Title = a.Title,
                Artist = a.Artist,
                Duration = a.Duration,
                Url = a.Url?.AbsoluteUri,
                TrackCode = a.TrackCode,
                AccessKey = a.AccessKey
            }).ToList();
        }

        public async Task<List<VKTrack>> GetRecommendationsAsync(int count = 50)
        {
            var result = await _api!.Audio.GetRecommendationsAsync(count: count);
            return result.Select(a => new VKTrack
            {
                Id = a.Id,
                OwnerId = a.OwnerId,
                Title = a.Title,
                Artist = a.Artist,
                Duration = a.Duration,
                Url = a.Url?.AbsoluteUri,
                TrackCode = a.TrackCode,
                AccessKey = a.AccessKey
            }).ToList();
        }

        public async Task<List<VKTrack>> GetPopularAsync(int count = 50)
        {
            var result = await _api!.Audio.GetPopularAsync(count: count);
            return result.Select(a => new VKTrack
            {
                Id = a.Id,
                OwnerId = a.OwnerId,
                Title = a.Title,
                Artist = a.Artist,
                Duration = a.Duration,
                Url = a.Url?.AbsoluteUri,
                TrackCode = a.TrackCode,
                AccessKey = a.AccessKey
            }).ToList();
        }

        public async Task<List<VKMix>> GetMixesAsync(int count = 20)
        {
            try
            {
                var json = await CallRawAsync("audio.getMixes", new VkParameters
                {
                    ["count"] = count.ToString()
                });
                var response = JsonConvert.DeserializeObject<VkApiResponse<VKMixResponse>>(json);
                return response?.Response?.Items ?? new List<VKMix>();
            }
            catch
            {
                return new List<VKMix>();
            }
        }

        public async Task<List<VKTrack>> GetMixTracksAsync(string mixId, int count = 50)
        {
            try
            {
                var json = await CallRawAsync("audio.getMixTracks", new VkParameters
                {
                    ["mix_id"] = mixId,
                    ["count"] = count.ToString()
                });
                var response = JsonConvert.DeserializeObject<VkApiResponse<VKMixTracksResponse>>(json);
                return response?.Response?.Items ?? new List<VKTrack>();
            }
            catch
            {
                return new List<VKTrack>();
            }
        }

        private async Task<string> CallRawAsync(string method, VkParameters parameters)
        {
            if (_apiInvoke == null)
                throw new InvalidOperationException("Not authorized");

            return await _apiInvoke.InvokeAsync(method, parameters);
        }
    }

    internal class VkApiResponse<T>
    {
        [JsonProperty("response")]
        public T? Response { get; set; }
    }
}
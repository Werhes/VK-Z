using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using VKZ.Models;
using VkNet.Abstractions;
using VkNet.Abstractions.Core;
using VkNet.AudioBypassService.Abstractions;
using VkNet.Model;
using VkNet.Utils;

namespace VKZ.Services
{
    /// <summary>
    /// Сервис для работы с VK API Audio.
    /// Использует IVkApiInvoke напрямую (как в Music-M) для кастомных методов audio.*.
    /// </summary>
    public class VKApiService
    {
        private readonly IVkApiInvoke _apiInvoke;
        private readonly IVkApiCategories _vkApi;
        private readonly IVkApiVersionManager _versionManager;
        private readonly IVkTokenStore _tokenStore;
        private readonly IDeviceIdStore _deviceIdStore;
        private readonly IVkApi _api;

        private const string ApiVersion = "8.154";

        public long? CurrentUserId { get; private set; }

        public VKApiService(
            IVkApiInvoke apiInvoke,
            IVkApiCategories vkApi,
            IVkApiVersionManager versionManager,
            IVkTokenStore tokenStore,
            IDeviceIdStore deviceIdStore,
            IVkApi api)
        {
            _apiInvoke = apiInvoke;
            _vkApi = vkApi;
            _versionManager = versionManager;
            _tokenStore = tokenStore;
            _deviceIdStore = deviceIdStore;
            _api = api;

            var ver = ApiVersion.Split('.');
            _versionManager.SetVersion(int.Parse(ver[0]), int.Parse(ver[1]));
        }

        /// <summary>
        /// Устанавливает токен и userId после авторизации.
        /// </summary>
        public void SetAuth(long userId)
        {
            CurrentUserId = userId;
        }

        /// <summary>
        /// Проверяет, авторизован ли пользователь.
        /// </summary>
        public bool IsAuthorized => _api.IsAuthorized && CurrentUserId.HasValue;

        #region Audio Methods

        /// <summary>
        /// Получает аудиозаписи пользователя (с плейлистами).
        /// </summary>
        public async Task<List<VKTrack>> GetAudio(long? playlistId = null, long? ownerId = null, string? accessKey = null, int offset = 0, int count = 100)
        {
            var parameters = new VkParameters
            {
                {"owner_id", ownerId ?? CurrentUserId ?? 0},
                {"offset", offset},
                {"count", count}
            };

            if (playlistId.HasValue)
                parameters.Add("album_id", playlistId.Value);
            if (!string.IsNullOrEmpty(accessKey))
                parameters.Add("access_key", accessKey);

            var response = await _apiInvoke.CallAsync<VKMusicResponse>("audio.get", parameters);
            return response?.Items ?? new List<VKTrack>();
        }

        /// <summary>
        /// Получает плейлисты пользователя.
        /// </summary>
        public async Task<List<VKPlaylist>> GetPlaylists(long? ownerId = null, int offset = 0, int count = 50)
        {
            var parameters = new VkParameters
            {
                {"owner_id", ownerId ?? CurrentUserId ?? 0},
                {"offset", offset},
                {"count", count}
            };

            var response = await _apiInvoke.CallAsync<VKPlaylistsResponse>("audio.get_playlists", parameters);
            return response?.Items ?? new List<VKPlaylist>();
        }

        /// <summary>
        /// Получает треки плейлиста.
        /// </summary>
        public async Task<List<VKTrack>> GetPlaylistTracks(long playlistId, long ownerId, string? accessKey = null, int offset = 0, int count = 100)
        {
            var parameters = new VkParameters
            {
                {"owner_id", ownerId},
                {"album_id", playlistId},
                {"offset", offset},
                {"count", count}
            };

            if (!string.IsNullOrEmpty(accessKey))
                parameters.Add("access_key", accessKey);

            var response = await _apiInvoke.CallAsync<VKMusicResponse>("audio.get", parameters);
            return response?.Items ?? new List<VKTrack>();
        }

        /// <summary>
        /// Поиск аудиозаписей.
        /// </summary>
        public async Task<List<VKTrack>> SearchAudio(string query, int offset = 0, int count = 100)
        {
            var parameters = new VkParameters
            {
                {"q", query},
                {"offset", offset},
                {"count", count}
            };

            var response = await _apiInvoke.CallAsync<VKSearchResponse>("audio.search", parameters);
            return response?.Items ?? new List<VKTrack>();
        }

        /// <summary>
        /// Получает рекомендации на основе трека.
        /// </summary>
        public async Task<List<VKTrack>> GetRecommendations(long trackId, long ownerId)
        {
            var parameters = new VkParameters
            {
                {"audio_id", trackId},
                {"owner_id", ownerId}
            };

            var response = await _apiInvoke.CallAsync<VKMusicResponse>("audio.get_recommendations", parameters);
            return response?.Items ?? new List<VKTrack>();
        }

        /// <summary>
        /// Получает популярные треки.
        /// </summary>
        public async Task<List<VKTrack>> GetPopular(int offset = 0, int count = 100)
        {
            var parameters = new VkParameters
            {
                {"offset", offset},
                {"count", count}
            };

            var response = await _apiInvoke.CallAsync<VKMusicResponse>("audio.get_popular", parameters);
            return response?.Items ?? new List<VKTrack>();
        }

        /// <summary>
        /// Получает каталог (разделы).
        /// </summary>
        public async Task<List<VKCatalogSection>> GetCatalog()
        {
            var parameters = new VkParameters();
            var response = await _apiInvoke.CallAsync<JObject>("audio.get_catalog", parameters);
            // Парсим секции из ответа
            var sections = new List<VKCatalogSection>();
            if (response?["items"] is JArray items)
            {
                foreach (var item in items)
                {
                    if (item["id"] != null && item["name"] != null)
                    {
                        sections.Add(new VKCatalogSection
                        {
                            Id = item["id"]!.ToString(),
                            Name = item["name"]!.ToString()
                        });
                    }
                }
            }
            return sections;
        }

        /// <summary>
        /// Получает список миксов.
        /// </summary>
        public async Task<List<VKMix>> GetMixes()
        {
            var parameters = new VkParameters();
            var response = await _apiInvoke.CallAsync<VKMixResponse>("audio.get_mixes", parameters);
            return response?.Items ?? new List<VKMix>();
        }

        /// <summary>
        /// Получает треки микса.
        /// </summary>
        public async Task<List<VKTrack>> GetMixTracks(string mixId)
        {
            var parameters = new VkParameters
            {
                {"mix_id", mixId}
            };

            var response = await _apiInvoke.CallAsync<VKMixTracksResponse>("audio.get_mix_tracks", parameters);
            return response?.Items ?? new List<VKTrack>();
        }

        /// <summary>
        /// Создаёт микс на основе трека.
        /// </summary>
        public async Task<VKMix?> CreateMix(long trackId, long ownerId)
        {
            var parameters = new VkParameters
            {
                {"audio_id", trackId},
                {"owner_id", ownerId}
            };

            var response = await _apiInvoke.CallAsync<JObject>("audio.create_mix", parameters);
            if (response != null)
            {
                return response.ToObject<VKMix>();
            }
            return null;
        }

        #endregion

        #region User Methods

        /// <summary>
        /// Получает информацию о текущем пользователе.
        /// </summary>
        public async Task<VKUser?> GetCurrentUserAsync()
        {
            var parameters = new VkParameters
            {
                {"fields", "photo_100,photo_200"}
            };

            var response = await _apiInvoke.CallAsync<JObject>("users.get", parameters);
            if (response?["response"] is JArray items && items.Count > 0)
            {
                return items[0].ToObject<VKUser>();
            }
            return null;
        }

        #endregion
    }
}
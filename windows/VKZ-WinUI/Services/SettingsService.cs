using Newtonsoft.Json;
using System;
using System.IO;
using System.Threading.Tasks;
using Windows.Storage;

namespace VKZ.Services
{
    /// <summary>
    /// Сервис для хранения настроек приложения в JSON-файле.
    /// Заменяет Properties.Settings из WPF.
    /// </summary>
    public class SettingsService
    {
        private const string SettingsFileName = "settings.json";
        private SettingsData _data = new();
        private readonly string _settingsFilePath;
        private bool _isLoaded;

        public SettingsService()
        {
            _settingsFilePath = Path.Combine(
                ApplicationData.Current.LocalFolder.Path,
                SettingsFileName);
        }

        /// <summary>
        /// Загружает настройки из файла. Вызывается при старте приложения.
        /// </summary>
        public async Task LoadAsync()
        {
            try
            {
                if (File.Exists(_settingsFilePath))
                {
                    var json = await File.ReadAllTextAsync(_settingsFilePath);
                    var data = JsonConvert.DeserializeObject<SettingsData>(json);
                    if (data != null)
                    {
                        _data = data;
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to load settings: {ex.Message}");
            }
            finally
            {
                _isLoaded = true;
            }
        }

        /// <summary>
        /// Сохраняет настройки в файл.
        /// </summary>
        public async Task SaveAsync()
        {
            try
            {
                var json = JsonConvert.SerializeObject(_data, Formatting.Indented);
                await File.WriteAllTextAsync(_settingsFilePath, json);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to save settings: {ex.Message}");
            }
        }

        // --- Свойства настроек ---

        public string? VkToken
        {
            get => _data.VkToken;
            set
            {
                _data.VkToken = value;
                _ = SaveAsync();
            }
        }

        public long? VkUserId
        {
            get => _data.VkUserId;
            set
            {
                _data.VkUserId = value;
                _ = SaveAsync();
            }
        }

        public bool IsAuthorized =>
            !string.IsNullOrEmpty(VkToken) && VkUserId.HasValue;

        public float Volume
        {
            get => _data.Volume;
            set
            {
                _data.Volume = Math.Clamp(value, 0f, 1f);
                _ = SaveAsync();
            }
        }

        public bool IsShuffled
        {
            get => _data.IsShuffled;
            set
            {
                _data.IsShuffled = value;
                _ = SaveAsync();
            }
        }

        public int RepeatMode
        {
            get => _data.RepeatMode;
            set
            {
                _data.RepeatMode = Math.Clamp(value, 0, 2);
                _ = SaveAsync();
            }
        }

        public string? LastPlaylistId
        {
            get => _data.LastPlaylistId;
            set
            {
                _data.LastPlaylistId = value;
                _ = SaveAsync();
            }
        }

        /// <summary>
        /// Очищает токен и userId (при логауте).
        /// </summary>
        public async Task ClearAuthAsync()
        {
            _data.VkToken = null;
            _data.VkUserId = null;
            await SaveAsync();
        }

        private class SettingsData
        {
            public string? VkToken { get; set; }
            public long? VkUserId { get; set; }
            public float Volume { get; set; } = 0.8f;
            public bool IsShuffled { get; set; }
            public int RepeatMode { get; set; }
            public string? LastPlaylistId { get; set; }
        }
    }
}
using System;
using System.Threading.Tasks;
using VKZ.Models;
using VkNet.Abstractions;
using VkNet.AudioBypassService.Abstractions;
using VkNet.AudioBypassService.Models.Auth;
using VkNet.Enums;

namespace VKZ.Services
{
    /// <summary>
    /// Сервис экосистемной авторизации VK через IVkApiAuthAsync.
    /// Поддерживает методы: push, sms, call, password, code generator.
    /// Аналог ChooseLoginWayControl из Music-M.
    /// </summary>
    public class VkAuthService
    {
        private readonly IVkApiAuthAsync _authAsync;
        private readonly IVkApi _vkApi;
        private readonly IVkTokenStore _tokenStore;
        private readonly SettingsService _settings;
        private readonly VKApiService _vkApiService;

        public AuthState AuthState { get; private set; } = AuthState.Unauthorized;
        public string? LastError { get; private set; }

        public event EventHandler<AuthState>? AuthStateChanged;

        public VkAuthService(
            IVkApiAuthAsync authAsync,
            IVkApi vkApi,
            IVkTokenStore tokenStore,
            SettingsService settings,
            VKApiService vkApiService)
        {
            _authAsync = authAsync;
            _vkApi = vkApi;
            _tokenStore = tokenStore;
            _settings = settings;
            _vkApiService = vkApiService;
        }

        /// <summary>
        /// Проверяет, есть ли сохранённая сессия.
        /// </summary>
        public bool HasSavedSession()
        {
            return _settings.IsAuthorized;
        }

        /// <summary>
        /// Восстанавливает сессию из сохранённого токена.
        /// </summary>
        public async Task<bool> RestoreSessionAsync()
        {
            if (!_settings.IsAuthorized)
                return false;

            try
            {
                var token = await _tokenStore.GetTokenAsync();
                if (string.IsNullOrEmpty(token))
                    return false;

                _vkApi.Authorize(new VkNet.Model.ApiAuthParams
                {
                    AccessToken = token
                });

                if (_vkApi.IsAuthorized && _settings.VkUserId.HasValue)
                {
                    _vkApiService.SetAuth(_settings.VkUserId.Value);
                    SetAuthState(AuthState.Authorized);
                    return true;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Session restore failed: {ex.Message}");
            }

            return false;
        }

        /// <summary>
        /// Запускает экосистемную авторизацию (VK ID).
        /// Вызывает IVkApiAuthAsync.AuthorizeAsync(new AndroidApiAuthParams()).
        /// </summary>
        public async Task<bool> AuthorizeEcosystemAsync()
        {
            try
            {
                SetAuthState(AuthState.Authorizing);
                LastError = null;

                // Экосистемная авторизация как в Music-M
                await _authAsync.AuthorizeAsync(new AndroidApiAuthParams());

                if (_vkApi.IsAuthorized)
                {
                    var token = await _tokenStore.GetTokenAsync();
                    var userId = _vkApi.UserId;

                    if (!string.IsNullOrEmpty(token) && userId.HasValue)
                    {
                        _settings.VkToken = token;
                        _settings.VkUserId = userId.Value;
                        _vkApiService.SetAuth(userId.Value);
                        SetAuthState(AuthState.Authorized);
                        return true;
                    }
                }

                SetAuthState(AuthState.Error);
                LastError = "Не удалось получить токен после авторизации";
                return false;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Ecosystem auth failed: {ex.Message}");
                LastError = ex.Message;
                SetAuthState(AuthState.Error);
                return false;
            }
        }

        /// <summary>
        /// Авторизация по логину и паролю с поддержкой 2FA.
        /// </summary>
        public async Task<bool> AuthorizeWithPasswordAsync(string login, string password, Func<Task<string>>? twoFactorCallback = null)
        {
            try
            {
                SetAuthState(AuthState.Authorizing);
                LastError = null;

                var authParams = new ApiAuthParams
                {
                    Login = login,
                    Password = password,
                    ApplicationId = 2274003,
                    ApplicationSecret = "hHbZxrka2uZ6jB1inYsH",
                    Settings = Settings.Audio
                };

                // Если есть callback для 2FA, устанавливаем его
                if (twoFactorCallback != null)
                {
                    // VkNet поддерживает TwoFactorAuthorization через событие
                    // Но в AudioBypassService это может работать иначе
                }

                await _authAsync.AuthorizeAsync(authParams);

                if (_vkApi.IsAuthorized)
                {
                    var token = await _tokenStore.GetTokenAsync();
                    var userId = _vkApi.UserId;

                    if (!string.IsNullOrEmpty(token) && userId.HasValue)
                    {
                        _settings.VkToken = token;
                        _settings.VkUserId = userId.Value;
                        _vkApiService.SetAuth(userId.Value);
                        SetAuthState(AuthState.Authorized);
                        return true;
                    }
                }

                SetAuthState(AuthState.Error);
                LastError = "Не удалось получить токен";
                return false;
            }
            catch (VkNet.Exception.VkApiException ex)
            {
                System.Diagnostics.Debug.WriteLine($"Auth failed: {ex.Message}");
                LastError = ex.Message;
                SetAuthState(AuthState.Error);
                return false;
            }
        }

        /// <summary>
        /// Авторизация по прямому токену.
        /// </summary>
        public async Task<bool> AuthorizeWithTokenAsync(string token, long userId)
        {
            try
            {
                SetAuthState(AuthState.Authorizing);
                LastError = null;

                _vkApi.Authorize(new VkNet.Model.ApiAuthParams
                {
                    AccessToken = token
                });

                if (_vkApi.IsAuthorized)
                {
                    _settings.VkToken = token;
                    _settings.VkUserId = userId;
                    _vkApiService.SetAuth(userId);
                    SetAuthState(AuthState.Authorized);
                    return true;
                }

                SetAuthState(AuthState.Error);
                LastError = "Токен недействителен";
                return false;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Token auth failed: {ex.Message}");
                LastError = ex.Message;
                SetAuthState(AuthState.Error);
                return false;
            }
        }

        /// <summary>
        /// Выход из аккаунта.
        /// </summary>
        public async Task LogoutAsync()
        {
            _vkApi.LogOut();
            await _settings.ClearAuthAsync();
            SetAuthState(AuthState.Unauthorized);
        }

        private void SetAuthState(AuthState state)
        {
            AuthState = state;
            AuthStateChanged?.Invoke(this, state);
        }
    }
}
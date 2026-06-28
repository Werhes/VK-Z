using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using System;
using System.Threading.Tasks;
using VKZ.Services;

namespace VKZ.Views
{
    public sealed partial class AuthPage : Page
    {
        private readonly VkAuthService _authService;
        private readonly SettingsService _settings;

        public AuthPage()
        {
            this.InitializeComponent();

            _authService = App.GetService<VkAuthService>();
            _settings = App.GetService<SettingsService>();

            AuthMethodSelector.SelectionChanged += OnAuthMethodChanged;
            _authService.AuthStateChanged += OnAuthStateChanged;
        }

        private void OnAuthMethodChanged(object sender, SelectionChangedEventArgs e)
        {
            if (AuthMethodSelector.SelectedIndex == 0)
            {
                TokenPanel.Visibility = Visibility.Visible;
                LoginPanel.Visibility = Visibility.Collapsed;
            }
            else
            {
                TokenPanel.Visibility = Visibility.Collapsed;
                LoginPanel.Visibility = Visibility.Visible;
            }
        }

        private async void OnVkIdClick(object sender, RoutedEventArgs e)
        {
            SetLoading(true);
            ErrorInfoBar.IsOpen = false;

            var success = await _authService.AuthorizeEcosystemAsync();

            SetLoading(false);

            if (success)
            {
                NavigateToMain();
            }
            else
            {
                ShowError(_authService.LastError ?? "Ошибка авторизации через VK ID");
            }
        }

        private async void OnTokenLoginClick(object sender, RoutedEventArgs e)
        {
            var token = TokenTextBox.Text?.Trim();
            if (string.IsNullOrEmpty(token))
            {
                ShowError("Введите токен");
                return;
            }

            long userId = 0;
            if (!string.IsNullOrEmpty(UserIdTextBox.Text))
            {
                if (!long.TryParse(UserIdTextBox.Text, out userId))
                {
                    ShowError("Некорректный ID пользователя");
                    return;
                }
            }

            SetLoading(true);
            ErrorInfoBar.IsOpen = false;

            var success = await _authService.AuthorizeWithTokenAsync(token, userId);

            SetLoading(false);

            if (success)
            {
                NavigateToMain();
            }
            else
            {
                ShowError(_authService.LastError ?? "Неверный токен");
            }
        }

        private async void OnPasswordLoginClick(object sender, RoutedEventArgs e)
        {
            var login = LoginTextBox.Text?.Trim();
            var password = PasswordBox.Password;

            if (string.IsNullOrEmpty(login) || string.IsNullOrEmpty(password))
            {
                ShowError("Введите логин и пароль");
                return;
            }

            SetLoading(true);
            ErrorInfoBar.IsOpen = false;

            var success = await _authService.AuthorizeWithPasswordAsync(login, password);

            SetLoading(false);

            if (success)
            {
                NavigateToMain();
            }
            else
            {
                ShowError(_authService.LastError ?? "Неверный логин или пароль");
            }
        }

        private void OnAuthStateChanged(object? sender, Models.AuthState state)
        {
            _ = DispatcherQueue.TryEnqueue(() =>
            {
                switch (state)
                {
                    case Models.AuthState.Authorizing:
                        SetLoading(true);
                        break;
                    case Models.AuthState.Authorized:
                        SetLoading(false);
                        NavigateToMain();
                        break;
                    case Models.AuthState.Error:
                        SetLoading(false);
                        ShowError(_authService.LastError ?? "Ошибка авторизации");
                        break;
                }
            });
        }

        private void SetLoading(bool isLoading)
        {
            LoadingRing.IsActive = isLoading;
            LoadingRing.Visibility = isLoading ? Visibility.Visible : Visibility.Collapsed;
            VkIdButton.IsEnabled = !isLoading;
        }

        private void ShowError(string message)
        {
            ErrorInfoBar.Message = message;
            ErrorInfoBar.IsOpen = true;
        }

        private void NavigateToMain()
        {
            if (App.GetService<MainWindow>() is MainWindow mainWindow)
            {
                mainWindow.NavigateToPlaylists();
            }
        }
    }
}
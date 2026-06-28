using System;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using VKZ.Properties;
using VKZ.Services;

namespace VKZ.Views
{
    public partial class AuthView : UserControl
    {
        public event Action? OnAuthSuccess;
        private TaskCompletionSource<string?>? _twoFactorTcs;

        public AuthView()
        {
            InitializeComponent();
        }

        private void OnTabChanged(object sender, RoutedEventArgs e)
        {
            if (sender == TokenTab)
            {
                TokenPanel.Visibility = Visibility.Visible;
                PhonePanel.Visibility = Visibility.Collapsed;
                TwoFactorPanel.Visibility = Visibility.Collapsed;
                AuthActionButton.Content = "Войти";
            }
            else
            {
                TokenPanel.Visibility = Visibility.Collapsed;
                PhonePanel.Visibility = Visibility.Visible;
                AuthActionButton.Content = "Войти";
            }
            StatusText.Text = "";
        }

        private async void OnAuthClick(object sender, RoutedEventArgs e)
        {
            // If we're waiting for 2FA code, submit it via the TCS
            if (_twoFactorTcs != null)
            {
                var code = TwoFactorTextBox.Text?.Trim();
                if (string.IsNullOrEmpty(code))
                {
                    StatusText.Text = "Введите код двухфакторной авторизации";
                    StatusText.Foreground = System.Windows.Media.Brushes.Orange;
                    return;
                }

                _twoFactorTcs.TrySetResult(code);
                AuthActionButton.IsEnabled = false;
                AuthActionButton.Content = "Авторизация...";
                return;
            }

            if (TokenTab.IsChecked == true)
            {
                await AuthWithToken();
            }
            else
            {
                await AuthWithPhone();
            }
        }

        private async Task AuthWithToken()
        {
            var token = TokenTextBox.Text?.Trim();
            if (string.IsNullOrEmpty(token))
            {
                StatusText.Text = "Введите токен доступа";
                return;
            }

            try
            {
                StatusText.Foreground = System.Windows.Media.Brushes.Gray;
                StatusText.Text = "Авторизация...";
                AuthActionButton.IsEnabled = false;

                await VKApiService.Instance.AuthorizeAsync(token);

                var user = await VKApiService.Instance.GetCurrentUserAsync();
                if (user != null)
                {
                    Settings.Default.AccessToken = token;
                    Settings.Default.UserId = user.Id;
                    Settings.Default.Save();
                }

                StatusText.Text = $"Успешно! Добро пожаловать, {user?.FullName ?? "пользователь"}";
                StatusText.Foreground = System.Windows.Media.Brushes.LightGreen;
                OnAuthSuccess?.Invoke();
            }
            catch (Exception ex)
            {
                StatusText.Text = $"Ошибка: {ex.Message}";
                StatusText.Foreground = System.Windows.Media.Brushes.Red;
            }
            finally
            {
                AuthActionButton.IsEnabled = true;
            }
        }

        private async Task AuthWithPhone()
        {
            var phone = PhoneTextBox.Text?.Trim();
            var password = PasswordBox.Password;

            if (string.IsNullOrEmpty(phone) || string.IsNullOrEmpty(password))
            {
                StatusText.Text = "Введите номер телефона и пароль";
                return;
            }

            try
            {
                StatusText.Foreground = System.Windows.Media.Brushes.Gray;
                StatusText.Text = "Авторизация...";
                AuthActionButton.IsEnabled = false;

                await VKApiService.Instance.AuthorizeWithLoginAsync(phone, password, async () =>
                {
                    // Switch to UI thread to show 2FA panel
                    await Dispatcher.InvokeAsync(() =>
                    {
                        _twoFactorTcs = new TaskCompletionSource<string?>();
                        TwoFactorPanel.Visibility = Visibility.Visible;
                        AuthActionButton.Content = "Отправить код 2FA";
                        AuthActionButton.IsEnabled = true;
                        StatusText.Text = "Введите код двухфакторной авторизации";
                        StatusText.Foreground = System.Windows.Media.Brushes.Orange;
                        TwoFactorTextBox.Text = "";
                        TwoFactorTextBox.Focus();
                    });

                    // Wait for the user to enter the code and click the button
                    var code = await _twoFactorTcs!.Task;
                    return code ?? throw new OperationCanceledException("2FA code was not provided");
                });

                var user = await VKApiService.Instance.GetCurrentUserAsync();
                if (user != null)
                {
                    Settings.Default.UserId = user.Id;
                    Settings.Default.Save();
                }

                StatusText.Text = $"Успешно! Добро пожаловать, {user?.FullName ?? "пользователь"}";
                StatusText.Foreground = System.Windows.Media.Brushes.LightGreen;
                OnAuthSuccess?.Invoke();
            }
            catch (Exception ex)
            {
                StatusText.Text = $"Ошибка: {ex.Message}";
                StatusText.Foreground = System.Windows.Media.Brushes.Red;
            }
            finally
            {
                AuthActionButton.IsEnabled = true;
                _twoFactorTcs = null;
                TwoFactorPanel.Visibility = Visibility.Collapsed;
            }
        }
    }
}
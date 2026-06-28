using System;
using System.Windows;
using System.Windows.Controls;
using VKZ.Properties;
using VKZ.Services;

namespace VKZ.Views
{
    public partial class AuthView : UserControl
    {
        public event Action? OnAuthSuccess;
        private bool _waitingForTwoFactor;

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
            if (_waitingForTwoFactor)
            {
                await SubmitTwoFactor();
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

        private async System.Threading.Tasks.Task AuthWithToken()
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

        private async System.Threading.Tasks.Task AuthWithPhone()
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

                await VKApiService.Instance.AuthorizeWithLoginAsync(phone, password, () =>
                {
                    // This runs on UI thread via dispatcher
                    string? code = null;
                    Dispatcher.Invoke(() =>
                    {
                        _waitingForTwoFactor = true;
                        TwoFactorPanel.Visibility = Visibility.Visible;
                        AuthActionButton.Content = "Отправить код 2FA";
                        StatusText.Text = "Введите код двухфакторной авторизации";
                        StatusText.Foreground = System.Windows.Media.Brushes.Orange;
                        AuthActionButton.IsEnabled = true;
                    });

                    // Wait for code
                    var waitEvent = new System.Threading.AutoResetEvent(false);
                    string? result = null;
                    Dispatcher.Invoke(() =>
                    {
                        TwoFactorTextBox.TextChanged += (s, args) =>
                        {
                            if (TwoFactorTextBox.Text.Length >= 4)
                            {
                                result = TwoFactorTextBox.Text;
                                waitEvent.Set();
                            }
                        };
                    });
                    waitEvent.WaitOne(60000); // 1 minute timeout
                    return result ?? throw new TimeoutException("Таймаут ожидания 2FA кода");
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
            catch (TimeoutException)
            {
                StatusText.Text = "Таймаут ожидания 2FA кода";
                StatusText.Foreground = System.Windows.Media.Brushes.Red;
            }
            catch (Exception ex)
            {
                StatusText.Text = $"Ошибка: {ex.Message}";
                StatusText.Foreground = System.Windows.Media.Brushes.Red;
            }
            finally
            {
                AuthActionButton.IsEnabled = true;
                _waitingForTwoFactor = false;
            }
        }

        private async System.Threading.Tasks.Task SubmitTwoFactor()
        {
            // This is handled inside AuthWithPhone via the callback
        }
    }
}
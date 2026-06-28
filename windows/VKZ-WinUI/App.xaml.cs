using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.UI.Xaml;
using System;
using System.Threading.Tasks;
using VKZ.Services;
using VkNet.Abstractions;
using VkNet.AudioBypassService.Extensions;
using VkNet.Extensions.DependencyInjection;

namespace VKZ
{
    public partial class App : Application
    {
        public static IHost Host { get; private set; } = null!;

        public static TService GetService<TService>() where TService : notnull
            => Host.Services.GetRequiredService<TService>();

        public App()
        {
            this.InitializeComponent();
            Application.Current.RequestedTheme = ApplicationTheme.Dark;
        }

        protected override async void OnLaunched(Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
        {
            Host = CreateHostBuilder().Build();

            // Запускаем хост
            await Host.StartAsync();

            // Создаём и активируем главное окно
            m_window = new MainWindow();
            m_window.Activate();

            this.UnhandledException += App_UnhandledException;
        }

        private static IHostBuilder CreateHostBuilder()
        {
            return Host.CreateDefaultBuilder()
                .ConfigureServices(services =>
                {
                    // VkNet с AudioBypass (экосистемная авторизация)
                    services.AddAudioBypass();
                    services.AddVkNet();

                    // Хранилища токенов
                    services.AddSingleton<IVkTokenStore, RegistryTokenStore>();
                    services.AddSingleton<IDeviceIdStore, RegistryTokenStore>();

                    // Сервисы приложения
                    services.AddSingleton<SettingsService>();
                    services.AddSingleton<VKApiService>();
                    services.AddSingleton<AudioPlayerService>();
                    services.AddSingleton<VkAuthService>();

                    // Страницы (регистрируются как transient — создаются при каждом переходе)
                    services.AddTransient<Views.AuthPage>();
                    services.AddTransient<Views.PlaylistsPage>();
                    services.AddTransient<Views.SearchPage>();
                    services.AddTransient<Views.MixPage>();
                    services.AddTransient<Views.PopularPage>();
                });
        }

        private void App_UnhandledException(object sender, Microsoft.UI.Xaml.UnhandledExceptionEventArgs e)
        {
            // Логирование необработанных исключений
            System.Diagnostics.Debug.WriteLine($"Unhandled exception: {e.Exception}");
            e.Handled = true;
        }

        private Window? m_window;
    }
}
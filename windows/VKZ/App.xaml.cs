using System.Windows;
using VKZ.Properties;
using VKZ.Services;

namespace VKZ
{
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            // Load saved token
            var savedToken = Settings.Default.AccessToken;
            var savedUserId = Settings.Default.UserId;

            if (!string.IsNullOrEmpty(savedToken) && savedUserId > 0)
            {
                // Token will be used on demand when user navigates to playlists
            }
        }

        protected override void OnExit(ExitEventArgs e)
        {
            AudioPlayerService.Instance.Dispose();
            base.OnExit(e);
        }
    }
}
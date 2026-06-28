using System.Windows;
using VKZ.Services;

namespace VKZ
{
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            // Load saved token
            var savedToken = Properties.Settings.Default.AccessToken;
            var savedUserId = Properties.Settings.Default.UserId;

            if (!string.IsNullOrEmpty(savedToken) && savedUserId > 0)
            {
                VKApiService.Instance.Configure(savedToken, savedUserId);
            }
        }

        protected override void OnExit(ExitEventArgs e)
        {
            AudioPlayerService.Instance.Dispose();
            base.OnExit(e);
        }
    }
}
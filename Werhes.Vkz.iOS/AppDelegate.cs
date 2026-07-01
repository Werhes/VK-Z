using Foundation;
using UIKit;

namespace Werhes.Vkz.iOS
{
    [Register("AppDelegate")]
    public class AppDelegate : UIResponder, IUIApplicationDelegate
    {
        [Export("window")]
        public UIWindow Window { get; set; }

        [Export("application:didFinishLaunchingWithOptions:")]
        public bool FinishedLaunching(UIApplication application, NSDictionary launchOptions)
        {
            // Настройка AppCenter
            Microsoft.AppCenter.AppCenter.Start("ee629636-643f-425c-9ce1-6444adada296",
                typeof(Microsoft.AppCenter.Analytics.Analytics),
                typeof(Microsoft.AppCenter.Crashes.Crashes));

            return true;
        }

        [Export("application:configurationForConnectingSceneSession:options:")]
        public UISceneConfiguration GetConfiguration(UIApplication application, UISceneSession connectingSceneSession, UISceneConnectionOptions options)
        {
            return UISceneConfiguration.Create("Default Configuration", connectingSceneSession.Role);
        }
    }
}
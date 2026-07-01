using Foundation;
using UIKit;

namespace Werhes.Vkz.iOS
{
    [Register("SceneDelegate")]
    public class SceneDelegate : UIResponder, IUIWindowSceneDelegate
    {
        [Export("window")]
        public UIWindow Window { get; set; }

        [Export("scene:willConnectToSession:options:")]
        public void WillConnect(UIScene scene, UISceneSession session, UISceneConnectionOptions connectionOptions)
        {
            var windowScene = scene as UIWindowScene;
            Window = new UIWindow(windowScene);

            var storyboard = UIStoryboard.FromName("Main", null);
            var rootViewController = storyboard.InstantiateInitialViewController();

            Window.RootViewController = rootViewController;
            Window.MakeKeyAndVisible();
        }
    }
}
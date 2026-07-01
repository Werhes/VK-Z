using UIKit;

namespace Werhes.Vkz.iOS.ViewControllers
{
    public class NavigationController : UINavigationController
    {
        public override void ViewDidLoad()
        {
            base.ViewDidLoad();
            NavigationBar.BarTintColor = UIColor.FromRGB(0x21, 0x21, 0x21);
            NavigationBar.TintColor = UIColor.White;
            NavigationBar.TitleTextAttributes = new UIStringAttributes
            {
                ForegroundColor = UIColor.White
            };
            NavigationBar.Translucent = false;
        }

        public override UIStatusBarStyle PreferredStatusBarStyle()
        {
            return UIStatusBarStyle.LightContent;
        }
    }
}
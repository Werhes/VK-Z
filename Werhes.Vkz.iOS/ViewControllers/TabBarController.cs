using UIKit;
using Foundation;

namespace Werhes.Vkz.iOS.ViewControllers
{
    public class TabBarController : UITabBarController
    {
        public override void ViewDidLoad()
        {
            base.ViewDidLoad();

            TabBar.TintColor = UIColor.FromRGB(0x80, 0x80, 0x80);
            TabBar.BarTintColor = UIColor.FromRGB(0x21, 0x21, 0x21);
            TabBar.UnselectedItemTintColor = UIColor.FromRGB(0xAA, 0xAA, 0xAA);

            var homeVC = CreateTab<RecommendationsViewController>(
                "Рекомендации", "house.fill", "house");

            var tracksVC = CreateTab<TracksViewController>(
                "Моя музыка", "music.note.list", "music.note.list");

            var searchVC = CreateTab<SearchViewController>(
                "Поиск", "magnifyingglass", "magnifyingglass");

            var settingsVC = CreateTab<SettingsViewController>(
                "Настройки", "gearshape.fill", "gearshape");

            ViewControllers = new UIViewController[]
            {
                homeVC, tracksVC, searchVC, settingsVC
            };

            SelectedIndex = 0;
        }

        private UINavigationController CreateTab<T>(string title, string selectedImage, string unselectedImage) where T : UIViewController, new()
        {
            var vc = new T();
            vc.TabBarItem = new UITabBarItem(title, UIImage.GetSystemImage(unselectedImage), UIImage.GetSystemImage(selectedImage));
            vc.TabBarItem.SelectedImage = UIImage.GetSystemImage(selectedImage);
            return new UINavigationController(vc);
        }
    }
}
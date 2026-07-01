using UIKit;

namespace Werhes.Vkz.iOS.ViewControllers
{
    /// <summary>
    /// HomeViewController — главный экран приложения.
    /// В текущей реализации используется RecommendationsViewController.
    /// Этот класс оставлен для возможного расширения функционала главного экрана.
    /// </summary>
    public class HomeViewController : RecommendationsViewController
    {
        public override void ViewDidLoad()
        {
            base.ViewDidLoad();
            Title = "Главная";
        }
    }
}
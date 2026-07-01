using UIKit;
using Foundation;
using Werhes.Vkz.iOS.Services;

namespace Werhes.Vkz.iOS.ViewControllers
{
    public class SplashViewController : UIViewController
    {
        private UIActivityIndicatorView _activityIndicator;

        public override void ViewDidLoad()
        {
            base.ViewDidLoad();
            View.BackgroundColor = UIColor.FromRGB(0x21, 0x21, 0x21);

            var titleLabel = new UILabel
            {
                Text = "VK Z",
                Font = UIFont.BoldSystemFontOfSize(36),
                TextColor = UIColor.White,
                TextAlignment = UITextAlignment.Center,
                TranslatesAutoresizingMaskIntoConstraints = false
            };
            View.AddSubview(titleLabel);

            _activityIndicator = new UIActivityIndicatorView(UIActivityIndicatorViewStyle.WhiteLarge)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                HidesWhenStopped = true
            };
            View.AddSubview(_activityIndicator);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                titleLabel.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                titleLabel.CenterYAnchor.ConstraintEqualTo(View.CenterYAnchor, -30),
                _activityIndicator.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                _activityIndicator.TopAnchor.ConstraintEqualTo(titleLabel.BottomAnchor, 30)
            });
        }

        public override void ViewDidAppear(bool animated)
        {
            base.ViewDidAppear(animated);
            _activityIndicator.StartAnimating();

            // Проверка авторизации
            if (AuthService.IsLoggedIn())
            {
                Core.Api.GetApi().VKontakte.Auth.Auto(AuthService.GetToken(), null);
                NavigateToMain();
            }
            else
            {
                NavigateToAuth();
            }
        }

        private void NavigateToMain()
        {
            var tabBarController = new TabBarController();
            tabBarController.ModalPresentationStyle = UIModalPresentationStyle.FullScreen;
            PresentViewController(tabBarController, true, null);
        }

        private void NavigateToAuth()
        {
            var authVC = new AuthViewController();
            authVC.ModalPresentationStyle = UIModalPresentationStyle.FullScreen;
            PresentViewController(authVC, true, null);
        }
    }
}
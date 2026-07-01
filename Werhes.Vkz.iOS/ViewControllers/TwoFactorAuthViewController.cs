using UIKit;

namespace Werhes.Vkz.iOS.ViewControllers
{
    /// <summary>
    /// TwoFactorAuthViewController — экран двухфакторной аутентификации.
    /// В текущей реализации используется заглушка, так как VK OAuth через WKWebView
    /// обрабатывает 2FA автоматически.
    /// </summary>
    public class TwoFactorAuthViewController : UIViewController
    {
        private UILabel _messageLabel;
        private UIActivityIndicatorView _loader;

        public override void ViewDidLoad()
        {
            base.ViewDidLoad();
            View.BackgroundColor = UIColor.FromRGB(0x21, 0x21, 0x21);

            _messageLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.White,
                Font = UIFont.SystemFontOfSize(16),
                TextAlignment = UITextAlignment.Center,
                Text = "Ожидание подтверждения входа..."
            };
            View.AddSubview(_messageLabel);

            _loader = new UIActivityIndicatorView(UIActivityIndicatorViewStyle.WhiteLarge)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                HidesWhenStopped = true
            };
            _loader.StartAnimating();
            View.AddSubview(_loader);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _messageLabel.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                _messageLabel.CenterYAnchor.ConstraintEqualTo(View.CenterYAnchor, -30),
                _messageLabel.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor, 20),
                _messageLabel.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor, -20),

                _loader.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                _loader.TopAnchor.ConstraintEqualTo(_messageLabel.BottomAnchor, 20)
            });
        }
    }
}
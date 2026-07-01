using UIKit;
using WebKit;
using Foundation;
using Werhes.Vkz.iOS.Services;

namespace Werhes.Vkz.iOS.ViewControllers
{
    public class AuthViewController : UIViewController
    {
        private WKWebView _webView;
        private UIActivityIndicatorView _activityIndicator;

        public override void ViewDidLoad()
        {
            base.ViewDidLoad();
            View.BackgroundColor = UIColor.FromRGB(0x21, 0x21, 0x21);

            _activityIndicator = new UIActivityIndicatorView(UIActivityIndicatorViewStyle.WhiteLarge)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                HidesWhenStopped = true
            };
            View.AddSubview(_activityIndicator);

            var config = new WKWebViewConfiguration();
            _webView = new WKWebView(View.Bounds, config)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                Alpha = 0
            };
            _webView.NavigationDelegate = new AuthNavigationDelegate(this);
            View.AddSubview(_webView);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _webView.TopAnchor.ConstraintEqualTo(View.TopAnchor),
                _webView.BottomAnchor.ConstraintEqualTo(View.BottomAnchor),
                _webView.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor),
                _webView.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor),
                _activityIndicator.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                _activityIndicator.CenterYAnchor.ConstraintEqualTo(View.CenterYAnchor)
            });

            LoadAuthPage();
        }

        private void LoadAuthPage()
        {
            _activityIndicator.StartAnimating();
            var url = new NSUrl("https://oauth.vk.com/authorize?client_id=6121396&display=mobile&redirect_uri=https://oauth.vk.com/blank.html&scope=audio,offline&response_type=token&v=5.131");
            var request = new NSUrlRequest(url);
            _webView.LoadRequest(request);
        }

        private class AuthNavigationDelegate : WKNavigationDelegate
        {
            private readonly AuthViewController _controller;

            public AuthNavigationDelegate(AuthViewController controller)
            {
                _controller = controller;
            }

            public override void DidFinishNavigation(WKWebView webView, WKNavigation navigation)
            {
                _controller._activityIndicator.StopAnimating();
                UIView.Animate(0.3, () => _controller._webView.Alpha = 1);
            }

            public override void DidStartProvisionalNavigation(WKWebView webView, WKNavigation navigation)
            {
                _controller._activityIndicator.StartAnimating();
            }

            public override void DecidePolicy(WKWebView webView, WKNavigationAction navigationAction, Action<WKNavigationActionPolicy> decisionHandler)
            {
                var url = navigationAction.Request.Url?.AbsoluteString ?? "";
                
                if (url.Contains("access_token="))
                {
                    var token = ExtractParameter(url, "access_token=");
                    var userId = ExtractParameter(url, "user_id=");

                    if (!string.IsNullOrEmpty(token))
                    {
                        AuthService.SaveToken(token);
                        Core.Api.GetApi().VKontakte.Auth.Auto(token, null);
                        _controller.NavigateToMain();
                    }

                    decisionHandler(WKNavigationActionPolicy.Cancel);
                    return;
                }

                decisionHandler(WKNavigationActionPolicy.Allow);
            }

            private string ExtractParameter(string url, string param)
            {
                var startIndex = url.IndexOf(param);
                if (startIndex == -1) return null;
                startIndex += param.Length;
                var endIndex = url.IndexOf('&', startIndex);
                if (endIndex == -1) endIndex = url.Length;
                return url.Substring(startIndex, endIndex - startIndex);
            }
        }

        private void NavigateToMain()
        {
            var tabBarController = new TabBarController();
            tabBarController.ModalPresentationStyle = UIModalPresentationStyle.FullScreen;
            PresentViewController(tabBarController, true, null);
        }
    }
}
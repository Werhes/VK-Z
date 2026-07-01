using System;
using UIKit;
using Werhes.Vkz.iOS.Services;

namespace Werhes.Vkz.iOS.ViewControllers
{
    public class PlayerViewController : UIViewController
    {
        private UIImageView _coverImageView;
        private UILabel _titleLabel;
        private UILabel _artistLabel;
        private UISlider _progressSlider;
        private UILabel _currentTimeLabel;
        private UILabel _durationLabel;
        private UIButton _playPauseButton;
        private UIButton _nextButton;
        private UIButton _prevButton;
        private UIButton _repeatButton;
        private UIButton _dismissButton;

        public override void ViewDidLoad()
        {
            base.ViewDidLoad();
            View.BackgroundColor = UIColor.FromRGB(0x21, 0x21, 0x21);

            _dismissButton = new UIButton(UIButtonType.System)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TintColor = UIColor.White
            };
            _dismissButton.SetImage(UIImage.GetSystemImage("chevron.down"), UIControlState.Normal);
            _dismissButton.TouchUpInside += (s, e) => DismissViewController(true, null);
            View.AddSubview(_dismissButton);

            _coverImageView = new UIImageView
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                ContentMode = UIViewContentMode.ScaleAspectFill,
                ClipsToBounds = true,
                Layer = { CornerRadius = 12 }
            };
            View.AddSubview(_coverImageView);

            _titleLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.White,
                Font = UIFont.SystemFontOfSize(22, UIFontWeight.Bold),
                TextAlignment = UITextAlignment.Center
            };
            View.AddSubview(_titleLabel);

            _artistLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.FromRGB(0xAA, 0xAA, 0xAA),
                Font = UIFont.SystemFontOfSize(16),
                TextAlignment = UITextAlignment.Center
            };
            View.AddSubview(_artistLabel);

            _currentTimeLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.FromRGB(0xAA, 0xAA, 0xAA),
                Font = UIFont.SystemFontOfSize(12),
                Text = "0:00"
            };
            View.AddSubview(_currentTimeLabel);

            _durationLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.FromRGB(0xAA, 0xAA, 0xAA),
                Font = UIFont.SystemFontOfSize(12),
                Text = "0:00"
            };
            View.AddSubview(_durationLabel);

            _progressSlider = new UISlider
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                MinimumTrackTintColor = UIColor.FromRGB(0x80, 0x80, 0x80),
                MaximumTrackTintColor = UIColor.FromRGB(0x3D, 0x3D, 0x3D),
                ThumbTintColor = UIColor.White
            };
            View.AddSubview(_progressSlider);

            _prevButton = new UIButton(UIButtonType.System)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TintColor = UIColor.White
            };
            _prevButton.SetImage(UIImage.GetSystemImage("backward.fill"), UIControlState.Normal);
            _prevButton.TouchUpInside += (s, e) => PlayerService.Instance.MainService.BackTrack();
            View.AddSubview(_prevButton);

            _playPauseButton = new UIButton(UIButtonType.System)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TintColor = UIColor.White
            };
            _playPauseButton.SetImage(UIImage.GetSystemImage("play.fill"), UIControlState.Normal);
            _playPauseButton.TouchUpInside += OnPlayPause;
            View.AddSubview(_playPauseButton);

            _nextButton = new UIButton(UIButtonType.System)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TintColor = UIColor.White
            };
            _nextButton.SetImage(UIImage.GetSystemImage("forward.fill"), UIControlState.Normal);
            _nextButton.TouchUpInside += (s, e) => PlayerService.Instance.MainService.NextTrack();
            View.AddSubview(_nextButton);

            _repeatButton = new UIButton(UIButtonType.System)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TintColor = UIColor.FromRGB(0xAA, 0xAA, 0xAA)
            };
            _repeatButton.SetImage(UIImage.GetSystemImage("repeat"), UIControlState.Normal);
            _repeatButton.TouchUpInside += (s, e) =>
            {
                StaticContentService.RepeatPlaylist = !StaticContentService.RepeatPlaylist;
                _repeatButton.TintColor = StaticContentService.RepeatPlaylist
                    ? UIColor.FromRGB(0x80, 0x80, 0x80) : UIColor.FromRGB(0xAA, 0xAA, 0xAA);
            };
            View.AddSubview(_repeatButton);

            SetupConstraints();
            UpdatePlayerInfo();
        }

        private void SetupConstraints()
        {
            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _dismissButton.TopAnchor.ConstraintEqualTo(View.SafeAreaLayoutGuide.TopAnchor, 8),
                _dismissButton.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor, 16),
                _dismissButton.WidthAnchor.ConstraintEqualTo(35),
                _dismissButton.HeightAnchor.ConstraintEqualTo(35),

                _coverImageView.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                _coverImageView.TopAnchor.ConstraintEqualTo(_dismissButton.BottomAnchor, 20),
                _coverImageView.WidthAnchor.ConstraintEqualTo(View.WidthAnchor, 0.75f),
                _coverImageView.HeightAnchor.ConstraintEqualTo(View.WidthAnchor, 0.75f),

                _titleLabel.TopAnchor.ConstraintEqualTo(_coverImageView.BottomAnchor, 24),
                _titleLabel.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor, 24),
                _titleLabel.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor, -24),

                _artistLabel.TopAnchor.ConstraintEqualTo(_titleLabel.BottomAnchor, 6),
                _artistLabel.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor, 24),
                _artistLabel.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor, -24),

                _currentTimeLabel.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor, 24),
                _currentTimeLabel.TopAnchor.ConstraintEqualTo(_artistLabel.BottomAnchor, 20),

                _durationLabel.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor, -24),
                _durationLabel.TopAnchor.ConstraintEqualTo(_artistLabel.BottomAnchor, 20),

                _progressSlider.TopAnchor.ConstraintEqualTo(_currentTimeLabel.BottomAnchor, 4),
                _progressSlider.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor, 24),
                _progressSlider.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor, -24),

                _prevButton.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor, -80),
                _prevButton.TopAnchor.ConstraintEqualTo(_progressSlider.BottomAnchor, 24),
                _prevButton.WidthAnchor.ConstraintEqualTo(50),
                _prevButton.HeightAnchor.ConstraintEqualTo(50),

                _playPauseButton.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                _playPauseButton.TopAnchor.ConstraintEqualTo(_progressSlider.BottomAnchor, 20),
                _playPauseButton.WidthAnchor.ConstraintEqualTo(60),
                _playPauseButton.HeightAnchor.ConstraintEqualTo(60),

                _nextButton.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor, 80),
                _nextButton.TopAnchor.ConstraintEqualTo(_progressSlider.BottomAnchor, 24),
                _nextButton.WidthAnchor.ConstraintEqualTo(50),
                _nextButton.HeightAnchor.ConstraintEqualTo(50),

                _repeatButton.TopAnchor.ConstraintEqualTo(_playPauseButton.BottomAnchor, 20),
                _repeatButton.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                _repeatButton.WidthAnchor.ConstraintEqualTo(35),
                _repeatButton.HeightAnchor.ConstraintEqualTo(35)
            });
        }

        private void UpdatePlayerInfo()
        {
            var player = PlayerService.Instance;
            _titleLabel.Text = player.Title ?? "Не играет";
            _artistLabel.Text = player.Artist ?? "";
        }

        private void OnPlayPause(object sender, EventArgs e)
        {
            var player = PlayerService.Instance;
            if (player.MainService.IsPlaying)
            {
                player.Pause();
                _playPauseButton.SetImage(UIImage.GetSystemImage("play.fill"), UIControlState.Normal);
            }
            else
            {
                player.Play();
                _playPauseButton.SetImage(UIImage.GetSystemImage("pause.fill"), UIControlState.Normal);
            }
        }
    }
}
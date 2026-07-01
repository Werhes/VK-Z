using UIKit;
using Werhes.Vkz.iOS.Services;

namespace Werhes.Vkz.iOS.Views
{
    public class MiniPlayerView : UIView
    {
        private readonly UIImageView _coverImageView;
        private readonly UILabel _titleLabel;
        private readonly UILabel _artistLabel;
        private readonly UIButton _playPauseButton;
        private readonly UIButton _nextButton;

        public MiniPlayerView()
        {
            BackgroundColor = UIColor.FromRGB(0x2D, 0x2D, 0x2D);
            TranslatesAutoresizingMaskIntoConstraints = false;

            _coverImageView = new UIImageView
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                ContentMode = UIViewContentMode.ScaleAspectFill,
                ClipsToBounds = true,
                Layer = { CornerRadius = 4 }
            };
            AddSubview(_coverImageView);

            _titleLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.White,
                Font = UIFont.SystemFontOfSize(14, UIFontWeight.Medium)
            };
            AddSubview(_titleLabel);

            _artistLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.FromRGB(0xAA, 0xAA, 0xAA),
                Font = UIFont.SystemFontOfSize(12)
            };
            AddSubview(_artistLabel);

            _playPauseButton = new UIButton(UIButtonType.System)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TintColor = UIColor.White
            };
            _playPauseButton.SetImage(UIImage.GetSystemImage("play.fill"), UIControlState.Normal);
            AddSubview(_playPauseButton);

            _nextButton = new UIButton(UIButtonType.System)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TintColor = UIColor.White
            };
            _nextButton.SetImage(UIImage.GetSystemImage("forward.fill"), UIControlState.Normal);
            AddSubview(_nextButton);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                HeightAnchor.ConstraintEqualTo(60),

                _coverImageView.LeadingAnchor.ConstraintEqualTo(LeadingAnchor, 12),
                _coverImageView.CenterYAnchor.ConstraintEqualTo(CenterYAnchor),
                _coverImageView.WidthAnchor.ConstraintEqualTo(45),
                _coverImageView.HeightAnchor.ConstraintEqualTo(45),

                _titleLabel.TopAnchor.ConstraintEqualTo(_coverImageView.TopAnchor, 2),
                _titleLabel.LeadingAnchor.ConstraintEqualTo(_coverImageView.TrailingAnchor, 10),
                _titleLabel.TrailingAnchor.ConstraintEqualTo(_playPauseButton.LeadingAnchor, -8),

                _artistLabel.TopAnchor.ConstraintEqualTo(_titleLabel.BottomAnchor, 2),
                _artistLabel.LeadingAnchor.ConstraintEqualTo(_coverImageView.TrailingAnchor, 10),
                _artistLabel.TrailingAnchor.ConstraintEqualTo(_playPauseButton.LeadingAnchor, -8),

                _nextButton.TrailingAnchor.ConstraintEqualTo(TrailingAnchor, -12),
                _nextButton.CenterYAnchor.ConstraintEqualTo(CenterYAnchor),
                _nextButton.WidthAnchor.ConstraintEqualTo(35),
                _nextButton.HeightAnchor.ConstraintEqualTo(35),

                _playPauseButton.TrailingAnchor.ConstraintEqualTo(_nextButton.LeadingAnchor, -8),
                _playPauseButton.CenterYAnchor.ConstraintEqualTo(CenterYAnchor),
                _playPauseButton.WidthAnchor.ConstraintEqualTo(35),
                _playPauseButton.HeightAnchor.ConstraintEqualTo(35)
            });

            // Сохраняем ссылки для MiniPlayerService
            MiniPlayerService.MiniPlayer = this;
            MiniPlayerService.TitleLabel = _titleLabel;
            MiniPlayerService.ArtistLabel = _artistLabel;
            MiniPlayerService.CoverImageView = _coverImageView;
            MiniPlayerService.PlayPauseButton = _playPauseButton;

            _playPauseButton.TouchUpInside += (s, e) =>
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
            };

            _nextButton.TouchUpInside += (s, e) =>
            {
                PlayerService.Instance.MainService.NextTrack();
            };

            var tapGesture = new UITapGestureRecognizer(() =>
            {
                // Открыть полноэкранный плеер
            });
            AddGestureRecognizer(tapGesture);
        }
    }
}
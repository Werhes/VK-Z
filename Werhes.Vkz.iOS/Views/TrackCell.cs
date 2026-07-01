using UIKit;
using CoreGraphics;

namespace Werhes.Vkz.iOS.Views
{
    public class TrackCell : UITableViewCell
    {
        public static readonly NSString CellId = new NSString("TrackCell");

        private readonly UIImageView _coverImageView;
        private readonly UILabel _titleLabel;
        private readonly UILabel _artistLabel;

        public TrackCell() : base(UITableViewCellStyle.Default, CellId)
        {
            BackgroundColor = UIColor.FromRGB(0x2D, 0x2D, 0x2D);
            SelectionStyle = UITableViewCellSelectionStyle.Gray;

            _coverImageView = new UIImageView
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                ContentMode = UIViewContentMode.ScaleAspectFill,
                ClipsToBounds = true,
                Layer = { CornerRadius = 4 }
            };
            ContentView.AddSubview(_coverImageView);

            _titleLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.White,
                Font = UIFont.SystemFontOfSize(16, UIFontWeight.Medium)
            };
            ContentView.AddSubview(_titleLabel);

            _artistLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.FromRGB(0xAA, 0xAA, 0xAA),
                Font = UIFont.SystemFontOfSize(13)
            };
            ContentView.AddSubview(_artistLabel);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _coverImageView.LeadingAnchor.ConstraintEqualTo(ContentView.LeadingAnchor, 12),
                _coverImageView.CenterYAnchor.ConstraintEqualTo(ContentView.CenterYAnchor),
                _coverImageView.WidthAnchor.ConstraintEqualTo(45),
                _coverImageView.HeightAnchor.ConstraintEqualTo(45),

                _titleLabel.TopAnchor.ConstraintEqualTo(ContentView.TopAnchor, 10),
                _titleLabel.LeadingAnchor.ConstraintEqualTo(_coverImageView.TrailingAnchor, 12),
                _titleLabel.TrailingAnchor.ConstraintEqualTo(ContentView.TrailingAnchor, -12),

                _artistLabel.TopAnchor.ConstraintEqualTo(_titleLabel.BottomAnchor, 3),
                _artistLabel.LeadingAnchor.ConstraintEqualTo(_coverImageView.TrailingAnchor, 12),
                _artistLabel.TrailingAnchor.ConstraintEqualTo(ContentView.TrailingAnchor, -12),
                _artistLabel.BottomAnchor.ConstraintEqualTo(ContentView.BottomAnchor, -10)
            });
        }

        public void Update(string title, string artist, UIImage cover)
        {
            _titleLabel.Text = title;
            _artistLabel.Text = artist;
            _coverImageView.Image = cover ?? UIImage.GetSystemImage("music.note");
        }
    }
}
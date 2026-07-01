using UIKit;

namespace Werhes.Vkz.iOS.Views
{
    public class PlaylistCell : UITableViewCell
    {
        public static readonly NSString CellId = new NSString("PlaylistCell");

        private readonly UIImageView _coverImageView;
        private readonly UILabel _titleLabel;
        private readonly UILabel _tracksCountLabel;

        public PlaylistCell() : base(UITableViewCellStyle.Default, CellId)
        {
            BackgroundColor = UIColor.FromRGB(0x2D, 0x2D, 0x2D);
            SelectionStyle = UITableViewCellSelectionStyle.Gray;

            _coverImageView = new UIImageView
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                ContentMode = UIViewContentMode.ScaleAspectFill,
                ClipsToBounds = true,
                Layer = { CornerRadius = 6 }
            };
            ContentView.AddSubview(_coverImageView);

            _titleLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.White,
                Font = UIFont.SystemFontOfSize(16, UIFontWeight.Medium)
            };
            ContentView.AddSubview(_titleLabel);

            _tracksCountLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.FromRGB(0xAA, 0xAA, 0xAA),
                Font = UIFont.SystemFontOfSize(13)
            };
            ContentView.AddSubview(_tracksCountLabel);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _coverImageView.LeadingAnchor.ConstraintEqualTo(ContentView.LeadingAnchor, 12),
                _coverImageView.CenterYAnchor.ConstraintEqualTo(ContentView.CenterYAnchor),
                _coverImageView.WidthAnchor.ConstraintEqualTo(55),
                _coverImageView.HeightAnchor.ConstraintEqualTo(55),

                _titleLabel.TopAnchor.ConstraintEqualTo(ContentView.TopAnchor, 12),
                _titleLabel.LeadingAnchor.ConstraintEqualTo(_coverImageView.TrailingAnchor, 12),
                _titleLabel.TrailingAnchor.ConstraintEqualTo(ContentView.TrailingAnchor, -12),

                _tracksCountLabel.TopAnchor.ConstraintEqualTo(_titleLabel.BottomAnchor, 4),
                _tracksCountLabel.LeadingAnchor.ConstraintEqualTo(_coverImageView.TrailingAnchor, 12),
                _tracksCountLabel.TrailingAnchor.ConstraintEqualTo(ContentView.TrailingAnchor, -12),
                _tracksCountLabel.BottomAnchor.ConstraintEqualTo(ContentView.BottomAnchor, -12)
            });
        }

        public void Update(string title, int tracksCount, UIImage cover)
        {
            _titleLabel.Text = title;
            _tracksCountLabel.Text = $"{tracksCount} треков";
            _coverImageView.Image = cover ?? UIImage.GetSystemImage("music.note.list");
        }
    }
}
using UIKit;

namespace Werhes.Vkz.iOS.Views
{
    public class AlbumCell : UICollectionViewCell
    {
        public static readonly NSString CellId = new NSString("AlbumCell");

        private readonly UIImageView _imageView;
        private readonly UILabel _titleLabel;

        public AlbumCell() : base()
        {
            BackgroundColor = UIColor.Clear;

            _imageView = new UIImageView
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                ContentMode = UIViewContentMode.ScaleAspectFill,
                ClipsToBounds = true,
                Layer = { CornerRadius = 6 }
            };
            ContentView.AddSubview(_imageView);

            _titleLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.White,
                Font = UIFont.SystemFontOfSize(13),
                TextAlignment = UITextAlignment.Center,
                Lines = 2
            };
            ContentView.AddSubview(_titleLabel);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _imageView.TopAnchor.ConstraintEqualTo(ContentView.TopAnchor),
                _imageView.LeadingAnchor.ConstraintEqualTo(ContentView.LeadingAnchor),
                _imageView.TrailingAnchor.ConstraintEqualTo(ContentView.TrailingAnchor),
                _imageView.HeightAnchor.ConstraintEqualTo(ContentView.WidthAnchor),

                _titleLabel.TopAnchor.ConstraintEqualTo(_imageView.BottomAnchor, 6),
                _titleLabel.LeadingAnchor.ConstraintEqualTo(ContentView.LeadingAnchor, 4),
                _titleLabel.TrailingAnchor.ConstraintEqualTo(ContentView.TrailingAnchor, -4),
                _titleLabel.BottomAnchor.ConstraintEqualTo(ContentView.BottomAnchor, -4)
            });
        }

        public void Update(string title, UIImage image)
        {
            _titleLabel.Text = title;
            _imageView.Image = image ?? UIImage.GetSystemImage("music.note.list");
        }
    }
}
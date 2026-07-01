using UIKit;

namespace Werhes.Vkz.iOS.Views
{
    public class ArtistCell : UICollectionViewCell
    {
        public static readonly NSString CellId = new NSString("ArtistCell");

        private readonly UIImageView _imageView;
        private readonly UILabel _nameLabel;

        public ArtistCell() : base()
        {
            BackgroundColor = UIColor.Clear;

            _imageView = new UIImageView
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                ContentMode = UIViewContentMode.ScaleAspectFill,
                ClipsToBounds = true,
                Layer = { CornerRadius = 35 }
            };
            ContentView.AddSubview(_imageView);

            _nameLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.White,
                Font = UIFont.SystemFontOfSize(13),
                TextAlignment = UITextAlignment.Center,
                Lines = 2
            };
            ContentView.AddSubview(_nameLabel);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _imageView.TopAnchor.ConstraintEqualTo(ContentView.TopAnchor),
                _imageView.CenterXAnchor.ConstraintEqualTo(ContentView.CenterXAnchor),
                _imageView.WidthAnchor.ConstraintEqualTo(70),
                _imageView.HeightAnchor.ConstraintEqualTo(70),

                _nameLabel.TopAnchor.ConstraintEqualTo(_imageView.BottomAnchor, 6),
                _nameLabel.LeadingAnchor.ConstraintEqualTo(ContentView.LeadingAnchor, 4),
                _nameLabel.TrailingAnchor.ConstraintEqualTo(ContentView.TrailingAnchor, -4),
                _nameLabel.BottomAnchor.ConstraintEqualTo(ContentView.BottomAnchor, -4)
            });
        }

        public void Update(string name, UIImage image)
        {
            _nameLabel.Text = name;
            _imageView.Image = image ?? UIImage.GetSystemImage("person.circle.fill");
        }
    }
}
using UIKit;

namespace Werhes.Vkz.iOS.Views
{
    public class RecommendationCell : UICollectionViewCell
    {
        public static readonly NSString CellId = new NSString("RecommendationCell");

        private readonly UIImageView _imageView;
        private readonly UILabel _titleLabel;

        public RecommendationCell() : base()
        {
            BackgroundColor = UIColor.FromRGB(0x2D, 0x2D, 0x2D);
            Layer.CornerRadius = 8;
            ClipsToBounds = true;

            _imageView = new UIImageView
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                ContentMode = UIViewContentMode.ScaleAspectFill,
                ClipsToBounds = true
            };
            ContentView.AddSubview(_imageView);

            _titleLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.White,
                Font = UIFont.SystemFontOfSize(14, UIFontWeight.Medium),
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

                _titleLabel.TopAnchor.ConstraintEqualTo(_imageView.BottomAnchor, 8),
                _titleLabel.LeadingAnchor.ConstraintEqualTo(ContentView.LeadingAnchor, 8),
                _titleLabel.TrailingAnchor.ConstraintEqualTo(ContentView.TrailingAnchor, -8),
                _titleLabel.BottomAnchor.ConstraintEqualTo(ContentView.BottomAnchor, -8)
            });
        }

        public void Update(string title, UIImage image)
        {
            _titleLabel.Text = title;
            _imageView.Image = image ?? UIImage.GetSystemImage("music.note");
        }
    }
}
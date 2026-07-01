using UIKit;

namespace Werhes.Vkz.iOS.Services
{
    public static class MiniPlayerService
    {
        public static UIView MiniPlayer { get; set; }
        public static UILabel TitleLabel { get; set; }
        public static UILabel ArtistLabel { get; set; }
        public static UIImageView CoverImageView { get; set; }
        public static UIButton PlayPauseButton { get; set; }

        public static void UpdateMiniPlayer(string title, string artist, UIImage cover)
        {
            if (TitleLabel != null)
                TitleLabel.Text = title;
            if (ArtistLabel != null)
                ArtistLabel.Text = artist;
            if (CoverImageView != null)
                CoverImageView.Image = cover ?? UIImage.GetSystemImage("music.note");
        }
    }
}
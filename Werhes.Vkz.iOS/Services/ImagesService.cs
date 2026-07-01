using System;
using System.Threading.Tasks;
using Foundation;
using UIKit;

namespace Werhes.Vkz.iOS.Services
{
    public static class ImagesService
    {
        public static async Task<UIImage> LoadImageAsync(string url)
        {
            if (string.IsNullOrEmpty(url)) return null;

            try
            {
                using var nsUrl = new NSUrl(url);
                using var data = await NSData.FromUrlAsync(nsUrl);
                if (data != null)
                    return UIImage.LoadFromData(data);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Image load error: {ex.Message}");
            }

            return null;
        }

        public static string BannerArtist(Core.Interfaces.IArtist artist)
        {
            // Возвращает URL баннера исполнителя
            return artist?.Cover ?? "";
        }

        public static UIImage GetPlaceholder()
        {
            return UIImage.GetSystemImage("music.note");
        }
    }
}
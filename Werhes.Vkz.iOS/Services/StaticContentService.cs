using System.Collections.Generic;
using Werhes.Vkz.iOS.Models;

namespace Werhes.Vkz.iOS.Services
{
    public static class StaticContentService
    {
        public static bool RepeatPlaylist { get; set; } = false;
        public static bool RepeatTrack { get; set; } = false;
        public static List<Track> NowPlay { get; set; }
        public static Album CurrentAlbum { get; set; }
    }
}
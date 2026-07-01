using System.Collections.Generic;

namespace Werhes.Vkz.iOS.Models
{
    public class Album : Core.Models.Album
    {
        public long Id { get; set; }
        public string Cover { get; set; }
        public List<Track> Tracks { get; set; }
    }
}
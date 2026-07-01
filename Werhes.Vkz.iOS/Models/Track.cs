using System.Collections.Generic;

namespace Werhes.Vkz.iOS.Models
{
    public class Track : Core.Models.Track
    {
        public string Url { get; set; }
        public Album Album { get; set; }
    }
}
using System.Collections.Generic;
using System.Linq;
using Werhes.Vkz.iOS.Models;

namespace Werhes.Vkz.iOS.Converters
{
    public static class TracksConverter
    {
        public static List<Track> ConvertToAudioFile(this List<Core.Interfaces.ITrack> tracks)
        {
            return tracks.Select(t => new Track
            {
                Title = t.Title,
                Artist = t.Artist.Name,
                Url = t.Url?.ToString() ?? "",
                Album = t.Album != null ? new Album
                {
                    Id = t.Album.Id,
                    Title = t.Album.Title,
                    Cover = t.Album.Cover
                } : null
            }).ToList();
        }
    }
}
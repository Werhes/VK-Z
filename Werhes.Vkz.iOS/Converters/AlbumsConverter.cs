using System.Collections.Generic;
using System.Linq;
using Werhes.Vkz.iOS.Models;

namespace Werhes.Vkz.iOS.Converters
{
    public static class AlbumsConverter
    {
        public static List<Album> CovertToPlaylistFiles(this List<Core.Interfaces.IAlbum> albums)
        {
            return albums.Select(a => new Album
            {
                Id = a.Id,
                Title = a.Title,
                Cover = a.Cover,
                Tracks = a.Tracks?.Select(t => new Track
                {
                    Title = t.Title,
                    Artist = t.Artist.Name,
                    Url = t.Url?.ToString() ?? "",
                    Album = new Album { Id = a.Id, Title = a.Title, Cover = a.Cover }
                }).ToList() ?? new List<Track>()
            }).ToList();
        }
    }
}
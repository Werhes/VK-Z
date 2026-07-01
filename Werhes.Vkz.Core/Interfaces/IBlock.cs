using System;
using System.Collections.Generic;
using System.Text;
using Werhes.Vkz.Core.Models.Music.BlockInfo;

namespace Werhes.Vkz.Core.Interfaces
{
    public interface IBlock
    {
        string Title { get; set; }
        string Subtitle { get; set; }
        long Count { get; set; }
        string Type { get; set; }
        string Source { get; set; }
        string Id { get; set; }
        List<ITrack> Tracks { get; set; }
        List<IAlbum> Albums { get; set; }
        List<SearchArtistBlockInfo> Artists { get; set; }
        
    }
}

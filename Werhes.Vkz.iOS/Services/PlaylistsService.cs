using System.Collections.Generic;
using System.Threading.Tasks;
using Werhes.Vkz.iOS.Converters;
using Werhes.Vkz.iOS.Models;

namespace Werhes.Vkz.iOS.Services
{
    public static class PlaylistsService
    {
        public static async Task<List<Album>> GetPlaylistsAsync()
        {
            var playlistsVk = await Task.Run(() =>
                Werhes.Vkz.Core.VKontakte.Music.Library.PlaylistsSync(20));
            return playlistsVk.CovertToPlaylistFiles();
        }

        public static async Task<List<Track>> GetTracksAsync(int count = 50, int offset = 0)
        {
            var tracksVk = await Task.Run(() =>
                Werhes.Vkz.Core.VKontakte.Music.Library.TracksSync(count, offset));
            return tracksVk.ConvertToAudioFile();
        }
    }
}
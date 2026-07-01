using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using Android.Provider;
using Werhes.Vkz.AndroidApp.Converters;
using Werhes.Vkz.AndroidApp.Models;
using Werhes.Vkz.Core.Interfaces;

namespace Werhes.Vkz.AndroidApp.Services
{
    public static class MusicService
    {

        public static List<Track> GetLocal()
        {
            var tracks = new List<Track>();
            string dir = Android.OS.Environment.GetExternalStoragePublicDirectory(Android.OS.Environment.DirectoryMusic).ToString();
            var files = Directory.GetFiles(dir);
            foreach (var track in files)
            {

            }

            return tracks;

        }

        public  static List<Track> GetMusicLibrary(int count, int offset)
        {
            //TODO: получение библиотеки
            //var tracksvk = Werhes.Vkz.Core.VKontakte.Music.Library.TracksSync(count, offset);
            /*var tracks = tracksvk.ConvertToAudioFile();
            return tracks;*/
            return null;
        }

        public static List<Track> ConvertToAudioFile(this IList<ITrack> music, string cover = null)
        {
            var tracks = new List<Track>();

            foreach (var track in music)
            {
                string coverImage;

                if (cover == null)
                {
                    if (track.Album.Cover is null)
                    {
                        coverImage = "placeholder";
                    }
                    else
                    {
                        coverImage =  ImagesService.CoverTrack(track);
                    }
                }
                else
                {
                    coverImage = cover;
                }


                var audiofile = track.ToTrack();
                audiofile.Album.Cover = coverImage;

                tracks.Add(audiofile);
            }

            return tracks;

        }
    }
}
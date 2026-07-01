using System;
using Werhes.Vkz.iOS.Models;

namespace Werhes.Vkz.iOS.Services
{
    public class PlayerService
    {
        public PlayingService MainService { get; }
        private static PlayerService _instance;

        public string Title { get; set; }
        public string Artist { get; set; }
        public string Cover { get; set; }
        public Track CurrentAudioFile { get; set; }

        public static PlayerService Instance => _instance ?? (_instance = new PlayerService());

        private PlayerService()
        {
            MainService = new PlayingService();
            MainService.CurrentAudioChanged += (s, args) =>
            {
                Title = args.Title;
                Artist = args.Artist;
                Cover = args.Album?.Cover;
                CurrentAudioFile = args;

                MiniPlayerService.UpdateMiniPlayer(Title, Artist, null);
            };
        }

        public void Play(Album playlist = null, Track audio = null)
        {
            try
            {
                StaticContentService.NowPlay = playlist?.Tracks;
                MainService.Play(playlist, audio);
            }
            catch (Exception e)
            {
                Console.WriteLine($"Play error: {e}");
            }
        }

        public void Pause()
        {
            MainService.Pause();
        }
    }
}
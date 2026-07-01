using System;
using System.Collections.Generic;

namespace Werhes.Vkz.iOS.Models
{
    public class AudioPlaylist
    {
        private readonly List<Track> _tracks;
        private int _currentIndex;
        private readonly bool _repeatPlaylist;
        private readonly bool _repeatTrack;

        public event EventHandler<Track> OnCurrentItemChanged;

        public AudioPlaylist(Album album, Track startTrack, bool repeatPlaylist, bool repeatTrack)
        {
            _tracks = album.Tracks;
            _repeatPlaylist = repeatPlaylist;
            _repeatTrack = repeatTrack;
            _currentIndex = _tracks.IndexOf(startTrack);
            if (_currentIndex < 0) _currentIndex = 0;
        }

        public void SetCurrentTrack(Track track)
        {
            _currentIndex = _tracks.IndexOf(track);
            if (_currentIndex < 0) _currentIndex = 0;
        }

        public void Next(bool auto)
        {
            if (_repeatTrack && auto) return;
            _currentIndex++;
            if (_currentIndex >= _tracks.Count)
            {
                if (_repeatPlaylist) _currentIndex = 0;
                else return;
            }
            OnCurrentItemChanged?.Invoke(this, _tracks[_currentIndex]);
        }

        public void Back()
        {
            _currentIndex--;
            if (_currentIndex < 0)
            {
                if (_repeatPlaylist) _currentIndex = _tracks.Count - 1;
                else _currentIndex = 0;
            }
            OnCurrentItemChanged?.Invoke(this, _tracks[_currentIndex]);
        }
    }
}
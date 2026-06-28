using System;
using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
using VKZ.Models;
using VKZ.Properties;
using VKZ.Services;

namespace VKZ
{
    public partial class MainWindow : Window
    {

        public MainWindow()
        {
            InitializeComponent();

            var player = AudioPlayerService.Instance;
            player.TrackChanged += OnTrackChanged;
            player.StateChanged += OnStateChanged;
            player.ProgressChanged += OnProgressChanged;
            player.DurationChanged += OnDurationChanged;

            if (!string.IsNullOrEmpty(Settings.Default.AccessToken) && Settings.Default.UserId > 0)
            {
                UserInfoText.Text = $"ID: {Settings.Default.UserId}";
                AuthButton.Content = "Сменить аккаунт";
            }

            // Subscribe to auth success
            AuthViewControl.OnAuthSuccess += OnAuthSuccessHandler;
        }

        private void OnTrackChanged(VKTrack? track)
        {
            Dispatcher.Invoke(() =>
            {
                if (track != null)
                {
                    NowPlayingTitle.Text = track.Title;
                    NowPlayingArtist.Text = track.Artist;
                }
                else
                {
                    NowPlayingTitle.Text = "Нет трека";
                    NowPlayingArtist.Text = "";
                }
            });
        }

        private void OnStateChanged(PlayerState state)
        {
            Dispatcher.Invoke(() =>
            {
                PlayPauseButton.Content = state switch
                {
                    PlayerState.Playing => "⏸",
                    PlayerState.Loading => "⏳",
                    _ => "▶"
                };
            });
        }

        private void OnProgressChanged(double position)
        {
            Dispatcher.Invoke(() =>
            {
                ProgressSlider.Value = position;
                CurrentTimeText.Text = TimeSpan.FromSeconds(position).ToString(@"m\:ss");
            });
        }

        private void OnDurationChanged(double duration)
        {
            Dispatcher.Invoke(() =>
            {
                ProgressSlider.Maximum = duration;
                DurationText.Text = TimeSpan.FromSeconds(duration).ToString(@"m\:ss");
            });
        }

        private void OnNavChanged(object sender, RoutedEventArgs e)
        {
            if (!(sender is RadioButton rb)) return;

            AuthViewControl.Visibility = Visibility.Collapsed;
            PlaylistsViewControl.Visibility = Visibility.Collapsed;
            SearchViewControl.Visibility = Visibility.Collapsed;
            MixViewControl.Visibility = Visibility.Collapsed;
            PopularViewControl.Visibility = Visibility.Collapsed;

            if (rb == NavPlaylists) PlaylistsViewControl.Visibility = Visibility.Visible;
            else if (rb == NavSearch) SearchViewControl.Visibility = Visibility.Visible;
            else if (rb == NavMix) MixViewControl.Visibility = Visibility.Visible;
            else if (rb == NavPopular) PopularViewControl.Visibility = Visibility.Visible;
        }

        private void AuthButton_Click(object sender, RoutedEventArgs e)
        {
            AuthViewControl.Visibility = Visibility.Visible;
            PlaylistsViewControl.Visibility = Visibility.Collapsed;
            SearchViewControl.Visibility = Visibility.Collapsed;
            MixViewControl.Visibility = Visibility.Collapsed;
            PopularViewControl.Visibility = Visibility.Collapsed;
        }

        private void OnAuthSuccessHandler()
        {
            Dispatcher.Invoke(() =>
            {
                UserInfoText.Text = $"ID: {Settings.Default.UserId}";
                AuthButton.Content = "Сменить аккаунт";
                AuthViewControl.Visibility = Visibility.Collapsed;
                PlaylistsViewControl.Visibility = Visibility.Visible;
                NavPlaylists.IsChecked = true;
            });
        }

        private void PlayPauseButton_Click(object sender, RoutedEventArgs e)
        {
            AudioPlayerService.Instance.PlayPause();
        }

        private void NextButton_Click(object sender, RoutedEventArgs e)
        {
            AudioPlayerService.Instance.Next();
        }

        private void PrevButton_Click(object sender, RoutedEventArgs e)
        {
            AudioPlayerService.Instance.Previous();
        }

        private void ProgressSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            AudioPlayerService.Instance.Seek(e.NewValue);
        }

        private void VolumeButton_Click(object sender, RoutedEventArgs e)
        {
            var player = AudioPlayerService.Instance;
            player.SetVolume(player.Volume > 0 ? 0 : 0.8);
            VolumeButton.Content = player.Volume > 0 ? "🔊" : "🔇";
        }

        protected override void OnClosing(CancelEventArgs e)
        {
            Settings.Default.Save();
            base.OnClosing(e);
        }
    }
}
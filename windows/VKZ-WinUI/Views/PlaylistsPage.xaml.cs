using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using VKZ.Models;
using VKZ.Services;

namespace VKZ.Views
{
    public sealed partial class PlaylistsPage : Page
    {
        private readonly VKApiService _apiService;
        private readonly AudioPlayerService _playerService;
        private readonly ObservableCollection<VKPlaylist> _playlists = new();

        public PlaylistsPage()
        {
            this.InitializeComponent();

            _apiService = App.GetService<VKApiService>();
            _playerService = App.GetService<AudioPlayerService>();

            PlaylistsListView.ItemsSource = _playlists;
            PlaylistsListView.ItemClick += OnPlaylistClick;
            PlaylistsListView.IsItemClickEnabled = true;
        }

        protected override async void OnNavigatedTo(Microsoft.UI.Xaml.Navigation.NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);
            await LoadPlaylists();
        }

        private async Task LoadPlaylists()
        {
            SetLoading(true);

            try
            {
                // Загружаем информацию о пользователе
                var user = await _apiService.GetCurrentUserAsync();
                if (user != null)
                {
                    UserInfoText.Text = $"{user.FullName}";
                }

                var playlists = await _apiService.GetPlaylists();
                _playlists.Clear();
                foreach (var playlist in playlists)
                {
                    _playlists.Add(playlist);
                }

                EmptyText.Visibility = _playlists.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to load playlists: {ex.Message}");
                EmptyText.Text = "Ошибка загрузки плейлистов";
                EmptyText.Visibility = Visibility.Visible;
            }
            finally
            {
                SetLoading(false);
            }
        }

        private async void OnPlaylistClick(object sender, ItemClickEventArgs e)
        {
            if (e.ClickedItem is VKPlaylist playlist)
            {
                // Загружаем треки плейлиста и открываем их
                try
                {
                    var tracks = await _apiService.GetPlaylistTracks(
                        playlist.Id,
                        playlist.OwnerId,
                        playlist.AccessKey);

                    if (tracks.Count > 0)
                    {
                        _playerService.SetQueue(tracks, 0);
                        await _playerService.Play(0);
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Failed to load playlist tracks: {ex.Message}");
                }
            }
        }

        private void OnContainerContentChanging(ListViewBase sender, ContainerContentChangingEventArgs args)
        {
            // Оптимизация рендеринга списка
        }

        private void SetLoading(bool isLoading)
        {
            LoadingRing.IsActive = isLoading;
            LoadingRing.Visibility = isLoading ? Visibility.Visible : Visibility.Collapsed;
        }
    }
}
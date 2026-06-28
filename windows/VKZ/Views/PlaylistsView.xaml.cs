using System.Collections.ObjectModel;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using VKZ.Models;
using VKZ.Services;

namespace VKZ.Views
{
    public partial class PlaylistsView : UserControl
    {
        public ObservableCollection<VKPlaylist> Playlists { get; } = new();

        public PlaylistsView()
        {
            InitializeComponent();
            DataContext = this;
            Loaded += OnLoaded;
        }

        private async void OnLoaded(object sender, RoutedEventArgs e)
        {
            if (Playlists.Count > 0) return;

            try
            {
                var api = VKApiService.Instance;
                var ownerId = api.UserId ?? 0;
                var playlists = await api.GetPlaylistsAsync(ownerId, 50);
                
                Playlists.Clear();
                foreach (var playlist in playlists)
                {
                    Playlists.Add(playlist);
                }

                PlaylistsList.ItemsSource = Playlists;
            }
            catch (System.Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error loading playlists: {ex.Message}");
            }
        }
    }
}
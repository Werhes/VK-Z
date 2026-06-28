using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;
using VKZ.Models;
using VKZ.Services;

namespace VKZ.Views
{
    public partial class PopularView : UserControl
    {
        public ObservableCollection<VKTrack> PopularTracks { get; } = new();

        public PopularView()
        {
            InitializeComponent();
            DataContext = this;
            Loaded += OnLoaded;
        }

        private async void OnLoaded(object sender, RoutedEventArgs e)
        {
            if (PopularTracks.Count > 0) return;

            try
            {
                var tracks = await VKApiService.Instance.GetPopularAsync(50);
                PopularTracks.Clear();
                foreach (var track in tracks)
                {
                    PopularTracks.Add(track);
                }
                PopularTracksList.ItemsSource = PopularTracks;
            }
            catch (System.Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error loading popular tracks: {ex.Message}");
            }
        }
    }
}
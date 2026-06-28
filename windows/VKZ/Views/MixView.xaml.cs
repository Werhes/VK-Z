using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;
using VKZ.Models;
using VKZ.Services;

namespace VKZ.Views
{
    public partial class MixView : UserControl
    {
        public ObservableCollection<VKMix> Mixes { get; } = new();

        public MixView()
        {
            InitializeComponent();
            DataContext = this;
            Loaded += OnLoaded;
        }

        private async void OnLoaded(object sender, RoutedEventArgs e)
        {
            if (Mixes.Count > 0) return;

            try
            {
                var mixes = await VKApiService.Instance.GetMixesAsync(20);
                Mixes.Clear();
                foreach (var mix in mixes)
                {
                    Mixes.Add(mix);
                }
                MixesList.ItemsSource = Mixes;
            }
            catch (System.Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error loading mixes: {ex.Message}");
            }
        }
    }
}
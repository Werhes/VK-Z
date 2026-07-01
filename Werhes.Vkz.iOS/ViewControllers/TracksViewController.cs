using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using UIKit;
using Werhes.Vkz.iOS.Converters;
using Werhes.Vkz.iOS.Models;
using Werhes.Vkz.iOS.Services;
using Werhes.Vkz.iOS.Views;

namespace Werhes.Vkz.iOS.ViewControllers
{
    public class TracksViewController : UIViewController
    {
        private UITableView _tableView;
        private List<Track> _tracks;
        private UIActivityIndicatorView _loader;
        private readonly Album _playlist;

        public TracksViewController() : this(null) { }

        public TracksViewController(Album playlist)
        {
            _playlist = playlist;
        }

        public override void ViewDidLoad()
        {
            base.ViewDidLoad();
            Title = "Моя музыка";
            View.BackgroundColor = UIColor.FromRGB(0x21, 0x21, 0x21);

            _tableView = new UITableView
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                BackgroundColor = UIColor.Clear,
                SeparatorColor = UIColor.FromRGB(0x3D, 0x3D, 0x3D),
                TableFooterView = new UIView()
            };
            _tableView.RegisterClass(typeof(TrackCell), TrackCell.CellId);
            _tableView.DataSource = new TracksDataSource(this);
            _tableView.Delegate = new TracksDelegate(this);
            View.AddSubview(_tableView);

            _loader = new UIActivityIndicatorView(UIActivityIndicatorViewStyle.WhiteLarge)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                HidesWhenStopped = true
            };
            View.AddSubview(_loader);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _tableView.TopAnchor.ConstraintEqualTo(View.SafeAreaLayoutGuide.TopAnchor),
                _tableView.BottomAnchor.ConstraintEqualTo(View.SafeAreaLayoutGuide.BottomAnchor),
                _tableView.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor),
                _tableView.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor),
                _loader.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                _loader.CenterYAnchor.ConstraintEqualTo(View.CenterYAnchor)
            });

            LoadTracks();
        }

        private async void LoadTracks()
        {
            _loader.StartAnimating();
            try
            {
                if (_playlist != null)
                {
                    _tracks = _playlist.Tracks;
                    Title = _playlist.Title;
                }
                else
                {
                    _tracks = await PlaylistsService.GetTracksAsync(50, 0);
                }
                _tableView.ReloadData();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Load tracks error: {ex.Message}");
            }
            _loader.StopAnimating();
        }

        private class TracksDataSource : UITableViewDataSource
        {
            private readonly TracksViewController _vc;
            public TracksDataSource(TracksViewController vc) => _vc = vc;

            public override nint RowsInSection(UITableView tableView, nint section) =>
                _vc._tracks?.Count ?? 0;

            public override UITableViewCell GetCell(UITableView tableView, NSIndexPath indexPath)
            {
                var cell = (TrackCell)tableView.DequeueReusableCell(TrackCell.CellId, indexPath);
                var track = _vc._tracks[indexPath.Row];
                cell.Update(track.Title, track.Artist, null);
                return cell;
            }
        }

        private class TracksDelegate : UITableViewDelegate
        {
            private readonly TracksViewController _vc;
            public TracksDelegate(TracksViewController vc) => _vc = vc;

            public override void RowSelected(UITableView tableView, NSIndexPath indexPath)
            {
                tableView.DeselectRow(indexPath, true);
                var track = _vc._tracks[indexPath.Row];
                var album = new Album
                {
                    Id = 0,
                    Title = "Моя музыка",
                    Cover = track.Album?.Cover,
                    Tracks = _vc._tracks
                };
                PlayerService.Instance.Play(album, track);
            }
        }
    }
}
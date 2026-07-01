using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using UIKit;
using Werhes.Vkz.iOS.Models;
using Werhes.Vkz.iOS.Services;
using Werhes.Vkz.iOS.Views;

namespace Werhes.Vkz.iOS.ViewControllers
{
    public class ArtistViewController : UIViewController
    {
        private readonly Artist _artist;
        private UIImageView _coverImageView;
        private UILabel _nameLabel;
        private UITableView _tableView;
        private List<Track> _tracks;
        private UIActivityIndicatorView _loader;

        public ArtistViewController(Artist artist)
        {
            _artist = artist;
        }

        public override void ViewDidLoad()
        {
            base.ViewDidLoad();
            Title = _artist?.Name ?? "Исполнитель";
            View.BackgroundColor = UIColor.FromRGB(0x21, 0x21, 0x21);

            _coverImageView = new UIImageView
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                ContentMode = UIViewContentMode.ScaleAspectFill,
                ClipsToBounds = true,
                Layer = { CornerRadius = 50 }
            };
            View.AddSubview(_coverImageView);

            _nameLabel = new UILabel
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                TextColor = UIColor.White,
                Font = UIFont.SystemFontOfSize(20, UIFontWeight.Bold),
                TextAlignment = UITextAlignment.Center,
                Text = _artist?.Name ?? "Неизвестный исполнитель"
            };
            View.AddSubview(_nameLabel);

            _loader = new UIActivityIndicatorView(UIActivityIndicatorViewStyle.WhiteLarge)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                HidesWhenStopped = true
            };
            View.AddSubview(_loader);

            _tableView = new UITableView
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                BackgroundColor = UIColor.Clear,
                SeparatorColor = UIColor.FromRGB(0x3D, 0x3D, 0x3D),
                TableFooterView = new UIView()
            };
            _tableView.RegisterClass(typeof(TrackCell), TrackCell.CellId);
            _tableView.DataSource = new ArtistTracksDataSource(this);
            _tableView.Delegate = new ArtistTracksDelegate(this);
            View.AddSubview(_tableView);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _coverImageView.TopAnchor.ConstraintEqualTo(View.SafeAreaLayoutGuide.TopAnchor, 20),
                _coverImageView.CenterXAnchor.ConstraintEqualTo(View.CenterXAnchor),
                _coverImageView.WidthAnchor.ConstraintEqualTo(100),
                _coverImageView.HeightAnchor.ConstraintEqualTo(100),

                _nameLabel.TopAnchor.ConstraintEqualTo(_coverImageView.BottomAnchor, 12),
                _nameLabel.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor, 20),
                _nameLabel.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor, -20),

                _tableView.TopAnchor.ConstraintEqualTo(_nameLabel.BottomAnchor, 20),
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
                var tracks = await Task.Run(() =>
                    Core.VKontakte.Music.Artists.GetTracksSync(_artist.Id, 30));
                _tracks = tracks.ConvertToAudioFile();
                _tableView.ReloadData();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Load artist tracks error: {ex.Message}");
            }
            _loader.StopAnimating();
        }

        private class ArtistTracksDataSource : UITableViewDataSource
        {
            private readonly ArtistViewController _vc;
            public ArtistTracksDataSource(ArtistViewController vc) => _vc = vc;

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

        private class ArtistTracksDelegate : UITableViewDelegate
        {
            private readonly ArtistViewController _vc;
            public ArtistTracksDelegate(ArtistViewController vc) => _vc = vc;

            public override void RowSelected(UITableView tableView, NSIndexPath indexPath)
            {
                tableView.DeselectRow(indexPath, true);
                var track = _vc._tracks[indexPath.Row];
                var album = new Album
                {
                    Id = 0,
                    Title = track.Title,
                    Cover = track.Album?.Cover,
                    Tracks = _vc._tracks
                };
                PlayerService.Instance.Play(album, track);
            }
        }
    }
}
using System;
using UIKit;
using Werhes.Vkz.iOS.Services;

namespace Werhes.Vkz.iOS.ViewControllers
{
    public class SettingsViewController : UIViewController
    {
        private UITableView _tableView;
        private readonly string[] _sections = { "Воспроизведение", "Аккаунт", "О приложении" };
        private readonly string[][] _items = {
            new[] { "Повторять плейлист" },
            new[] { "Выйти" },
            new[] { "О VK Z", "Версия 1.0" }
        };

        public override void ViewDidLoad()
        {
            base.ViewDidLoad();
            Title = "Настройки";
            View.BackgroundColor = UIColor.FromRGB(0x21, 0x21, 0x21);

            _tableView = new UITableView(View.Bounds, UITableViewStyle.Grouped)
            {
                TranslatesAutoresizingMaskIntoConstraints = false,
                BackgroundColor = UIColor.Clear,
                SeparatorColor = UIColor.FromRGB(0x3D, 0x3D, 0x3D)
            };
            _tableView.DataSource = new SettingsDataSource(this);
            _tableView.Delegate = new SettingsDelegate(this);
            View.AddSubview(_tableView);

            NSLayoutConstraint.ActivateConstraints(new[]
            {
                _tableView.TopAnchor.ConstraintEqualTo(View.SafeAreaLayoutGuide.TopAnchor),
                _tableView.BottomAnchor.ConstraintEqualTo(View.SafeAreaLayoutGuide.BottomAnchor),
                _tableView.LeadingAnchor.ConstraintEqualTo(View.LeadingAnchor),
                _tableView.TrailingAnchor.ConstraintEqualTo(View.TrailingAnchor)
            });
        }

        private class SettingsDataSource : UITableViewDataSource
        {
            private readonly SettingsViewController _vc;
            public SettingsDataSource(SettingsViewController vc) => _vc = vc;

            public override nint NumberOfSections(UITableView tableView) => _vc._sections.Length;

            public override nint RowsInSection(UITableView tableView, nint section) =>
                _vc._items[section].Length;

            public override string TitleForHeader(UITableView tableView, nint section) =>
                _vc._sections[section];

            public override UITableViewCell GetCell(UITableView tableView, NSIndexPath indexPath)
            {
                var cell = tableView.DequeueReusableCell("SettingsCell")
                    ?? new UITableViewCell(UITableViewCellStyle.Default, "SettingsCell");

                cell.TextLabel.Text = _vc._items[indexPath.Section][indexPath.Row];
                cell.TextLabel.TextColor = UIColor.White;
                cell.BackgroundColor = UIColor.FromRGB(0x2D, 0x2D, 0x2D);
                cell.SelectionStyle = UITableViewCellSelectionStyle.Gray;

                if (indexPath.Section == 0 && indexPath.Row == 0)
                {
                    var repeatSwitch = new UISwitch
                    {
                        On = StaticContentService.RepeatPlaylist,
                        TintColor = UIColor.FromRGB(0x80, 0x80, 0x80),
                        OnTintColor = UIColor.FromRGB(0x80, 0x80, 0x80)
                    };
                    repeatSwitch.ValueChanged += (s, e) =>
                    {
                        StaticContentService.RepeatPlaylist = repeatSwitch.On;
                    };
                    cell.AccessoryView = repeatSwitch;
                }
                else
                {
                    cell.Accessory = UITableViewCellAccessory.DisclosureIndicator;
                }

                return cell;
            }
        }

        private class SettingsDelegate : UITableViewDelegate
        {
            private readonly SettingsViewController _vc;
            public SettingsDelegate(SettingsViewController vc) => _vc = vc;

            public override void RowSelected(UITableView tableView, NSIndexPath indexPath)
            {
                tableView.DeselectRow(indexPath, true);

                if (indexPath.Section == 1 && indexPath.Row == 0)
                {
                    var alert = UIAlertController.Create(
                        "Выход",
                        "Вы уверены, что хотите выйти?",
                        UIAlertControllerStyle.Alert);

                    alert.AddAction(UIAlertAction.Create("Отмена", UIAlertActionStyle.Cancel, null));
                    alert.AddAction(UIAlertAction.Create("Выйти", UIAlertActionStyle.Destructive, _ =>
                    {
                        AuthService.Logout();
                        var splash = new SplashViewController();
                        splash.ModalPresentationStyle = UIModalPresentationStyle.FullScreen;
                        _vc.PresentViewController(splash, true, null);
                    }));

                    _vc.PresentViewController(alert, true, null);
                }
                else if (indexPath.Section == 2 && indexPath.Row == 0)
                {
                    var alert = UIAlertController.Create(
                        "О VK Z",
                        "VK Z — музыкальный плеер для ВКонтакте\n\nРазработчик: Werhes\n\nВерсия: 1.0",
                        UIAlertControllerStyle.Alert);
                    alert.AddAction(UIAlertAction.Create("OK", UIAlertActionStyle.Default, null));
                    _vc.PresentViewController(alert, true, null);
                }
            }

            public override UIView GetViewForHeader(UITableView tableView, nint section)
            {
                var header = new UILabel
                {
                    Text = _vc._sections[section],
                    TextColor = UIColor.FromRGB(0xAA, 0xAA, 0xAA),
                    Font = UIFont.SystemFontOfSize(14, UIFontWeight.Medium),
                    BackgroundColor = UIColor.Clear
                };
                return header;
            }

            public override nfloat GetHeightForHeader(UITableView tableView, nint section) => 40;
        }
    }
}
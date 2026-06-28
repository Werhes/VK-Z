using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Data;
using System;
using System.Globalization;

namespace VKZ.Converters
{
    /// <summary>
    /// Конвертирует длительность в секундах в формат mm:ss.
    /// </summary>
    public class DurationConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            if (value is double seconds)
            {
                var ts = TimeSpan.FromSeconds(seconds);
                return ts.Hours > 0
                    ? $"{ts.Hours}:{ts.Minutes:D2}:{ts.Seconds:D2}"
                    : $"{ts.Minutes}:{ts.Seconds:D2}";
            }
            return "0:00";
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }

    /// <summary>
    /// Конвертирует булево значение в Visibility (true = Visible, false = Collapsed).
    /// </summary>
    public class BoolToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            if (value is bool boolValue)
            {
                bool invert = parameter?.ToString() == "invert";
                bool result = invert ? !boolValue : boolValue;
                return result ? Visibility.Visible : Visibility.Collapsed;
            }
            return Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }

    /// <summary>
    /// Конвертирует PlayerState в булево значение (Playing = true).
    /// </summary>
    public class PlayerStateToBoolConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            if (value is Models.PlayerState state)
            {
                return state == Models.PlayerState.Playing;
            }
            return false;
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }

    /// <summary>
    /// Конвертирует PlayerRepeatMode в иконку повтора.
    /// </summary>
    public class RepeatModeToIconConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            if (value is Models.PlayerRepeatMode mode)
            {
                return mode switch
                {
                    Models.PlayerRepeatMode.None => "\uE1CD", // Repeat All (серая)
                    Models.PlayerRepeatMode.One => "\uE1CC", // Repeat One
                    Models.PlayerRepeatMode.All => "\uE1CD", // Repeat All (синяя)
                    _ => "\uE1CD"
                };
            }
            return "\uE1CD";
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }

    /// <summary>
    /// Конвертирует число в строку с форматированием (для счётчиков).
    /// </summary>
    public class NumberFormatConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            if (value is int intValue)
            {
                if (intValue >= 1000000)
                    return $"{intValue / 1000000.0:F1}M";
                if (intValue >= 1000)
                    return $"{intValue / 1000.0:F1}K";
                return intValue.ToString();
            }
            return "0";
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }

    /// <summary>
    /// Конвертирует процент (0.0-1.0) в ширину для прогресс-бара.
    /// </summary>
    public class ProgressToWidthConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            if (value is double progress && parameter is string widthStr)
            {
                if (double.TryParse(widthStr, out double width))
                {
                    return progress * width;
                }
            }
            return 0.0;
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }
}
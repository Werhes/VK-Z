namespace Werhes.Vkz.iOS.Converters
{
    public static class TimeSpanConverter
    {
        public static string ToTimeString(this System.TimeSpan time)
        {
            return time.Hours > 0
                ? $"{time.Hours}:{time.Minutes:D2}:{time.Seconds:D2}"
                : $"{time.Minutes}:{time.Seconds:D2}";
        }
    }
}
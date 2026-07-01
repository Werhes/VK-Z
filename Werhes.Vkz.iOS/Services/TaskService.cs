using System;
using Foundation;

namespace Werhes.Vkz.iOS.Services
{
    public static class TaskService
    {
        public static void RunOnUI(Action action)
        {
            NSRunLoop.Main.BeginInvokeOnMainThread(action);
        }

        public static void RunInBackground(Action action)
        {
            System.Threading.ThreadPool.QueueUserWorkItem(_ => action());
        }
    }
}
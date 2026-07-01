using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace Werhes.Vkz.Core
{
    public interface ILoggerService
    {
        void Info(object msg);
        void Trace(object msg);
        void Error(object msg, Exception e);
        Task SaveLog();
    }
}

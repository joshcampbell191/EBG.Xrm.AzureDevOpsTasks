//using Microsoft.Xrm.Sdk;

namespace EBG.Xrm.PowerShell.Cmdlets
{
    public interface ILogger
    {
        void LogVerbose(string format, params object[] args);
        void LogInformation(string format, params object[] args);
        void LogWarning(string format, params object[] args);
        void LogError(string format, params object[] args);
    }
}

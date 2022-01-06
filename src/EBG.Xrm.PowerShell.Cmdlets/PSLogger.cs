using System;
using System.Management.Automation;

namespace EBG.Xrm.PowerShell.Cmdlets
{
    internal class PSLogger : ILogger
    {
        #region Properties

        protected CommandBase XrmCmdlet
        {
            get;
            set;
        }

        #endregion

        #region Constructors

        public PSLogger(CommandBase xrmCmdlet)
        {
            XrmCmdlet = xrmCmdlet;
            XrmCmdlet.WriteVerbose(string.Format("PS Version: {0}", GetPSVersion().ToString()));
            if (GetPSVersion().Major < 5)
            {
                XrmCmdlet.WriteVerbose("Switching to Console.WriteLine instead of WriteInformation due to PS Version");
            }
        }

        #endregion

        #region ILogger

        public void LogError(string format, params object[] args)
        {
            string message = (args.Length > 0) ? string.Format(format, args) : format;
            ErrorRecord error = new ErrorRecord(
                new Exception(message),
                "EBG.Xrm.AzureDevOpsTasks", ErrorCategory.WriteError, null);
            XrmCmdlet.WriteError(error);
        }

        public void LogInformation(string format, params object[] args)
        {
            string message = (args.Length > 0) ? string.Format(format, args) : format;
            if (GetPSVersion().Major < 5)
            {
                Console.WriteLine(message);
            }
            else
            {
                XrmCmdlet.WriteInformation(message, new string[] { "EBG.Xrm.AzureDevOpsTasks" });
            }
        }

        public void LogVerbose(string format, params object[] args)
        {
            string message = (args.Length > 0) ? string.Format(format, args) : format;
            XrmCmdlet.WriteVerbose(message);
        }

        public void LogWarning(string format, params object[] args)
        {
            string message = (args.Length > 0) ? string.Format(format, args) : format;
            XrmCmdlet.WriteWarning(message);
        }

        #endregion

        #region Private Methods

        private Version GetPSVersion()
        {
            return XrmCmdlet.CommandRuntime.Host.Version;
        }

        #endregion
    }
}

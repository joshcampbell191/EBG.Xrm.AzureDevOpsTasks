
using System.Management.Automation;
//using Microsoft.Xrm.Sdk;

namespace EBG.Xrm.PowerShell.Cmdlets
{
    public abstract class CommandBase : PSCmdlet
    {
        protected virtual ILogger Logger { get; set; }

        protected override void BeginProcessing()
        {
            base.BeginProcessing();

            Logger = new PSLogger(this);
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }
    }
}

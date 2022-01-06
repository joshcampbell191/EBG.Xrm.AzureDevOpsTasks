using System;
using System.Linq;
using System.IO;
using System.Management.Automation;
using System.Reflection;

namespace EBG.Xrm.PowerShell.Cmdlets
{
    [Cmdlet("Invoke", "EarlyBoundGenerator")]
    public class InvokeEarlyBoundGeneratorCommand : CommandBase
    {
        /// <summary>
        /// <para type="description">The connectionstring to the crm organization (see https://msdn.microsoft.com/en-us/library/mt608573.aspx ).</para>
        /// </summary>
        [Parameter(Mandatory = true)]
        public string ConnectionString { get; set; }

        /// <summary>
        ///
        /// </summary>
        [Parameter(Mandatory = true)]
        public string SettingsPath { get; set; }

        /// <summary>
        ///
        /// </summary>
        [Parameter(Mandatory = true)]
        public string CreationType { get; set; }

        /// <summary>
        ///
        /// </summary>
        [Parameter(Mandatory = true)]
        public string EarlyBoundGeneratorApiPath { get; set; }

        protected override void ProcessRecord()
        {
            base.ProcessRecord();

            Logger.LogInformation(string.Format("Invoking the early bound generator"));

            Logger.LogVerbose($"SettingsPath: {SettingsPath}");
            Logger.LogVerbose($"CreationType: {CreationType}");
            Logger.LogVerbose($"EarlyBoundGeneratorApiPath: {EarlyBoundGeneratorApiPath}");

            var path = Path.Combine(EarlyBoundGeneratorApiPath, "lib");
            var assemblyPaths = Directory.GetFiles(path, "DLaB.EarlyBoundGenerator.Api.dll", SearchOption.AllDirectories);

            if (!assemblyPaths.Any())
            {
                var message = $"Failed to find 'DLaB.EarlyBoundGenerator.Api.dll' assembly in: {path}";
                Logger.LogError(message);
                throw new FileNotFoundException(message);
            }

            if (assemblyPaths.Length > 1)
            {
                var message = $"Found multiple 'DLaB.EarlyBoundGenerator.Api.dll' assembly in: {path}";
                Logger.LogError(message);
                throw new Exception(message);
            }

            var assemblyPath = assemblyPaths.First();

            var assembly = Assembly.LoadFile(assemblyPath);
            var earlyBoundGeneratorConfigType = assembly.GetType("DLaB.EarlyBoundGenerator.Settings.EarlyBoundGeneratorConfig");
            var configuration = earlyBoundGeneratorConfigType.GetMethod("Load", BindingFlags.Public | BindingFlags.Static).Invoke(null, new[] { SettingsPath });

            var relativeRootPath = Path.Combine(EarlyBoundGeneratorApiPath, "content", "bin");
            var relativePath = Path.Combine("DLaB.EarlyBoundGenerator", "CrmSvcUtil.exe");
            var rootPath = Path.GetDirectoryName(Path.GetFullPath(SettingsPath));

            earlyBoundGeneratorConfigType.GetProperty("ConnectionString", BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty).SetValue(configuration, ConnectionString);
            earlyBoundGeneratorConfigType.GetProperty("CrmSvcUtilRelativeRootPath", BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty).SetValue(configuration, relativeRootPath);
            earlyBoundGeneratorConfigType.GetProperty("CrmSvcUtilRelativePath", BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty).SetValue(configuration, relativePath);
            earlyBoundGeneratorConfigType.GetProperty("RootPath", BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty).SetValue(configuration, rootPath);
            earlyBoundGeneratorConfigType.GetProperty("SupportsActions", BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty).SetValue(configuration, true);
            earlyBoundGeneratorConfigType.GetProperty("UseConnectionString", BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty).SetValue(configuration, true);

            var logicType = assembly.GetType("DLaB.EarlyBoundGenerator.Logic");
            var logic = Activator.CreateInstance(logicType, configuration);

            var loggerType = assembly.GetType("DLaB.Log.Logger");
            var logger = loggerType.GetProperty("Instance", BindingFlags.Public | BindingFlags.Static).GetValue(null);

            var onLog = loggerType.GetEvent("OnLog");
            onLog.AddEventHandler(logger, (Action<object>)(logMessageInfo =>
            {
                var detail = logMessageInfo.GetType()
                    .GetProperty("Detail", BindingFlags.Public | BindingFlags.Instance | BindingFlags.GetProperty)
                    .GetValue(logMessageInfo)
                    .ToString();

                Logger.LogInformation(detail);
            }));

            switch (CreationType)
            {
                case "all":
                    logicType.GetMethod("ExecuteAll", BindingFlags.Public | BindingFlags.Instance).Invoke(logic, null);
                    break;
                case "actions":
                    logicType.GetMethod("CreateActions", BindingFlags.Public | BindingFlags.Instance).Invoke(logic, null);
                    break;
                case "entities":
                    logicType.GetMethod("CreateEntities", BindingFlags.Public | BindingFlags.Instance).Invoke(logic, null);
                    break;
                case "optionsets":
                    logicType.GetMethod("CreateOptionSets", BindingFlags.Public | BindingFlags.Instance).Invoke(logic, null);
                    break;
                default:
                    break;
            }

            Logger.LogInformation("Early bound generation completed");
        }
    }
}

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
        public bool ExecuteAsync { get; set; }

        /// <summary>
        ///
        /// </summary>
        [Parameter(Mandatory = true)]
        public string EarlyBoundGeneratorApiPath { get; set; }

        protected override void ProcessRecord()
        {
            base.ProcessRecord();

            Logger.LogInformation("Invoking the early bound generator");

            Logger.LogVerbose($"SettingsPath: {SettingsPath}");
            Logger.LogVerbose($"CreationType: {CreationType}");
            Logger.LogVerbose($"ExecuteAsync: {ExecuteAsync}");
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
            var configuration = InvokeMethod(earlyBoundGeneratorConfigType, "Load", BindingFlags.Public | BindingFlags.Static, null, new [] { SettingsPath });

            var relativeRootPath = Path.Combine(EarlyBoundGeneratorApiPath, "content", "bin");
            var relativePath = Path.Combine("DLaB.EarlyBoundGenerator", "CrmSvcUtil.exe");
            var rootPath = Path.GetDirectoryName(Path.GetFullPath(SettingsPath));

            earlyBoundGeneratorConfigType.GetProperty("ConnectionString", BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty).SetValue(configuration, ConnectionString);
            earlyBoundGeneratorConfigType.GetProperty("CrmSvcUtilRelativeRootPath", BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty).SetValue(configuration, relativeRootPath);
            earlyBoundGeneratorConfigType.GetProperty("CrmSvcUtilRelativePath", BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty).SetValue(configuration, relativePath);
            earlyBoundGeneratorConfigType.GetProperty("RootPath", BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty).SetValue(configuration, rootPath);
            earlyBoundGeneratorConfigType.GetProperty("SupportsActions", BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty).SetValue(configuration, true);
            earlyBoundGeneratorConfigType.GetProperty("UseConnectionString", BindingFlags.Public | BindingFlags.Instance | BindingFlags.SetProperty).SetValue(configuration, true);

            if (!ExecuteAsync)
            {
                var loggerType = assembly.GetType("DLaB.Log.Logger");
                RegisterOnLog(loggerType);
            }

            var logicType = assembly.GetType("DLaB.EarlyBoundGenerator.Logic");
            var logic = Activator.CreateInstance(logicType, configuration);

            switch (CreationType)
            {
                case "all":
                    ExecuteAll(logic);
                    break;
                case "actions":
                    CreateActions(logic);
                    break;
                case "entities":
                    CreateEntities(logic);
                    break;
                case "optionsets":
                    CreateOptionSets(logic);
                    break;
                default:
                    break;
            }

            Logger.LogInformation("Early bound generation completed");
        }

        private void RegisterOnLog(Type loggerType)
        {
            var logger = loggerType.GetField("Instance", BindingFlags.Public | BindingFlags.Static)?.GetValue(null);

            var onLog = loggerType.GetEvent("OnLog", BindingFlags.Public | BindingFlags.Instance);

            var method = this.GetType().GetMethod(nameof(OnLogHandler), BindingFlags.NonPublic | BindingFlags.Instance);
            var handler = Delegate.CreateDelegate(onLog.EventHandlerType, this, method);

            onLog.AddEventHandler(logger, handler);
        }

        private void ExecuteAll(object logic)
        {
            if (ExecuteAsync)
            {
                InvokeMethod(logic.GetType(), "ExecuteAll", BindingFlags.Public | BindingFlags.Instance, logic);
            }
            else
            {
                InvokeMethod(logic.GetType(), "CreateActions", BindingFlags.Public | BindingFlags.Instance, logic);
                InvokeMethod(logic.GetType(), "CreateEntities", BindingFlags.Public | BindingFlags.Instance, logic);
                InvokeMethod(logic.GetType(), "CreateOptionSets", BindingFlags.Public | BindingFlags.Instance, logic);
            }
        }

        private static void CreateActions(object logic)
        {
            InvokeMethod(logic.GetType(), "CreateActions", BindingFlags.Public | BindingFlags.Instance, logic);
        }

        private static void CreateEntities(object logic)
        {
            InvokeMethod(logic.GetType(), "CreateEntities", BindingFlags.Public | BindingFlags.Instance, logic);
        }
        private static void CreateOptionSets(object logic)
        {
            InvokeMethod(logic.GetType(), "CreateOptionSets", BindingFlags.Public | BindingFlags.Instance, logic);
        }

        private static object InvokeMethod(Type type, string method, BindingFlags flags, object target, object[] parameters = null)
        {
            return type.GetMethod(method, flags)?.Invoke(target, parameters);
        }

        private void OnLogHandler(object logMessageInfo)
        {
            var modalMessage = logMessageInfo.GetType()
                .GetProperty("ModalMessage", BindingFlags.Public | BindingFlags.Instance | BindingFlags.GetProperty)?
                .GetValue(logMessageInfo);

            var detail = logMessageInfo.GetType()
                .GetProperty("Detail", BindingFlags.Public | BindingFlags.Instance | BindingFlags.GetProperty)?
                .GetValue(logMessageInfo);

            var message = modalMessage is null ? $"{detail}" : $"{modalMessage} - {detail}";

            Logger.LogVerbose(message);
        }
    }
}

## Overview
**EBG DevOps Tools is a set of tools that makes it easy and quick to automate DevOps tasks of your PowerApps/CDS/Dynamics 365 CE solutions.**

This will allow you to setup a fully automated DevOps pipeline so you can deliver CRM more frequently in a consistent and reliable way.

[Compatibility](#compatibility)
[Task Catalog](#task-catalogue)
[More Information](#more-information)
[Version History](#version-history)

## Compatibility

**Dynamics 365 (8.x.x)**
**Dynamics 365 (9.x.x)/CDS/PowerApps**
(Many tasks may work with previous versions of Dynamics CRM)

**Azure DevOps/Azure DevOps Server/TFS** For support and installation [instructions](https://docs.microsoft.com/en-us/vsts/marketplace/get-tfs-extensions)

Works with Hosted Azure Agents

## Task Catalog

Below is a list of tasks that are included with this extension.

**You must add the 'EBG DevOps Tool Installer' at the begining of every agent phase for the other tasks to work.**

| Task | Category | Description |
| --- | --- | --- |
| **EBG DevOps Tool Installer** | Utility | Configures the tools/dependencies required by all of the tasks |
| **Early Bound Generator** | Utility | Extends and automates the creation of Early Bound Xrm classes |

Some explanation for tasks that have the below in the names:

**preview**: New functionality. May contain some bugs. Subject to breaking changes while in preview.

**deprecated**: Task has been replaced with another task or is no longer required. Will be removed in future release.

## More Information

For more documentation and source code, check out Github using the links on this page.

## Version History

**1.0.x**
Initial Release

For more information on changes between versions, check the milestones and releases on GitHub

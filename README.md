Build status dev: [![Build status](https://ci.appveyor.com/api/projects/status/w7359l21bp14oiec/branch/dev?svg=true)](https://ci.appveyor.com/project/bgelens/hybridrunbookworkerdsc/branch/dev)

# HybridRunbookWorkerDsc

This module contains resources to onboard / remove Hybrid Runbook Workers from an Automation Account and to reassign the Group membership if needed.

For this resource to work, the node on which this resource is used must already have the Microsoft Monitoring Agent installed.
The OMS Workspace should have the Automation solution enabled and coupled with an Automation Account.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## How to Contribute
If you would like to contribute to this repository, please read the DSC Resource Kit [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

* **HybridRunbookWorker** Used for onboarding Hybrid Runbook Worker into Automation Account. Also governs the Group assignment and can be used to remove the worker from the Automation Account.
* **WaitForHybridRegistrionModule** Used to wait for HybridRegistration Module to be pushed to node by OMS.

### HybridRunbookWorker
This resource is capable of:
* Enabling Hybrid Runbook Worker if Microsoft Monitoring Agent is already installed.
* Change the Hybrid Runbook Worker Group
* Remove Hybrid Runbook Worker from Automation Account.

This resource contains the following properties:
* **Ensure**: Ensures that the node is onboarded or removed from the Automation Account.
* **Endpoint**: Uri of Automation Account.
* **Token**: Credential containing the Automation Account primary or secondary key as a password.
* **GroupName**: The Hybrid Runbook Worker Group for this Worker to join.

### WaitForHybridRegistrionModule
This resource is capable of:
* Waiting for the HybridRegistration to appear.

This resource contains the following properties:
* **IsSingleInstance**: Specifies if the resource is a single instance, the value must be 'Yes'
* **RetryIntervalSec**: Specifies amount of seconds between retries. Default 60 seconds.
* **RetryCount**: Specifies amount of retries. Default 10 times.

## Versions

### Unreleased

* Initial release with the following resources:
    * HybridRunbookWorker
    * WaitForHybridRegistrionModule

### 1.0.0.0

configuration HybridRunbookWorkerConfig
{

    Import-DscResource -ModuleName @{ModuleName='xPSDesiredStateConfiguration'; ModuleVersion='4.0.0.0'}
    Import-DscResource -ModuleName HybridRunbookWorkerDsc

    $OmsWorkspaceId = Get-AutomationVariable WorkspaceID
    $OmsWorkspaceKey = Get-AutomationVariable WorkspaceKey
    $AutomationEndpoint = Get-AutomationVariable AutomationEndpoint
    $AutomationKey = Get-AutomationPSCredential AutomationCredential

    $OIPackageLocalPath = "C:\MMASetup-AMD64.exe"

    Node $AllNodes.NodeName
    {
        # Download a package
        xRemoteFile OIPackage
        {
            Uri = "https://opsinsight.blob.core.windows.net/publicfiles/MMASetup-AMD64.exe"
            DestinationPath = $OIPackageLocalPath
        }

        # Application, requires reboot. Allow reboot in meta config
        Package OI
        {
            Ensure = "Present"
            Path = $OIPackageLocalPath
            Name = "Microsoft Monitoring Agent"
            ProductId = "E854571C-3C01-4128-99B8-52512F44E5E9"
            Arguments = '/Q /C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_ID=' + 
                $OmsWorkspaceID + ' OPINSIGHTS_WORKSPACE_KEY=' + 
                    $OmsWorkspaceKey + ' AcceptEndUserLicenseAgreement=1"'
            DependsOn = "[xRemoteFile]OIPackage"
        }
        
        # Service state
        Service OIService
        {
            Name = "HealthService"
            State = "Running"
            DependsOn = "[Package]OI"
        }

        WaitForHybridRegistrationModule ModuleWait
        {
            IsSingleInstance = 'Yes'
            RetryIntervalSec = 3
            RetryCount = 2
            DependsOn = '[Package]OI'
        }

        HybridRunbookWorker Onboard
        {
            Ensure    = 'Present'
            Endpoint  = $AutomationEndpoint
            Token     = $AutomationKey
            GroupName = $Node.NodeName
            DependsOn = '[WaitForHybridRegistrationModule]ModuleWait'
        }
    }
}

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'TestHybridWorker'
            PSDscAllowPlainTextPassword = $true
            
        },
        @{
            NodeName = 'ProdHybridWorker'
            PSDscAllowPlainTextPassword = $true
        }
    )
}

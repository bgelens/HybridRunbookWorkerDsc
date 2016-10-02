Configuration HybridRunbookWorkerConfig
{

    Import-DscResource -ModuleName @{ModuleName='xPSDesiredStateConfiguration'; ModuleVersion='3.9.0.0'}
    Import-DscResource -ModuleName HybridRunbookWorker

    $OmsWorkspaceId = Get-AutomationVariable WorkspaceID
    $OmsWorkspaceKey = Get-AutomationVariable WorkspaceKey

    $OIPackageLocalPath = "C:\MMASetup-AMD64.exe"

    Node $AllNodes.NodeName
    {
        # Download a package
        xRemoteFile OIPackage
        {
            Uri = "https://opsinsight.blob.core.windows.net/publicfiles/MMASetup-AMD64.exe"
            DestinationPath = $OIPackageLocalPath
        }

        # Application
        Package OI
        {
            Ensure = "Present"
            Path = $OIPackageLocalPath
            Name = "Microsoft Monitoring Agent"
            ProductId = ""
            Arguments = '/C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_ID=' + $OmsWorkspaceID + ' OPINSIGHTS_WORKSPACE_KEY=' + $OmsWorkspaceKey + ' AcceptEndUserLicenseAgreement=1"'
            DependsOn = "[xRemoteFile]OIPackage"
        }
        
        # Service state
        Service OIService
        {
            Name = "HealthService"
            State = "Running"
            DependsOn = "[Package]OI"
        }


        HybridRunbookWorker Onboard
        {
            Ensure    = 'Present'
            Endpoint  = Get-AutomationVariable AutomationEndpoint
            Token     = Get-AutomationPSCredential AutomationCredential
            GroupName = $Node.NodeName
            DependsOn = '[Package]OI'
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

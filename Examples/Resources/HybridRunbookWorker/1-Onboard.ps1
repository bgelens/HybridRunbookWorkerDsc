configuration Onboard
{
    Import-DscResource -ModuleName HybridRunbookWorker

    HybridRunbookWorker Onboard
    {
        Ensure = 'Present'
        Endpoint = 'https://we-agentservice-prod-1.azure-automation.net/accounts/<subid>'
        Token = (Get-Credential -Message 'Enter AA Key' -UserName 'AAKey')
        GroupName = 'MyGroup'
    }
}

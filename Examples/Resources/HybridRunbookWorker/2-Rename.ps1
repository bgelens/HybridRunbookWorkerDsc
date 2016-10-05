configuration Rename
{
    Import-DscResource -ModuleName HybridRunbookWorkerDsc

    HybridRunbookWorker Rename
    {
        Ensure = 'Present'
        Endpoint = 'https://we-agentservice-prod-1.azure-automation.net/accounts/<subid>'
        Token = Get-Credential -Message 'Enter AA Key' -UserName 'AAKey'
        GroupName = 'MyNewGroup'
    }
}

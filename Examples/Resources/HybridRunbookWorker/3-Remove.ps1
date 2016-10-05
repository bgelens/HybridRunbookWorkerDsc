configuration Remove
{
    Import-DscResource -ModuleName HybridRunbookWorkerDsc

    HybridRunbookWorker Remove
    {
        Ensure = 'Absent'
        Endpoint = 'https://we-agentservice-prod-1.azure-automation.net/accounts/<subid>'
        Token = Get-Credential -Message 'Enter AA Key' -UserName 'AAKey'
        GroupName = 'MyGroup'
    }
}

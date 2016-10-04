configuration WaitModule 
{
    Import-DscResource -ModuleName HybridRunbookWorkerDsc

    node localhost
    {
        WaitForHybridRegistrationModule ModuleWait
        {
            IsSingleInstance = 'Yes'
            RetryIntervalSec = 3
            RetryCount = 2
        }
    }
}

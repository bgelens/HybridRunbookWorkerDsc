function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Endpoint,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Token,

        [parameter(Mandatory = $true)]
        [System.String]
        $GroupName
    )
    $ModulePresent = TestRegModule
    if (-not $ModulePresent)
    {
        $ErrorParam = @{
            ErrorId = 'ModuleNotPresent'
            ErrorMessage = 'HybridRegistration Module is not Present. OMS Agent is probably not installed'
            ErrorCategory = 'ObjectNotFound'
            ErrorAction = 'Stop'
        }
        New-TerminatingError @ErrorParam
    }

    $Actived = TestRegRegistry
    if ($Actived)
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }
    
    if ($Actived)
    {
        $Config = GetRegRegistry
        return @{
            Ensure = $Ensure
            GroupName = $config.RunbookWorkerGroup
            Endpoint = $Endpoint
            Token = $null
        }
    }
    else
    {
        return @{
            Ensure = $Ensure
            GroupName = $GroupName
            Endpoint = $Endpoint
            Token = $null
        }
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Endpoint,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Token,

        [parameter(Mandatory = $true)]
        [System.String]
        $GroupName
    )
    $ModulePresent = TestRegModule
    if (-not $ModulePresent)
    {
        $ErrorParam = @{
            ErrorId = 'ModuleNotPresent'
            ErrorMessage = 'HybridRegistration Module is not Present. OMS Agent is probably not installed'
            ErrorCategory = 'ObjectNotFound'
            ErrorAction = 'Stop'
        }
        New-TerminatingError @ErrorParam
    }

    $Actived = TestRegRegistry

    if ($Ensure -eq 'Present' -and $Actived)
    {
        Write-Verbose -Message 'Change Hybrid Runbook Worker Group'
        Remove-HybridRunbookWorker -Url $Endpoint -Key $Token.GetNetworkCredential().Password
        Add-HybridRunbookWorker -Url $Endpoint -GroupName $GroupName -Key $Token.GetNetworkCredential().Password
    }
    elseif ($Ensure -eq 'Present')
    {
        Write-Verbose -Message 'Registering Hybrid Runbook Worker'
        Add-HybridRunbookWorker -Url $Endpoint -GroupName $GroupName -Key $Token.GetNetworkCredential().Password
    }
    else
    {
        Write-Verbose -Message 'Remove Hybrid Runbook Worker registration'
        Remove-HybridRunbookWorker -Url $Endpoint -Key $Token.GetNetworkCredential().Password
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Endpoint,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Token,

        [parameter(Mandatory = $true)]
        [System.String]
        $GroupName
    )
    $ModulePresent = TestRegModule
    if (-not $ModulePresent)
    {
        $ErrorParam = @{
            ErrorId = 'ModuleNotPresent'
            ErrorMessage = 'HybridRegistration Module is not Present. OMS Agent is probably not installed'
            ErrorCategory = 'ObjectNotFound'
            ErrorAction = 'Stop'
        }
        New-TerminatingError @ErrorParam
    }
    
    $Actived = TestRegRegistry
    if ($Ensure -eq 'Present')
    {
        if ($Actived)
        {
            Write-Verbose -Message 'Hybrid Runbook Worker Configuration Present'
            $Config = GetRegRegistry
            Write-Verbose -Message "Config: $($Config | Out-String)"
            if ($Config.RunbookWorkerGroup -eq $GroupName)
            {
                Write-Verbose -Message 'Hybrid Runbook Worker GroupName Correct'
                $true
            }
            else
            {
                Write-Verbose -Message 'Hybrid Runbook Worker GroupName InCorrect'
                $false
            }
        }
        else
        {
            Write-Verbose -Message 'Hybrid Runbook Worker Configuration Absent. Should be Present'
            $false
        }
    }
    else
    {
        if ($Actived)
        {
            Write-Verbose -Message 'Hybrid Runbook Worker Configuration Present. Should be Absent'
            $false
        }
        else
        {
            Write-Verbose -Message 'Hybrid Runbook Worker Configuration Absent'
            $true
        }
    }
}

#region helper functions
function TestRegModule {
    if (Get-Module -Name HybridRegistration -ListAvailable)
    {
        $true
    }
    else
    {
        $false
    }
}

function TestRegRegistry
{
    Test-Path -Path HKLM:\SOFTWARE\Microsoft\HybridRunbookWorker
}

function GetRegRegistry
{
    Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HybridRunbookWorker
}

function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String] $ErrorId,

        [Parameter(Mandatory)]
        [String] $ErrorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory] $ErrorCategory
    )

    $exception = New-Object System.InvalidOperationException $errorMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
    throw $errorRecord
}
#endregion

Export-ModuleMember -Function *-TargetResource

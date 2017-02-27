#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_WaitForHybridRegistrationModule.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_WaitForHybridRegistrationModule.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
    .SYNOPSIS
    Returns Resource Property values and test result for HybridRegistration module check.
    .PARAMETER IsSingleInstance
    This resource is restricted to single usage.
    .PARAMETER RetryIntervalSec
    Specifies the retry interval in seconds to search for the HybridRegistration module.
    .PARAMETER RetryCount
    Specifies the retry count to search for the HybridRegistration module.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [parameter()]
        [UInt64]
        $RetryIntervalSec = 60,

        [parameter()]
        [UInt32]
        $RetryCount = 10
    )
    return @{
        IsSingleInstance = $IsSingleInstance
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
        ModulePresent = TestRegModule
    }
}

<#
    .SYNOPSIS
    Wait for the HybridRegistration module to become available.
    .PARAMETER IsSingleInstance
    This resource is restricted to single usage.
    .PARAMETER RetryIntervalSec
    Specifies the retry interval in seconds to search for the HybridRegistration module.
    .PARAMETER RetryCount
    Specifies the retry count to search for the HybridRegistration module.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [parameter()]
        [UInt64]
        $RetryIntervalSec = 60,

        [parameter()]
        [UInt32]
        $RetryCount = 10
    )
    for($count = 0; $count -lt $RetryCount; $count++)
    {
        $env:PSModulePath = [System.Environment]::GetEnvironmentVariable('PSModulePath',[System.EnvironmentVariableTarget]::Machine)
        if (TestRegModule) {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                    $($LocalizedData.HybridRunbookWorkerModulePresent)
            ) -join '' )
            break
        }
        else
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                    $($LocalizedData.HybridRunbookWorkerModuleRetry -f ($count + 1),$RetryCount,$RetryIntervalSec)
            ) -join '' )
            
            Start-Sleep -Seconds $RetryIntervalSec    
        }
    }
    if (-not (TestRegModule))
    {
        $ErrorParam = @{
            ErrorId = 'ModuleNotPresent'
            ErrorMessage = ( @(
                    "$($MyInvocation.MyCommand): "
                        $($LocalizedData.HybridRunbookWorkerModuleNotPresent)
                ) -join '' )
            ErrorCategory = 'ObjectNotFound'
            ErrorAction = 'Stop'
        }
        New-TerminatingError @ErrorParam
    }
}

<#
    .SYNOPSIS
    Test if the HybridRegistration module is available.
    .PARAMETER IsSingleInstance
    This resource is restricted to single usage.
    .PARAMETER RetryIntervalSec
    Specifies the retry interval in seconds to search for the HybridRegistration module.
    .PARAMETER RetryCount
    Specifies the retry count to search for the HybridRegistration module.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [parameter()]
        [UInt64]
        $RetryIntervalSec = 60,

        [parameter()]
        [UInt32]
        $RetryCount = 10
    )
    TestRegModule   
}

#region helper functions
<#
    .SYNOPSIS
    Returns true or false based on the presence of HybridRegistration PowerShell module.
#>
function TestRegModule
{
    if (Get-Module -Name HybridRegistration -ListAvailable)
    {
        $true
    }
    else
    {
        $false
    }
}

<#
    .SYNOPSIS
    Throw a custome exception.
    .PARAMETER ErrorId
    The identifier representing the exception being thrown.
    .PARAMETER ErrorMessage
    The error message to be used for this exception.
    .PARAMETER ErrorCategory
    The exception error category.
#>
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
    $PSCmdlet.ThrowTerminatingError($errorRecord)
}
#endregion

Export-ModuleMember -Function *-TargetResource

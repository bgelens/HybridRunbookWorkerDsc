#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_HybridRunbookWorker.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_HybridRunbookWorker.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
    .SYNOPSIS
    Returns the current Hybrid Runbook Worker configuration state.
    .PARAMETER Ensure
    Specifies if the Hybrid Runbook Worker should be onboarded or removed from the Automation Account.
    .PARAMETER Endpoint
    Specifies the Uri of the Automation Account.
    .PARAMETER Token
    Specifies the Primary or Secondary Key of the Automation Account.
    .PARAMETER GroupName
    Specifies the Hybrid Runbook Worker Group Name.
#>
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
            ErrorMessage = ( @(
                    "$($MyInvocation.MyCommand): "
                        $($LocalizedData.HybridRunbookWorkerModuleNotPresent)
                ) -join '' )
            ErrorCategory = 'ObjectNotFound'
            ErrorAction = 'Stop'
        }
        New-TerminatingError @ErrorParam
    }

    $Activated = TestRegRegistry
    if ($Activated)
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }
    
    if ($Activated)
    {
        $Config = GetRegRegistry
        return @{
            Ensure = $Ensure
            GroupName = $Config.RunbookWorkerGroup
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

<#
    .SYNOPSIS
    Sets the Hybrid Runbook Worker configuration state.
    .PARAMETER Ensure
    Specifies if the Hybrid Runbook Worker should be onboarded or removed from the Automation Account.
    .PARAMETER Endpoint
    Specifies the Uri of the Automation Account.
    .PARAMETER Token
    Specifies the Primary or Secondary Key of the Automation Account.
    .PARAMETER GroupName
    Specifies the Hybrid Runbook Worker Group Name.
#>
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
            ErrorMessage = ( @(
                    "$($MyInvocation.MyCommand): "
                        $($LocalizedData.HybridRunbookWorkerModuleNotPresent)
                ) -join '' )
            ErrorCategory = 'ObjectNotFound'
            ErrorAction = 'Stop'
        }
        New-TerminatingError @ErrorParam
    }

    $Activated = TestRegRegistry

    if ($Ensure -eq 'Present' -and $Activated)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                    $($LocalizedData.HybridRunbookWorkerChangeGroup)
            ) -join '' )
        Remove-HybridRunbookWorker -Url $Endpoint -Key $Token.GetNetworkCredential().Password
        Add-HybridRunbookWorker -Url $Endpoint -GroupName $GroupName -Key $Token.GetNetworkCredential().Password
    }
    elseif ($Ensure -eq 'Present')
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                    $($LocalizedData.HybridRunbookWorkerRegister)
            ) -join '' )
        Add-HybridRunbookWorker -Url $Endpoint -GroupName $GroupName -Key $Token.GetNetworkCredential().Password
    }
    else
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                    $($LocalizedData.HybridRunbookWorkerRemove)
            ) -join '' )
        Remove-HybridRunbookWorker -Url $Endpoint -Key $Token.GetNetworkCredential().Password
    }
}

<#
    .SYNOPSIS
    Tests if the Hybrid Runbook Worker configuration state is in the desired state.
    .PARAMETER Ensure
    Specifies if the Hybrid Runbook Worker should be onboarded or removed from the Automation Account.
    .PARAMETER Endpoint
    Specifies the Uri of the Automation Account.
    .PARAMETER Token
    Specifies the Primary or Secondary Key of the Automation Account.
    .PARAMETER GroupName
    Specifies the Hybrid Runbook Worker Group Name.
#>
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
            ErrorMessage = ( @(
                    "$($MyInvocation.MyCommand): "
                        $($LocalizedData.HybridRunbookWorkerModuleNotPresent)
                ) -join '' )
            ErrorCategory = 'ObjectNotFound'
            ErrorAction = 'Stop'
        }
        New-TerminatingError @ErrorParam
    }
    
    $Activated = TestRegRegistry
    if ($Ensure -eq 'Present')
    {
        if ($Activated)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                        $($LocalizedData.HybridRunbookWorkerConfigPresent)
                ) -join '' )

            $Config = GetRegRegistry
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                        $($LocalizedData.HybridRunbookWorkerConfig -f ($Config | Out-String))
                ) -join '' )

            if ($Config.RunbookWorkerGroup -eq $GroupName)
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                        $($LocalizedData.HybridRunbookWorkerGroupNameCorrect)
                ) -join '' )
                $true
            }
            else
            {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                        $($LocalizedData.HybridRunbookWorkerGroupNameNotCorrect)
                ) -join '' )
                $false
            }
        }
        else
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                        $($LocalizedData.HybridRunbookWorkerConfigMisMatch -f 'Absent','Present')
                ) -join '' )
            $false
        }
    }
    else
    {
        if ($Activated)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                        $($LocalizedData.HybridRunbookWorkerConfigMisMatch -f 'Present','Absent')
                ) -join '' )
            $false
        }
        else
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                        $($LocalizedData.HybridRunbookWorkerConfigAbsent)
                ) -join '' )
            $true
        }
    }
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
    Returns true or false based on the presence of HybridRunbookWorker registry key.
#>
function TestRegRegistry
{
    Test-Path -Path HKLM:\SOFTWARE\Microsoft\HybridRunbookWorker
}

<#
    .SYNOPSIS
    Returns the content of the HybridRunbookWorker Registry key.
#>
function GetRegRegistry
{
    $Reg = Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HybridRunbookWorker
    if ($null -eq $Reg) {
        #newer version
        $Reg = [pscustomobject]@{
            RunbookWorkerGroup = Split-Path -Path (Get-Item -Path HKLM:\SOFTWARE\Microsoft\HybridRunbookWorker\*\*).Name -Leaf
        }
    }
    $Reg
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

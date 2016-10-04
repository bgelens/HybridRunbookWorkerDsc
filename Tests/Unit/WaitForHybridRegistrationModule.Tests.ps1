$Global:ModuleName = 'HybridRunbookWorkerDsc'
$Global:DscResourceName = 'MSFT_WaitForHybridRegistrationModule'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

# TODO: Insert the correct <ModuleName> and <ResourceName> for your resource
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:ModuleName `
    -DSCResourceName $Global:DscResourceName `
    -TestType Unit 

#endregion HEADER

function Invoke-TestSetup {
    # TODO: Optional init code goes here...
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    
    # TODO: Other Optional Cleanup Code Goes Here...
}

# Begin Testing
try
{
    Invoke-TestSetup

    #region Pester Tests
    InModuleScope $Global:DscResourceName {
        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            It 'Returns a hashtable' {
                Mock -CommandName TestRegModule -MockWith {return $true}                
                $targetResource = Get-TargetResource -IsSingleInstance 'Yes'
                $targetResource -is [System.Collections.Hashtable] | Should Be $true
            }

            It 'Returns Module Present information' {
                Mock -CommandName TestRegModule -MockWith {return $true}
                $targetResource = Get-TargetResource -IsSingleInstance 'Yes'
                $targetResource.ModulePresent | Should Be $true

                Mock -CommandName TestRegModule -MockWith {return $false}
                $targetResource = Get-TargetResource -IsSingleInstance 'Yes'
                $targetResource.ModulePresent | Should Be $false
            }
        }
        #endregion


        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            Context 'Invoking with HybridRegistration Module missing' {
                Mock -CommandName TestRegModule -MockWith {return $false}
                It 'should return false when module is not present' {
                    Test-TargetResource -IsSingleInstance 'Yes' -RetryIntervalSec 1 -RetryCount 1 | Should Be $False
                }
            }

            Context 'Invoking with HybridRegistration Module present' {
                Mock -CommandName TestRegModule -MockWith {return $true}
                It 'should return true when module is present' {
                    Test-TargetResource -IsSingleInstance 'Yes' -RetryIntervalSec 1 -RetryCount 1 | Should Be $true
                }
            }
        }
        ##endregion

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            
            Context 'Invoking with HybridRegistration Module missing' {
                Mock -CommandName TestRegModule -MockWith {return $false}
                $ErrorRecord = New-Object System.Management.Automation.ErrorRecord 'HybridRegistration Module is not Present.', 'ModuleNotPresent', 'ObjectNotFound', $null
                It 'should throw ObjectNotFound exception' {
                    {Set-TargetResource -IsSingleInstance 'Yes' -RetryIntervalSec 1 -RetryCount 1} | Should Throw $ErrorRecord
                }
            }

            Context 'Invoking with HybridRegistration Module present' {
                Mock -CommandName TestRegModule -MockWith {return $true}
                It 'should not throw' {
                    {Set-TargetResource -IsSingleInstance 'Yes' -RetryIntervalSec 1 -RetryCount 1} | Should Not Throw
                }
            }
            
            Context 'It should respect RetryCount' {
                It 'Calls Start-Sleep exactly 2 times' {
                    Mock -CommandName TestRegModule -MockWith {return $false}
                    Mock -CommandName Start-Sleep -MockWith {}
                    {Set-TargetResource -IsSingleInstance 'Yes' -RetryIntervalSec 1 -RetryCount 2} | Should Throw
                    Assert-MockCalled -CommandName Start-Sleep -Times 2 -Exactly -Scope It
                }
                
                It 'Should finish when module is found and call Start-Sleep 1 time' {
                    Mock -CommandName TestRegModule -MockWith {return $false}
                    Mock -CommandName Start-Sleep -MockWith {}
                    {Set-TargetResource -IsSingleInstance 'Yes' -RetryIntervalSec 1 -RetryCount 1} | Should Throw
                    Mock -CommandName TestRegModule -MockWith {return $true}
                    {Set-TargetResource -IsSingleInstance 'Yes' -RetryIntervalSec 1 -RetryCount 1} | Should Not Throw
                    Assert-MockCalled -CommandName Start-Sleep -Times 1 -Exactly -Scope It
                }
            }
        }
        #endregion
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}


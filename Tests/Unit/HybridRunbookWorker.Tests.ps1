[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$Global:ModuleName = 'HybridRunbookWorkerDsc'
$Global:DscResourceName = 'MSFT_HybridRunbookWorker'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:ModuleName `
    -DSCResourceName $Global:DscResourceName `
    -TestType Unit 

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    #region Pester Tests
    InModuleScope $Global:DscResourceName {
        $Token = New-Object -TypeName PSCredential -ArgumentList 'TestToken',(ConvertTo-SecureString -String 'BogusToken' -AsPlainText -Force)
        $GroupName = 'TestGroup'
        $EndPoint = 'https://TestEndpoint'
        function Remove-HybridRunbookWorker { }
        function Add-HybridRunbookWorker { }

        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            Mock -CommandName TestRegModule -MockWith {return $true}

            It 'Returns a hashtable' {                
                $targetResource = Get-TargetResource -Ensure 'Present' -Endpoint $EndPoint -Token $Token -GroupName $GroupName
                $targetResource -is [System.Collections.Hashtable] | Should Be $true
            }
        }
        #endregion


        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            Context 'Invoking with HybridRegistration Module missing' {
                Mock -CommandName TestRegModule -MockWith {return $false}
                $ErrorRecord = New-Object System.Management.Automation.ErrorRecord 'HybridRegistration Module is not Present. OMS Agent is probably not installed', 'ModuleNotPresent', 'ObjectNotFound', $null
                It 'should throw ObjectNotFound exception' {
                    {Test-TargetResource -Ensure 'Present' -Endpoint $EndPoint -Token $Token -GroupName $GroupName} | Should Throw $ErrorRecord
                }
            }
            
            Context 'Invoking with HybridRegistration Module Present' {
                Mock -CommandName TestRegModule -MockWith {return $true}
                Mock -CommandName TestRegRegistry -MockWith {return $true}
                Mock -CommandName GetRegRegistry -MockWith {[PSCustomObject]@{
                        RunbookWorkerGroup = $GroupName
                    }
                }
                It 'should not throw ObjectNotFound exception' {
                    {Test-TargetResource -Ensure 'Present' -Endpoint $EndPoint -Token $Token -GroupName $GroupName} | Should not Throw
                }
            }
            
            Context 'Invoking without finished registration' {
                Mock -CommandName TestRegModule -MockWith {return $true}
                Mock -CommandName TestRegRegistry -MockWith {return $true}
                It 'Should return $false when no registration has been done and Ensure is Present' {
                    Mock -CommandName TestRegRegistry -MockWith {return $false}
                    Test-TargetResource -Ensure 'Present' -Endpoint $EndPoint -Token $Token -GroupName $GroupName | Should be $false
                }
                It 'Should return $true when no registration has been done and Ensure is Absent' {
                    Mock -CommandName TestRegRegistry -MockWith {return $false}
                    Test-TargetResource -Ensure 'Absent' -Endpoint $EndPoint -Token $Token -GroupName $GroupName | Should be $true
                }
            }
            
            Context 'Invoking with finished registration' {
                Mock -CommandName TestRegModule -MockWith {return $true}
                Mock -CommandName TestRegRegistry -MockWith {return $true}
                
                It 'Should return $false when registration has been done but desired GroupName has changed' {
                    Mock -CommandName GetRegRegistry -MockWith {[PSCustomObject]@{
                            RunbookWorkerGroup = 'OtherGroupName'
                        }
                    }
                    Test-TargetResource -Ensure 'Present' -Endpoint $EndPoint -Token $Token -GroupName $GroupName  | Should be $false
                }
                It 'Should return $true when registration is done and desired GroupName is correct' {
                    Mock -CommandName GetRegRegistry -MockWith {[PSCustomObject]@{
                            RunbookWorkerGroup = $GroupName
                        }
                    }
                    Test-TargetResource -Ensure 'Present' -Endpoint $EndPoint -Token $Token -GroupName $GroupName  | Should be $true
                }
            }
        }
        ##endregion

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            Mock Remove-HybridRunbookWorker
            Mock Add-HybridRunbookWorker
            Mock -CommandName TestRegModule -MockWith {return $true}
            
            Context 'Invoke Registration' {

                It 'Should call only "Add-HybridRunbookWorker"' {
                    $Null = Set-TargetResource -Ensure 'Present' -Endpoint $EndPoint -Token $Token -GroupName $GroupName

                    Assert-MockCalled -CommandName Add-HybridRunbookWorker -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-HybridRunbookWorker -Exactly -Times 0
                }
            }

            Context 'Invoke GroupName Change' {

                It 'Should call "Remove-HybridRunbookWorker" and "Add-HybridRunbookWorker"' {
                    Mock -CommandName TestRegRegistry -MockWith {return $true}
                    $Null = Set-TargetResource -Ensure 'Present' -Endpoint $EndPoint -Token $Token -GroupName $GroupName

                    Assert-MockCalled -CommandName Add-HybridRunbookWorker -Exactly -Times 1
                    Assert-MockCalled -CommandName Remove-HybridRunbookWorker -Exactly -Times 1
                }
            }
            
            Context 'Invoke De-Registration' {
                It 'Should call only "Remove-HybridRunbookWorker"' {
                    $Null = Set-TargetResource -Ensure 'Absent' -Endpoint $EndPoint -Token $Token -GroupName $GroupName

                    Assert-MockCalled -CommandName Add-HybridRunbookWorker -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-HybridRunbookWorker -Exactly -Times 1
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


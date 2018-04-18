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
            Mock -CommandName TestRegRegistry -MockWith {return $false}

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
            Mock -CommandName TestRegRegistry -MockWith {return $false}

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
                    Mock -CommandName TestRegRegistry -MockWith {return $true}
                    $Null = Set-TargetResource -Ensure 'Absent' -Endpoint $EndPoint -Token $Token -GroupName $GroupName

                    Assert-MockCalled -CommandName Add-HybridRunbookWorker -Exactly -Times 0
                    Assert-MockCalled -CommandName Remove-HybridRunbookWorker -Exactly -Times 1
                }
            }
        }
        #endregion

        #region Function TestRegModule
        Describe "$($Global:DSCResourceName)\TestRegModule" {
            It 'Should return "True" when HybridRegistration module is present' {
                Mock -CommandName Get-Module -MockWith {[pscustomobject]@{Name = 'HybridRegistration'}}
                TestRegModule | Should -BeTrue
            }

            It 'Should return "False" when HybridRegistration module is absent' {
                Mock -CommandName Get-Module -MockWith {}
                TestRegModule | Should -BeFalse
            }
        }
        #endregion

        #region Function TestRegRegistry
        Describe "$($Global:DSCResourceName)\TestRegRegistry" {
            It 'Should return "True" when old registry path exists' {
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Microsoft\HybridRunbookWorker' } -MockWith {[pscustomobject]@{Name='SomeProperty'}}
                Mock -CommandName Get-Item

                TestRegRegistry | Should -BeTrue
                Assert-MockCalled -CommandName Get-Item -Times 0 -Exactly -Scope It
            }

            It 'Should return "True" when new registry path contains user records' {
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Microsoft\HybridRunbookWorker' } -MockWith {}
                Mock -CommandName Get-Item -MockWith {[pscustomobject]@{PSChildName = 'User'}}
                Mock -CommandName Get-ChildItem -MockWith {[pscustomobject]@{PSChildName = 'User'}}

                TestRegRegistry | Should -BeTrue
                Assert-MockCalled -CommandName Get-Item -Times 1 -Exactly -Scope It
            }

            It 'Should return "False" when new registry path does not contain user records' {
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Microsoft\HybridRunbookWorker' } -MockWith {}
                Mock -CommandName Get-Item -MockWith {[pscustomobject]@{PSChildName = 'Machine'}}
                Mock -CommandName Get-ChildItem -MockWith {[pscustomobject]@{PSChildName = 'Machine'}}

                TestRegRegistry | Should -BeFalse
                Assert-MockCalled -CommandName Get-Item -Times 1 -Exactly -Scope It
            }
        }
        #endregion

        #region Function GetRegRegistry
        Describe "$($Global:DSCResourceName)\GetRegRegistry" {
            It 'Should return an object when old registry path is used' {
                Mock -CommandName Get-ItemProperty -MockWith {[PSCustomObject]@{RunbookWorkerGroup = 'OtherGroupName'}}
                Mock -CommandName Get-Item

                GetRegRegistry | Should -Not -BeNullOrEmpty
                Assert-MockCalled -CommandName Get-Item -Times 0 -Exactly -Scope It
            }

            It 'Should return an object when new registry path is used' {
                Mock -CommandName Get-ItemProperty -MockWith {}
                Mock -CommandName Get-Item -MockWith {[pscustomobject]@{PSChildName = 'User'}}
                Mock -CommandName Get-ChildItem -MockWith {[pscustomobject]@{PSChildName = 'User'}}

                GetRegRegistry | Should -Not -BeNullOrEmpty
                Assert-MockCalled -CommandName Get-Item -Times 1 -Exactly -Scope It
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


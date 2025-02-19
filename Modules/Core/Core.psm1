[hashtable]$Script:CoreConfig

<#
.DESCRIPTION
Initialize config (hashtable) used in Core.psm1. The best place you use it is in scripts (like /Scripts/MergeInto.ps1).
.PARAMETER Config
Config name
.PARAMETER Value
Config value (hashtable)
#>
function Initialize-GifCore {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Config,
        [Parameter(Mandatory = $true)]
        [hashtable]$Value
    )
    Set-Variable $Config $Value -Scope Script # Share with Core.psm1
    Write-GifOutput "[Core.psm1::Initialize-GifCore::Config=Value]`n$Config = $($Value | ConvertTo-Json)" -Level verbose
}

<#
.DESCRIPTION
Reset the workspace (such as reset branch back to the source branch)
.PARAMETER ResetConfig
Reset config
#>
function Reset-GifWorkspace {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ResetConfig
    )
    Write-GifOutput 'Reset workspace...' -ShowCurrentBranch
    if ($ResetConfig['Branch']) {
        GifCore switch $ResetConfig['Branch']
    }
}

<#
.DESCRIPTION
GifCore, execute git command
#>
function GifCore {
    begin {
        $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Write-GifOutput "[Core.psm1::GifCore::Exec] git $($args -join ' ')" -Level Verbose
    }
    process {
        try {
            $Command = $args -join ' '
            if ($Command -match '[;&|]') {
                throw 'Dangerous characters detected in command!'
            }
            $Output = & git @args 2>&1 | Out-String
            if (-not $?) {
                throw $Output
            }
            return $Output
        }
        finally {
            Write-GifOutput "[Core.psm1::GifCore::TimeCost] $($Stopwatch.Elapsed.TotalSeconds.ToString('0.00s'))" -Level Verbose
        }
    }
}

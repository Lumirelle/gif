<#
.DESCRIPTION
Your best git friend -- gif (v0.2.0)
.PARAMETER Command
Command
.PARAMETER Options
Command options
#>

param (
  [Parameter(Mandatory = $true)]
  [string]$Command,
  [Parameter(ValueFromRemainingArguments)]
  [string[]]$Options
)

# == Init & Check ==
$Global:GifVerbose = $VerbosePreference -in 'Continue', 'Inquire'
$BinPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

$Modules = @('Core', 'IO')
foreach ($Module in $Modules) {
  Import-Module "$BinPath/Modules/$Module"
}
if ($Global:GifVerbose) {
  Write-GifOutput ' ' -LineFeed 1
}

Write-GifOutput "[Gif.ps1::Param]`nCommand: $Command`nParameters: $($Options -join "`n")" -Level verbose

# "git switch" need v2.23+
$GitVersion = (git --version) -replace '^git version (\d+\.\d+\.\d+).*', '$1'
Write-GifOutput "[Gif.ps1::GitVersion] v$GitVersion" -Level verbose
if ([version]$GitVersion -lt [version]'2.23.0') {
  Write-GifOutput "Require Git 2.23+ (current: $GitVersion)" -Level error -LineFeed 1
  Exit 00001
}

# == Main Task ==
switch ($Command) {
  'help' {
    # In PowerShell, empty array, empty string and $null are treat as $false
    if (-not $Options) {
      Get-Help "$BinPath/gif.ps1"
      break
    }
    switch ($Options[0]) {
      { $PSItem -cin 'merge-into', 'mi' } {
        Get-Help "$BinPath/Scripts/MergeInto.ps1"
      }
      { $PSItem -cin 'delete-branch', 'db' } {
        Get-Help "$BinPath/Scripts/DeleteBranch.ps1"
      }
      # TODO: New command above
      Default {
        Write-GifOutput "No such command `"$Command`" in function `"Gif.ps1`"!" -Level error -LineFeed 1
        Exit 00101
      }
    }
  }
  { $PSItem -cin 'merge-into', 'mi' } {
    & "$BinPath/Scripts/MergeInto.ps1" @Options
  }
  { $PSItem -cin 'delete-branch', 'db' } {
    & "$BinPath/Scripts/DeleteBranch.ps1" @Options
  }
  # TODO: New command below
  Default {
    Write-GifOutput "No such command `"$Command`" in function `"Gif.ps1`"!" -Level error -LineFeed 1
    Exit 00101
  }
}

# == Clean ==
foreach ($Module in $Modules) {
  if (Get-Module $Module) {
    Remove-Module $Module -Force -ErrorAction SilentlyContinue
  }
}

Remove-Variable GifVerbose -Scope Global -Force -ErrorAction SilentlyContinue

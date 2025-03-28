<#
.DESCRIPTION
Delete current branch on "local" and "remote"
.PARAMETER Options
Command options:
#>

param (
  [Parameter(ValueFromRemainingArguments)]
  [string[]]$Options
)

# == Init & Check ==
Write-GifOutput "[DeleteBranch.ps1::Param]`nOptions: $($Options -join "`n")" -Level verbose

$HiddenFolders = Get-ChildItem -Name -Attributes D+H
Write-GifOutput "[DeleteBranch.ps1::HiddenFolders]`n$($HiddenFolders -join "`n")" -Level verbose
if ('.git' -cnotin $HiddenFolders) {
  Write-GifOutput 'You are not in a git repository!' -Level error -LineFeed 1
  Exit 02001
}

$Branches = & git for-each-ref --format='%(refname:short)' refs/heads/
Write-GifOutput "[DeleteBranch.ps1::Branches]`n$($Branches -join "`n")" -Level verbose
if (-not $Branches) {
  Write-GifOutput 'Your repository has no branch now, create a branch by command "git branch -c <branch>"!' -Level error -LineFeed 1
  Exit 02002
}

$Remote = & git remote
if ($Remote -is [array]) {
  Write-GifOutput "[DeleteBranch.ps1::Remote]`n$($Remote -join "`n")" -Level verbose
  Write-GifOutput 'Detected multiple remotes!' -Level warn
  if ('origin' -cin $Remote) {
    $Remote = 'origin'
    Write-GifOutput 'Detected remote named "origin", use it as default!' -Level warn
  }
  else {
    Write-GifOutput 'Could not specify a remote accurately!' -Level error -LineFeed 1
    Exit 02003
  }
}
Write-GifOutput "[DeleteBranch.ps1::Remote] $Remote" -Level verbose

$SourceBranch = & git branch --show-current

# This config is used for functions in "Modules/Core/Core.psm1"
Initialize-GifCore CoreConfig @{ }

# == Main Task ==
try {
  if ($Remote) {
    # `git fetch` output nothing, so that we should use `-LineFeed 1` to escape blank line
    Write-GifOutput "Fetch from remote `"$Remote`" (prune) ..." -ShowCurrentBranch -LineFeed 1
    GifCore fetch $Remote --prune
  }

  Write-GifOutput "Delete branch `"$SourceBranch`" on local..." -ShowCurrentBranch
  GifCore branch -d $SourceBranch

  if ($Remote) {
    Write-GifOutput "Delete branch `"$SourceBranch`" on remote..." -ShowCurrentBranch
    GifCore push -d $Remote $SourceBranch
  }
}
# == Clean ==
catch {
  Write-GifOutput $_ -Level error

  # Detect Error: Other
  $Script:ErrorType = 'Other'
}
finally {
  # Exit with Error: Other
  if ($Script:ErrorType -ceq 'Other') {
    Exit 01201
  }
}

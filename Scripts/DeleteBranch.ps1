<#
.DESCRIPTION
Delete current branch on "local" and "remote"
.PARAMETER TargetBranch
The branch to delete
.PARAMETER Options
Command options:
#>

param (
  [string]$TargetBranch,
  [Parameter(ValueFromRemainingArguments)]
  [string[]]$Options
)

# == Init & Check ==
Write-GifOutput "[DeleteBranch.ps1::Param]`nTargetBranch: $TargetBranch`nOptions: $($Options -join "`n")" -Level verbose

if (-not $TargetBranch) {
  Write-GifOutput 'Target branch cannot be null or empty!' -Level error -LineFeed 1
  Exit 02001
}

$HiddenFolders = Get-ChildItem -Name -Attributes D+H
Write-GifOutput "[DeleteBranch.ps1::HiddenFolders]`n$($HiddenFolders -join "`n")" -Level verbose
if ('.git' -cnotin $HiddenFolders) {
  Write-GifOutput 'You are not in a git repository!' -Level error -LineFeed 1
  Exit 02002
}

$Branches = & git for-each-ref --format='%(refname:short)' refs/heads/
Write-GifOutput "[DeleteBranch.ps1::Branches]`n$($Branches -join "`n")" -Level verbose
if (-not $Branches) {
  Write-GifOutput 'Your repository has no branch now, create a branch by command "git branch -c <branch>"!' -Level error -LineFeed 1
  Exit 02003
}

$SourceBranch = & git branch --show-current
Write-GifOutput "[MergeInto.ps1::SourceBranch] $SourceBranch" -Level verbose
if ($SourceBranch -ceq $TargetBranch) {
  Write-GifOutput "You can't delete current branch `"$TargetBranch`"!" -Level error -LineFeed 1
  Exit 02004
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
    Exit 02005
  }
}
Write-GifOutput "[DeleteBranch.ps1::Remote] $Remote" -Level verbose

$BranchExists = & git rev-parse --verify $TargetBranch 2>$null
Write-GifOutput "[MergeInto.ps1::BranchExists] $BranchExists" -Level verbose
$RemoteBranchExists = & git ls-remote --heads $Remote "$TargetBranch" 2>$null
Write-GifOutput "[MergeInto.ps1::RemoteBranchExists] $RemoteBranchExists" -Level verbose
if (-not $BranchExists -and -not $RemoteBranchExists) {
  Write-GifOutput "Target branch `"$TargetBranch`" does not exist locally and remotely" -Level error -LineFeed 1
  Exit 02006
}

# This config is used for functions in "Modules/Core/Core.psm1"
Initialize-GifCore CoreConfig @{ }

# == Main Task ==
try {
  if ($Remote -and $BranchExists) {
    # `git fetch` output nothing, so that we should use `-LineFeed 1` to escape blank line
    Write-GifOutput "Fetch from remote `"$Remote`" (prune) ..." -ShowCurrentBranch -LineFeed 1
    GifCore fetch $Remote --prune
  }

  if ($BranchExists) {
    Write-GifOutput "Delete branch `"$TargetBranch`" on local..." -ShowCurrentBranch
    GifCore branch -d $TargetBranch
  }

  if ($Remote -and $RemoteBranchExists) {
    Write-GifOutput "Delete branch `"$TargetBranch`" on remote..." -ShowCurrentBranch
    GifCore push -d $Remote $TargetBranch
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
    Exit 02201
  }
}

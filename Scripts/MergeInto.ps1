<#
.DESCRIPTION
Merge "current branch" into "target branch"
.PARAMETER TargetBranch
The branch to merge into
.PARAMETER Options
Command options:
--manual-push, -m: Manual push target branch to remote
--manual-back, -r: Manual back from target branch to source branch
#>

param (
  [string]$TargetBranch,
  [Parameter(ValueFromRemainingArguments)]
  [string[]]$Options
)

# == Init & Check ==
Write-GifOutput "[MergeInto.ps1::Param]`nTargetBranch: $TargetBranch`nOptions: $($Options -join "`n")" -Level verbose

if (-not $TargetBranch) {
  Write-GifOutput 'Target branch cannot be null or empty!' -Level error -LineFeed 1
  Exit 01001
}

$HiddenFolders = Get-ChildItem -Name -Attributes D+H
Write-GifOutput "[MergeInto.ps1::HiddenFolders]`n$($HiddenFolders -join "`n")" -Level verbose
if ('.git' -cnotin $HiddenFolders) {
  Write-GifOutput 'You are not in a git repository!' -Level error -LineFeed 1
  Exit 01002
}

$Branches = & git for-each-ref --format='%(refname:short)' refs/heads/
Write-GifOutput "[MergeInto.ps1::Branches]`n$($Branches -join "`n")" -Level verbose
if (-not $Branches) {
  Write-GifOutput 'Your repository has no branch now, create a branch by command "git branch -c <branch>"!' -Level error -LineFeed 1
  Exit 01003
}

$BranchExists = & git rev-parse --verify $TargetBranch 2>$null
Write-GifOutput "[MergeInto.ps1::BranchExists] $BranchExists" -Level verbose
if (-not $BranchExists) {
  Write-GifOutput "Target branch `"$TargetBranch`" does not exist locally" -Level error -LineFeed 1
  Exit 01004
}

$SourceBranch = & git branch --show-current
Write-GifOutput "[MergeInto.ps1::SourceBranch] $SourceBranch" -Level verbose
if ($SourceBranch -ceq $TargetBranch) {
  Write-GifOutput "You don't need merge branch `"$TargetBranch`" into itself!" -Level error -LineFeed 1
  Exit 01005
}

$Remote = & git remote
if ($Remote -is [array]) {
  Write-GifOutput "[MergeInto.ps1::Remote]`n$($Remote -join "`n")" -Level verbose
  Write-GifOutput 'Detected multiple remotes!' -Level warn
  if ('origin' -cin $Remote) {
    $Remote = 'origin'
    Write-GifOutput 'Detected remote named "origin", auto switch to it!' -Level warn
  }
  else {
    Write-GifOutput 'Could not find remote named "origin"!' -Level error -LineFeed 1
    Exit 01006
  }
}
Write-GifOutput "[MergeInto.ps1::Remote] $Remote" -Level verbose

# This config is used for functions in "Modules/Core/Core.psm1"
Initialize-GifCore CoreConfig @{ }

$ManualPush = ('--manual-push' -cin $Options) -or ('-m' -cin $Options)
$ManualReset = ('--manual-back' -cin $Options) -or ('-b' -cin $Options)

# == Main Task ==
try {
  if ($Remote) {
    # `git fetch` output nothing, so that we should use `-LineFeed 1` to escape blank line
    Write-GifOutput "Fetch from all remote..." -ShowCurrentBranch -LineFeed 1
    GifCore fetch --all
  }

  Write-GifOutput "Switch branch from `"$SourceBranch`" to `"$TargetBranch`"..." -ShowCurrentBranch
  GifCore switch $TargetBranch

  if ($Remote) {
    Write-GifOutput "Pull from remote (rebase mode)..." -ShowCurrentBranch
    GifCore pull $Remote $TargetBranch --rebase
  }

  Write-GifOutput "Merge branch `"$SourceBranch`" into `"$TargetBranch`"..." -ShowCurrentBranch
  # Write-Progress -Activity "Merging $SourceBranch to $TargetBranch" -Status "Processing"
  GifCore merge $SourceBranch -m "merge: merge branch `"$SourceBranch`" into `"$TargetBranch`""
  # Write-Progress -Completed

  if ($Remote -and -not $ManualPush) {
    Write-GifOutput "Push to remote..." -ShowCurrentBranch
    GifCore push $Remote $TargetBranch
  }
}
# == Clean ==
catch {
  Write-GifOutput $_ -Level error
  if ($_ -match '^CONFLICT \(.+\):|Merge conflict') {
    $Script:ErrorType = 'MergeConflict'
  }
  else {
    $Script:ErrorType = 'Other'
  }
  # Error: Merge conflict
  if ($Script:ErrorType -ceq 'MergeConflict') {
    $Confirmed = Wait-GifConfirm "You should resolve this conflict manually, or just abort this  merge?"
    if ($Confirmed) {
      Write-GifOutput 'Abort merge...'
      GifCore merge --abort
    }
  }
}
finally {
  if ((-not $ManualReset) -and ($Script:ErrorType -cne 'MergeConflict')) {
    Reset-GifWorkspace @{ 'Branch' = $SourceBranch }
  }
  # Error: Merge conflict
  if ($Script:ErrorType -ceq 'Other') {
    Exit 01201
  }
  elseif ($Script:ErrorType -ceq 'MergeConflict') {
    Exit 01202
  }
}

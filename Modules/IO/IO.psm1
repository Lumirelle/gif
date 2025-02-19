<#
.DESCRIPTION
Beautified output
.PARAMETER Message
Output message
.PARAMETER Level
Output level, case insensitive, support Info, Git, Warn, Verbose, Error (Default: Info)
Attention: "-Level verbose" output controls by "-Verbose" parameter
.PARAMETER LineFeed
-LineFeed 0 -> Inline
-LineFeed 1 -> New line
-LineFeed 2 -> Blank between each line (Default)
...
Attention: "-Level verbose" does not support inline output
.PARAMETER ShowCurrentBranch
Whether to show current branch in output (Default: false)
#>
function Write-GifOutput {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Message,
    [ValidateSet('Info', 'Git', 'Warn', 'Verbose', 'Error', IgnoreCase = $true)]
    [string]$Level = 'Info',
    [int]$LineFeed = 2,
    [switch]$ShowCurrentBranch = $false
  )
  $Message += "`n" * ([Math]::Max(0, $LineFeed - 1))

  if ($ShowCurrentBranch) {
    $Message = "`u{e725} $(git branch --show-current): $Message"
  }

  switch ($Level) {
    'info' {
      Write-Host $Message -ForegroundColor Cyan -NoNewline:($LineFeed -eq 0)
    }
    'git' {
      Write-Host $Message -ForegroundColor DarkGray -NoNewline:($LineFeed -eq 0)
    }
    'warn' {
      Write-Host $Message -ForegroundColor Yellow -NoNewline:($LineFeed -eq 0)
    }
    'verbose' {
      Write-Verbose $Message -Verbose:$Global:GifVerbose # Not support inline output
    }
    'error' {
      Write-Host '[!] ' -NoNewline -ForegroundColor Red
      Write-Host $Message
    }
    Default {
      Write-GifOutput 'No such output level in function "Modules/IO/IO.psm1::Write-GifOutput"!' -Level error
    }
  }
}

<#
.DESCRIPTION
Beautified input
.PARAMETER Prompt
Input prompt
.PARAMETER ShowCurrentBranch
Whether to show current branch in input (Default: false)
#>
function Read-GifInput {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Prompt,
    [switch]$ShowCurrentBranch = $false
  )
  Write-GifOutput $Prompt -LineFeed 0 -ShowCurrentBranch:$ShowCurrentBranch
  $Result = Read-Host
  Write-GifOutput ' ' -LineFeed 1
  return $Result -replace '[;|&]', '' # Filter dangerous characters
}

<#
.DESCRIPTION
Ask input until user confirm or reject (Y or N, case insensitive, you can change them as you wish)
.PARAMETER Prompt
Input prompt
.PARAMETER ShowCurrentBranch
Whether to show current branch in input (Default: false)
.PARAMETER ChoiceConfirm
Confirm choice (Default: Y)
.PARAMETER ChoiceReject
Reject choice (Default: N)
#>
function Wait-GifConfirm {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Prompt,
    [switch]$ShowCurrentBranch = $false,
    [string]$ChoiceConfirm = 'Y',
    [string]$ChoiceReject = 'N'
  )
  $Choice = Read-GifInput "$Prompt [$ChoiceConfirm/$ChoiceReject]: " -ShowCurrentBranch:$ShowCurrentBranch
  while ($true) {
    switch ($Choice.ToLower()) {
      $ChoiceConfirm {
        return $true
      }
      $ChoiceReject {
        return $false
      }
      Default {
        $Choice = Read-GifInput "Just tell me `"$ChoiceConfirm`" or `"$ChoiceReject`", you fool [$ChoiceConfirm/$ChoiceReject]: " -ShowCurrentBranch:$ShowCurrentBranch
      }
    }
  }
}

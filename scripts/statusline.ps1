[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$e       = [char]27
$cyan    = "$e[38;5;45m"
$green   = "$e[38;5;78m"
$yellow  = "$e[38;5;220m"
$orange  = "$e[38;5;208m"
$red     = "$e[38;5;196m"
$magenta = "$e[38;5;177m"
$dim     = "$e[2m"
$bold    = "$e[1m"
$reset   = "$e[0m"
$sep     = "$dim | $reset"

try {
    $inputStream = [System.IO.StreamReader]::new([System.Console]::OpenStandardInput())
    $rawInput    = $inputStream.ReadToEnd()
    $inputStream.Close()
    $json = $rawInput | ConvertFrom-Json
} catch {
    Write-Output "${dim}statusline: waiting...$reset"
    exit 0
}

# Session tag (first 8 chars of session_id)
$sessionId = if ($json.session_id) { $json.session_id } else { "" }
$sessionTag = if ($sessionId.Length -ge 8) { $sessionId.Substring(0, 8) }
              elseif ($sessionId.Length -gt 0) { $sessionId }
              else { "new" }
$sessionPart = "${magenta}${bold}S:${reset}${magenta}$sessionTag${reset}"

# Context free percentage (color-coded)
$usedPct = 0
try {
    if ($json.context_window -and $null -ne $json.context_window.used_percentage) {
        $usedPct = [math]::Round([double]$json.context_window.used_percentage)
    }
} catch { $usedPct = 0 }
$freePct = 100 - $usedPct
$ctxColor = if     ($freePct -gt 60) { $green  }
            elseif ($freePct -gt 30) { $yellow }
            elseif ($freePct -gt 15) { $orange }
            else                     { $red    }
$barLen  = 5
$filled  = [math]::Max(0, [math]::Min($barLen, [math]::Round($usedPct * $barLen / 100)))
$empty   = $barLen - $filled
$barUsed = ("$([char]0x2593)" * $filled)
$barFree = ("$([char]0x2591)" * $empty)
$ctxBar  = "${red}$barUsed${green}$barFree${reset}"
$contextPart = "${ctxColor}${bold}CTX Free:${reset} ${ctxColor}${freePct}%${reset} $ctxBar"

# Repository name
$projectDir = if ($json.workspace.project_dir) { $json.workspace.project_dir }
              elseif ($json.workspace.current_dir) { $json.workspace.current_dir }
              elseif ($json.cwd) { $json.cwd }
              else { "" }
$repoName = if ($projectDir) { Split-Path $projectDir -Leaf } else { "unknown" }
$repoPart = "${cyan}${bold}Repo:${reset}${cyan}$repoName${reset}"

# Git branch + dirty indicator
$cwd = if ($json.cwd) { $json.cwd }
       elseif ($json.workspace.current_dir) { $json.workspace.current_dir }
       else { $PWD.Path }
$branch = ""
try {
    $branch = (git -C $cwd branch --show-current 2>$null)
    if (-not $branch) {
        $headFile = Join-Path (git -C $cwd rev-parse --git-dir 2>$null) "HEAD"
        if (Test-Path $headFile) {
            $headContent = Get-Content $headFile -Raw
            if ($headContent -match "ref: refs/heads/(.+)") {
                $branch = $Matches[1].Trim()
            } else {
                $branch = $headContent.Substring(0, 7)
            }
        }
    }
} catch { $branch = "" }
$branchDisplay = if ($branch) { $branch } else { "no-git" }
$dirty = ""
try {
    $status = git -C $cwd status --porcelain 2>$null
    if ($status) { $dirty = "${orange}*${reset}" }
} catch {}
$branchPart = "${green}${bold}Branch:${reset}${green}$branchDisplay${reset}$dirty"

Write-Output "$sessionPart$sep$contextPart$sep$repoPart$sep$branchPart"

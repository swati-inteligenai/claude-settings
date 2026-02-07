$repo = "$env:USERPROFILE\repos\claude-code-config"
$claude = "$env:USERPROFILE\.claude"

Set-Location $repo
git pull

New-Item -Path $claude -ItemType Directory -Force | Out-Null

$items = @(
    @{ Src = "$repo\settings.json";            Dst = "$claude\settings.json" }
    @{ Src = "$repo\CLAUDE.md";                Dst = "$claude\CLAUDE.md" }
    @{ Src = "$repo\keybindings.json";         Dst = "$claude\keybindings.json" }
    @{ Src = "$repo\scripts\statusline.ps1";   Dst = "$claude\statusline.ps1" }
)
foreach ($item in $items) {
    if (Test-Path $item.Src) { Copy-Item $item.Src $item.Dst -Force }
}
foreach ($dir in @("commands", "skills", "agents")) {
    if (Test-Path "$repo\$dir") {
        Copy-Item "$repo\$dir" "$claude\$dir" -Recurse -Force
    }
}

Write-Host "Config pulled from GitHub to $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "NOTE: Run 'claude auth login' if credentials aren't set up on this machine." -ForegroundColor Yellow

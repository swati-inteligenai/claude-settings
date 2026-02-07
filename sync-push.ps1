$repo = "$env:USERPROFILE\repos\claude-code-config"
$claude = "$env:USERPROFILE\.claude"

$items = @(
    @{ Src = "$claude\settings.json";    Dst = "$repo\settings.json" }
    @{ Src = "$claude\CLAUDE.md";        Dst = "$repo\CLAUDE.md" }
    @{ Src = "$claude\keybindings.json"; Dst = "$repo\keybindings.json" }
    @{ Src = "$claude\statusline.ps1";   Dst = "$repo\scripts\statusline.ps1" }
)
New-Item -Path "$repo\scripts" -ItemType Directory -Force | Out-Null
foreach ($item in $items) {
    if (Test-Path $item.Src) { Copy-Item $item.Src $item.Dst -Force }
}
foreach ($dir in @("commands", "skills", "agents")) {
    if (Test-Path "$claude\$dir") {
        Copy-Item "$claude\$dir" "$repo\$dir" -Recurse -Force
    }
}

Set-Location $repo
git add -A
$ts = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "sync: config update $ts from $env:COMPUTERNAME"
git push
Write-Host "Config pushed to GitHub from $env:COMPUTERNAME" -ForegroundColor Green

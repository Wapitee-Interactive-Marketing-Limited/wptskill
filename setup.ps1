# Wapitee Skill Installer for Windows — one-time setup for team-wide skill distribution
$ErrorActionPreference = "Stop"

$RepoDir = $PSScriptRoot
$ExpectedDir = Join-Path $env:LOCALAPPDATA "Claude\skills\wapitee"
$SkillsDir = Join-Path $env:LOCALAPPDATA "Claude\skills"
$ClaudeMd = Join-Path $env:LOCALAPPDATA "Claude\CLAUDE.md"

$WapiteeBlockStart = "# >>> WAPITEE SKILLS START"
$WapiteeBlockEnd = "# <<< WAPITEE SKILLS END"

# ─── 1. Ensure repo is linked at %LOCALAPPDATA%\Claude\skills\wapitee ───────
if ($RepoDir -ne $ExpectedDir) {
    Write-Host "Linking repository to $ExpectedDir..."
    $ParentDir = Split-Path -Parent $ExpectedDir
    if (!(Test-Path $ParentDir)) {
        New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
    }
    if (Test-Path $ExpectedDir) {
        $item = Get-Item $ExpectedDir -Force
        if ($item.Attributes -match "ReparsePoint") {
            Remove-Item $ExpectedDir -Force
        } else {
            Write-Error "Error: $ExpectedDir already exists and is not a symlink/junction.`n  Remove it manually and re-run setup."
            exit 1
        }
    }
    # Use Junction for directories (does not require admin on Windows 10+)
    New-Item -ItemType Junction -Path $ExpectedDir -Target $RepoDir | Out-Null
}

# ─── 2. Register each skill as a native Claude Code skill ───────────────────
$linked = @()
$mdFiles = Get-ChildItem -Path $ExpectedDir -Filter "*.md" -File
foreach ($file in $mdFiles) {
    $filename = $file.Name
    switch ($filename) {
        "README.md" { continue }
        "FEEDBACK_LOG.md" { continue }
        "SKILL_TEMPLATE.md" { continue }
    }
    $skillName = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    $targetDir = Join-Path $SkillsDir "wapitee-$skillName"
    if (!(Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    $targetSkillMd = Join-Path $targetDir "SKILL.md"
    if (Test-Path $targetSkillMd) {
        $item = Get-Item $targetSkillMd -Force
        if ($item.Attributes -match "ReparsePoint") {
            Remove-Item $targetSkillMd -Force
        } else {
            Remove-Item $targetSkillMd -Force
        }
    }
    # Try symbolic link first, then hard link, then copy as fallback
    try {
        New-Item -ItemType SymbolicLink -Path $targetSkillMd -Target $file.FullName | Out-Null
    } catch {
        try {
            New-Item -ItemType HardLink -Path $targetSkillMd -Target $file.FullName | Out-Null
        } catch {
            Copy-Item -Path $file.FullName -Destination $targetSkillMd -Force
        }
    }
    $linked += "wapitee-$skillName"
}

# ─── 3. Inject global prompt into %LOCALAPPDATA%\Claude\CLAUDE.md ───────────
$ConfigDir = Split-Path -Parent $ClaudeMd
if (!(Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}

if (Test-Path $ClaudeMd) {
    $lines = Get-Content $ClaudeMd
    $outputLines = @()
    $skip = $false
    foreach ($line in $lines) {
        if ($line -eq $WapiteeBlockStart) {
            $skip = $true
            continue
        }
        if ($line -eq $WapiteeBlockEnd) {
            $skip = $false
            continue
        }
        if (!$skip) {
            $outputLines += $line
        }
    }
    # Trim trailing blank lines to keep file neat
    while ($outputLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($outputLines[$outputLines.Count - 1])) {
        $outputLines = $outputLines[0..($outputLines.Count - 2)]
    }
    $outputLines | Set-Content $ClaudeMd -Encoding UTF8
}

$block = @"
$WapiteeBlockStart
# Wapitee Skill Registry

You have access to the Wapitee Skill Registry at $ExpectedDir.

Before answering any user request related to development, deployment, tracking, analytics, or DevOps:
1. Read $ExpectedDir\README.md to determine which skill to use
2. Read $ExpectedDir\FEEDBACK_LOG.md for any known issues or lessons learned
3. Then read the matched skill file(s)
4. Follow the instructions in that skill strictly
5. After generating the output, present the Post-Deployment Checklist from the skill
6. Ask the user: "是否需要将本次遇到的问题或改进建议记录到 FEEDBACK_LOG.md？"
$WapiteeBlockEnd
"@

Add-Content -Path $ClaudeMd -Value $block -Encoding UTF8

# ─── 4. Done ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Wapitee skills installed successfully."
Write-Host "  Registry:      $ExpectedDir"
Write-Host "  Linked skills: $($linked -join ' ')"
Write-Host "  Global config: $ClaudeMd"
Write-Host ""
Write-Host "How team members should install:"
Write-Host "  git clone https://github.com/Wapitee-Interactive-Marketing-Limited/wptskill.git `"`$env:LOCALAPPDATA\Claude\skills\wapitee`""
Write-Host "  cd `"`$env:LOCALAPPDATA\Claude\skills\wapitee`"; .\setup.ps1"
Write-Host ""
Write-Host "How to update when skills change:"
Write-Host "  cd `"`$env:LOCALAPPDATA\Claude\skills\wapitee`"; git pull; .\setup.ps1"
Write-Host ""

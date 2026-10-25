# Requires -Version 5.1
# Windows integration tests for QA Instinct Lifecycle Manager (install.ps1)

$ErrorActionPreference = 'Stop'

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Starting QA Instinct Lifecycle Integration Tests (PowerShell)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Create a sandboxed workspace within the repository directory
$repoDir = Resolve-Path "$PSScriptRoot\.."
$sandboxDir = Join-Path $repoDir "tests\sandbox-win"

if (Test-Path $sandboxDir) {
    Remove-Item -Path $sandboxDir -Recurse -Force -ErrorAction SilentlyContinue
}

New-Item -ItemType Directory -Path "$sandboxDir\project" | Out-Null
New-Item -ItemType Directory -Path "$sandboxDir\mock-home" | Out-Null

# Redirect environment variables to use mock directories
$env:USERPROFILE = "$sandboxDir\mock-home"
$env:HOME = "$sandboxDir\mock-home"

# Initialize mock git repository in sandboxed project folder
Set-Location -Path "$sandboxDir\project"
git init -b main
git config user.name "QA Tester Win"
git config user.email "qa-win@tester.com"

Write-Host "[OK] Sandboxed Windows environment configured successfully." -ForegroundColor Green

# Return to repo root where compile script and installer are
Set-Location -Path $repoDir

# Compile adapters first
Write-Host "Compiling rule adapters..." -ForegroundColor Yellow
powershell.exe -ExecutionPolicy Bypass -File .\generate-adapters.ps1 -Clean
if ($LASTEXITCODE -ne 0) { throw "generate-adapters.ps1 failed with exit status $LASTEXITCODE" }

# Reads a file exactly as v2.2.0 shipped it, as raw bytes - used to simulate a pre-v2.3.3 install
# still holding an older release's content. ReadAllBytes keeps the bytes (and therefore the
# SHA-256) unchanged; a missing fixture throws, failing the test setup.
function Get-ReleaseFixtureBytes {
    param([string]$RelativePath)
    return [System.IO.File]::ReadAllBytes((Join-Path $repoDir "tests\fixtures\release-v2.2.0\$(Split-Path -Leaf $RelativePath)"))
}

# -----------------------------------------------------------------------------
# TEST 1: Fresh Installation (Project & Global - All Editors)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 1: Fresh Installation (both scopes, all editors)..." -ForegroundColor Yellow

Set-Location -Path "$sandboxDir\project"
powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target both -Editor all -NonInteractive
if ($LASTEXITCODE -ne 0) { throw "install.ps1 failed with exit status $LASTEXITCODE" }

Write-Host "Verifying project-level installation..." -ForegroundColor Cyan
if (-not (Test-Path ".claude\commands\qa.md")) { throw "Missing qa.md in project commands" }
if (-not (Test-Path ".claude\rules\accessibility-qa.md")) { throw "Missing accessibility-qa.md in project rules" }
if (-not (Test-Path ".claude\rules\security-qa.md")) { throw "Missing security-qa.md in project rules" }
if (-not (Test-Path ".claude\hooks\validate-tc-format.sh")) { throw "Missing validator hook in project" }
if (-not (Test-Path ".git\hooks\pre-commit")) { throw "Missing git pre-commit hook in project" }
if (-not (Test-Path ".cursor\rules\qa-instinct.mdc")) { throw "Missing cursor rule in project" }
if (-not (Test-Path ".cursor\skills\qa-cases\SKILL.md")) { throw "Missing cursor skill in project" }
if (-not (Test-Path ".windsurf\rules\qa-instinct-security-qa.md")) { throw "Missing windsurf rule in project" }
if (-not (Test-Path ".windsurf\skills\qa\SKILL.md")) { throw "Missing windsurf skill in project" }
if (-not (Test-Path ".github\copilot-instructions.md")) { throw "Missing copilot instructions in project" }
if (-not (Test-Path ".github\skills\qa-plan\SKILL.md")) { throw "Missing copilot skill in project" }
if (-not (Test-Path ".cline\rules\qa-instinct.md")) { throw "Missing cline rules in project" }
if (-not (Test-Path ".agents\rules\qa-instinct.md")) { throw "Missing antigravity rule in project" }
if (-not (Test-Path ".agents\skills\qa\SKILL.md")) { throw "Missing antigravity skill in project" }

Write-Host "Verifying global-level installation..." -ForegroundColor Cyan
if (-not (Test-Path "$env:USERPROFILE\.claude\commands\qa.md")) { throw "Missing global qa.md" }
if (-not (Test-Path "$env:USERPROFILE\.cursor\skills\qa\SKILL.md")) { throw "Missing global cursor skill" }
if (-not (Test-Path "$env:USERPROFILE\.codeium\windsurf\skills\qa\SKILL.md")) { throw "Missing global windsurf skill" }
if (-not (Test-Path "$env:USERPROFILE\.gemini\config\skills\qa\SKILL.md")) { throw "Missing global antigravity skill" }
if (-not (Test-Path "$env:USERPROFILE\.git-templates\hooks\pre-commit")) { throw "Missing global git templates pre-commit hook" }

Write-Host "[OK] Test 1 passed successfully! All files are in their correct spots." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 2: Update Operations
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 2: Update (Verifying no overwrite prompts)..." -ForegroundColor Yellow

# Modify a file to simulate an old version
"Version: 1.0.0" | Out-File -FilePath ".claude\commands\qa.md" -Encoding utf8

# Run update
powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target both -Editor all -NonInteractive -Update
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Update failed with exit status $LASTEXITCODE" }

# Verify it was updated back to new version
$content = Get-Content -Path ".claude\commands\qa.md" -Raw
if ($content -match "Version: 1.0.0") {
    throw "Update failed: old version was not overwritten"
}

# The edit above stands in for a user-modified file: update must preserve it in a backup
# rather than discarding it.
$editBackup = Get-ChildItem -Path ".claude\commands" -Filter 'qa.md.qa-skills-backup-*' | Select-Object -First 1
if (-not $editBackup) { throw "Update overwrote a modified file without a backup" }
if ((Get-Content -Raw -LiteralPath $editBackup.FullName) -notmatch "Version: 1.0.0") {
    throw "Backup does not contain the modified content"
}
# This backup is left in place deliberately: it is the user's data, uninstall must never
# delete it, and Test 3 below asserts exactly that (a real backup surviving a real uninstall)
# instead of erasing the evidence to assert an empty tree.

Write-Host "[OK] Test 2 passed successfully! Update overwrote older files without asking and kept a backup." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 3: Uninstallation / Purging
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 3: Uninstallation (both scopes, all editors)..." -ForegroundColor Yellow

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target both -Editor all -NonInteractive -Uninstall
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall failed with exit status $LASTEXITCODE" }

Write-Host "Verifying project-level removal (except the user backup Test 2 created, which must survive)..." -ForegroundColor Cyan
if (Test-Path ".claude\commands\qa.md") { throw "Package qa.md still exists in project commands" }
if (Test-Path ".claude\rules\security-qa.md") { throw "Package security-qa.md still exists in project rules" }
if (Test-Path ".claude\rules") { throw "Now-empty project rules folder was not cleaned up" }
if (Test-Path ".claude\hooks") { throw "Now-empty project hooks folder was not cleaned up" }
if (Test-Path ".claude\skills") { throw "Now-empty project skills folder was not cleaned up" }
if (Test-Path ".claude\agents") { throw "Now-empty project agents folder was not cleaned up" }
if (-not (Test-Path $editBackup.FullName)) { throw "Uninstall deleted the user's backup from Test 2" }
if ((Get-Content -Raw -LiteralPath $editBackup.FullName) -notmatch "Version: 1.0.0") { throw "The surviving backup's content changed" }
# The backup must be the ONLY thing left. Naming individual files would let anything not
# named here survive unnoticed, which is what asserting an empty tree used to rule out.
$remainingFiles = @(Get-ChildItem -Path ".claude" -Recurse -File -Force)
if ($remainingFiles.Count -ne 1 -or $remainingFiles[0].FullName -ne $editBackup.FullName) {
    $remainingFiles | ForEach-Object { Write-Host "  $($_.FullName)" }
    throw "Uninstall left files behind besides the user's backup"
}
if (Test-Path ".git\hooks\pre-commit") { throw "Git pre-commit hook still exists in project" }
if (Test-Path ".cursor") { throw ".cursor folder still exists in project" }
if (Test-Path ".windsurf") { throw ".windsurf folder still exists in project" }
if (Test-Path ".github") { throw ".github folder still exists in project" }
if (Test-Path ".cline") { throw ".cline folder still exists in project" }
if (Test-Path ".agents") { throw ".agents folder still exists in project" }

Write-Host "Verifying global-level removal..." -ForegroundColor Cyan
if (Test-Path "$env:USERPROFILE\.claude") { throw "Global .claude folder still exists" }
if (Test-Path "$env:USERPROFILE\.cursor") { throw "Global .cursor folder still exists" }
if (Test-Path "$env:USERPROFILE\.codeium") { throw "Global .codeium folder still exists" }
if (Test-Path "$env:USERPROFILE\.gemini") { throw "Global .gemini folder still exists" }
if (Test-Path "$env:USERPROFILE\.git-templates\hooks\pre-commit") { throw "Global git templates pre-commit hook still exists" }

Write-Host "[OK] Test 3 passed successfully! Uninstallation purged package files while leaving the user's backup untouched." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 4: Project-owned files survive install and uninstall
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 4: Project-owned .claude files are preserved (install + uninstall)..." -ForegroundColor Yellow

$ownedProject = Join-Path $sandboxDir "owned-project"
New-Item -ItemType Directory -Path $ownedProject | Out-Null
Set-Location -Path $ownedProject
git init -q -b main

# Files a project may already have that are NOT part of the qa-instinct package
$ownedFiles = @(
    '.claude\commands\team-deploy.md',
    '.claude\rules\team-conventions.md',
    '.claude\agents\team-reviewer.md',
    '.claude\skills\team-skill\SKILL.md',
    '.claude\hooks\team-hook.sh'
)
foreach ($f in $ownedFiles) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $f) -Force | Out-Null
    Set-Content -Path $f -Value "project-owned: $f" -Encoding utf8
}

function Assert-OwnedFilesIntact([string]$Stage) {
    foreach ($f in $ownedFiles) {
        if (-not (Test-Path $f) -or (Get-Content -Path $f -Raw).Trim() -ne "project-owned: $f") {
            throw "$Stage deleted or changed project-owned file: $f"
        }
    }
}

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 4) failed with exit status $LASTEXITCODE" }

Write-Host "Verifying project-owned files survived install..." -ForegroundColor Cyan
Assert-OwnedFilesIntact 'Install'
if (-not (Test-Path ".claude\commands\qa.md")) { throw "Package qa.md was not installed alongside project files" }

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall (Test 4) failed with exit status $LASTEXITCODE" }

Write-Host "Verifying project-owned files survived uninstall..." -ForegroundColor Cyan
Assert-OwnedFilesIntact 'Uninstall'

Write-Host "Verifying every package file was removed..." -ForegroundColor Cyan
$claudeSrc = Join-Path $repoDir '.claude'
foreach ($folder in @('commands', 'rules', 'skills', 'agents', 'hooks')) {
    Get-ChildItem -Path (Join-Path $claudeSrc $folder) -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($claudeSrc.Length).TrimStart('\', '/')
        if (Test-Path (Join-Path '.claude' $rel)) { throw "Uninstall left package file: .claude\$rel" }
    }
}

Write-Host "[OK] Test 4 passed successfully! Project-owned files were preserved and package files removed." -ForegroundColor Green

# Test 5 moved to conformance case 002 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 6: Uninstall touches only what it installed
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 6: Uninstall leaves untracked and modified files alone..." -ForegroundColor Yellow

$untrackedProject = Join-Path $sandboxDir "untracked-project"
New-Item -ItemType Directory -Path $untrackedProject -Force | Out-Null
Set-Location -Path $untrackedProject
git init -q -b main

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 6) failed with exit status $LASTEXITCODE" }

# (a) a file that appeared after install (project's own, or an older version's leftover)
Set-Content -Path ".claude\rules\legacy-or-own.md" -Value "added after install" -Encoding utf8
# (b) a package file the user edited after install
Set-Content -Path ".claude\rules\testing-guidelines.md" -Value "user edited this" -Encoding utf8

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall (Test 6) failed with exit status $LASTEXITCODE" }

if ((Get-Content -Raw ".claude\rules\legacy-or-own.md").Trim() -ne "added after install") { throw "Uninstall deleted a file it never installed" }
if ((Get-Content -Raw ".claude\rules\testing-guidelines.md").Trim() -ne "user edited this") { throw "Uninstall deleted a package file the user had modified" }
if (Test-Path ".claude\rules\security-qa.md") { throw "Uninstall left an unmodified package rule behind" }

Write-Host "[OK] Test 6 passed successfully! Only unmodified installed files were removed." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 7: Same protection at global scope
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 7: Colliding file in the home directory is backed up, not destroyed..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude\rules" -Force | Out-Null
$homeContent = "MY OWN GLOBAL TESTING GUIDELINES"
Set-Content -Path "$env:USERPROFILE\.claude\rules\testing-guidelines.md" -Value $homeContent -Encoding utf8

$globalCaller = Join-Path $sandboxDir "global-caller"
New-Item -ItemType Directory -Path $globalCaller -Force | Out-Null
Set-Location -Path $globalCaller
powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target global -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Target global (Test 7) failed with exit status $LASTEXITCODE" }

$homeBackup = Get-ChildItem -Path "$env:USERPROFILE\.claude\rules" -Filter 'testing-guidelines.md.qa-skills-backup-*' | Select-Object -First 1
if (-not $homeBackup) { throw "Global install overwrote a colliding file without a backup" }
if ((Get-Content -Raw -LiteralPath $homeBackup.FullName).Trim() -ne $homeContent) { throw "Global backup does not contain the original content" }

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target global -Editor claude -NonInteractive -Uninstall
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall global (Test 7) failed with exit status $LASTEXITCODE" }
if ((Get-Content -Raw -LiteralPath $homeBackup.FullName).Trim() -ne $homeContent) { throw "Global uninstall destroyed the backup" }

Write-Host "[OK] Test 7 passed successfully! Global-scope collisions are preserved too." -ForegroundColor Green

# Test 8 moved to conformance cases 008 and 011 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 9: Manifest round-trips across platforms
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 9: A manifest rewritten into install.sh's on-disk form still uninstalls cleanly..." -ForegroundColor Yellow

$roundtripProject = Join-Path $sandboxDir "roundtrip-project"
New-Item -ItemType Directory -Path $roundtripProject -Force | Out-Null
Set-Location -Path $roundtripProject
git init -q -b main

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 9) failed with exit status $LASTEXITCODE" }

if (-not (Test-Path ".qa-skills-manifest")) { throw "Install did not write .qa-skills-manifest" }

# Rewrite the manifest into install.sh's exact on-disk form: no BOM, LF line endings, and
# forward-slash path separators.
$mfPath = Resolve-Path ".qa-skills-manifest"
$lines = Get-Content -LiteralPath $mfPath | ForEach-Object { $_ -replace '\\', '/' }
$lfContent = ($lines -join "`n") + "`n"
[System.IO.File]::WriteAllText($mfPath, $lfContent, (New-Object System.Text.UTF8Encoding($false)))

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall (Test 9) failed with exit status $LASTEXITCODE" }

Write-Host "Verifying every installed file was actually removed..." -ForegroundColor Cyan
if (Test-Path ".claude") { throw ".claude folder still exists - files installed under a foreign-platform manifest were orphaned" }
if (Test-Path ".qa-skills-manifest") { throw "Manifest still exists after uninstall" }

Write-Host "[OK] Test 9 passed successfully! A foreign-platform manifest (no BOM, LF, forward slashes) still uninstalls cleanly." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 10: A project path containing a space installs and uninstalls without duplicating
# manifest entries
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 10: A project path with a space in it installs and uninstalls cleanly..." -ForegroundColor Yellow

$spaceProject = Join-Path $sandboxDir "space project"
New-Item -ItemType Directory -Path $spaceProject -Force | Out-Null
Set-Location -Path $spaceProject
git init -q -b main

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 10, first install) failed with exit status $LASTEXITCODE" }
$firstInstallLines = @(Get-Content -LiteralPath ".qa-skills-manifest").Count

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 10, second install) failed with exit status $LASTEXITCODE" }
$secondInstallLines = @(Get-Content -LiteralPath ".qa-skills-manifest").Count

if ($firstInstallLines -ne $secondInstallLines) { throw "Re-installing into a path with a space duplicated manifest entries ($firstInstallLines -> $secondInstallLines lines)" }

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall (Test 10) failed with exit status $LASTEXITCODE" }

if (Test-Path ".claude") { throw ".claude folder still exists in a path with a space" }
if (Test-Path ".qa-skills-manifest") { throw "Manifest still exists after uninstall in a path with a space" }

Write-Host "[OK] Test 10 passed successfully! A project path with a space installs and uninstalls cleanly with no duplicate manifest entries." -ForegroundColor Green

# Test 11 moved to conformance case 009 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 12: The manifest is written to disk once per install, atomically - not
# rewritten in full for every installed file
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 12: The manifest is written once, atomically, not rewritten per installed file..." -ForegroundColor Yellow

$atomicProject = Join-Path $sandboxDir "atomic-manifest-project"
New-Item -ItemType Directory -Path $atomicProject -Force | Out-Null
Set-Location -Path $atomicProject
git init -q -b main

$manifestName = ".qa-skills-manifest"

# Watch for every disk write that touches the manifest (or a temp file used to replace it)
# during a single install, so we can tell "rewritten once per file" from "written once, atomically".
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $atomicProject
$watcher.Filter = "$manifestName*"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

$global:manifestEvents = [System.Collections.Generic.List[string]]::new()
$handler = {
    $global:manifestEvents.Add("$($Event.SourceEventArgs.ChangeType):$($Event.SourceEventArgs.Name)")
}
$subCreated = Register-ObjectEvent -InputObject $watcher -EventName Created -Action $handler
$subChanged = Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $handler
$subRenamed = Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $handler

try {
    powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
    if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 12) failed with exit status $LASTEXITCODE" }
    Start-Sleep -Milliseconds 300  # let buffered filesystem events be delivered
}
finally {
    $watcher.EnableRaisingEvents = $false
    Unregister-Event -SourceIdentifier $subCreated.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $subChanged.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $subRenamed.Name -ErrorAction SilentlyContinue
    Remove-Job -Name $subCreated.Name -Force -ErrorAction SilentlyContinue
    Remove-Job -Name $subChanged.Name -Force -ErrorAction SilentlyContinue
    Remove-Job -Name $subRenamed.Name -Force -ErrorAction SilentlyContinue
    $watcher.Dispose()
}

if (-not (Test-Path ".qa-skills-manifest")) { throw "Install did not write .qa-skills-manifest" }
$manifestEntryCount = @(Get-Content -LiteralPath ".qa-skills-manifest").Count

# Only count events that landed on the final manifest name itself (an atomic write via a temp
# file plus rename shows up here as exactly one such event: the rename onto the final name).
$finalNameEvents = @($global:manifestEvents | Where-Object { $_ -like "*:$manifestName" })
Write-Host "  ($manifestEntryCount manifest entries installed; $($finalNameEvents.Count) write(s) observed to $manifestName; raw events: $($global:manifestEvents -join ', '))" -ForegroundColor Cyan

if ($finalNameEvents.Count -gt 2) {
    throw "install.ps1 wrote $manifestName $($finalNameEvents.Count) times while installing $manifestEntryCount files - Set-ManifestEntry is rewriting the whole manifest per file instead of buffering all entries and writing once, atomically"
}

# Demonstrate the real consequence this non-atomic rewriting caused: an interrupted per-file
# rewrite can leave a manifest that still exists but reflects only the first entry that made it
# to disk. Because the manifest exists, the no-manifest fallback never fires, so uninstall keeps
# reporting success while every other installed file is left behind. This is Uninstall-Recorded's
# own handling of a manifest truncated by ANY means - it is unchanged by this fix (which only
# stops an interrupted install from producing this state on its own; a manifest truncated by
# some other means is a separate, not-yet-fixed concern) - so this part passes both before and
# after the fix. It is included to document the real-world impact of the write count assertion
# above.
$truncatedFirstLine = (Get-Content -LiteralPath ".qa-skills-manifest")[0]
[System.IO.File]::WriteAllText((Resolve-Path ".qa-skills-manifest"), "$truncatedFirstLine`n", (New-Object System.Text.UTF8Encoding($false)))

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall (Test 12) failed with exit status $LASTEXITCODE" }

$orphaned = @(Get-ChildItem -Path ".claude" -Recurse -File -ErrorAction SilentlyContinue)
Write-Host "  ($($orphaned.Count) of $($manifestEntryCount - 1) file(s) left orphaned after uninstall ran against a manifest truncated to 1 of $manifestEntryCount entries)" -ForegroundColor Cyan
if ($orphaned.Count -eq 0) { throw "Expected uninstall to leave files orphaned when only 1 of $manifestEntryCount manifest entries survived truncation, since the no-manifest fallback never fires while a (truncated) manifest exists" }

Write-Host "[OK] Test 12 passed successfully! The manifest is written once per install, atomically - an interrupted run can no longer produce a truncated-but-present manifest on its own." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 13: Uninstall reports what actually happened, not a blanket success
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 13: Uninstall reporting matches what was actually removed..." -ForegroundColor Yellow

# --- 13a: a file kept because it changed since install must not be reported as a
#     complete removal ---
$reportKeptProject = Join-Path $sandboxDir "report-kept-project"
New-Item -ItemType Directory -Path $reportKeptProject -Force | Out-Null
Set-Location -Path $reportKeptProject
git init -q -b main

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 13a) failed with exit status $LASTEXITCODE" }
Set-Content -Path ".claude\rules\testing-guidelines.md" -Value "user edited this" -Encoding utf8

$keptOutput = & powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall 2>&1
if ($LASTEXITCODE -ne 0) { Write-Host ($keptOutput -join "`n"); throw "install.ps1 -Uninstall (Test 13a) failed with exit status $LASTEXITCODE" }
$keptText = $keptOutput -join "`n"

Write-Host "Verifying the summary does not claim complete removal when a file was kept..." -ForegroundColor Cyan
if ($keptText -match '(?i)completely removed') { Write-Host $keptText; throw "Uninstall claimed the package was completely removed while a modified file was kept" }
if (-not ($keptText -match '(?i)kept')) { Write-Host $keptText; throw "Uninstall summary did not mention that a file was kept" }

# --- 13b: uninstalling when nothing was ever installed must say so, not claim success ---
$reportEmptyProject = Join-Path $sandboxDir "report-empty-project"
New-Item -ItemType Directory -Path $reportEmptyProject -Force | Out-Null
Set-Location -Path $reportEmptyProject
git init -q -b main

$emptyOutput = & powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall 2>&1
if ($LASTEXITCODE -ne 0) { Write-Host ($emptyOutput -join "`n"); throw "install.ps1 -Uninstall (Test 13b) failed with exit status $LASTEXITCODE" }
$emptyText = $emptyOutput -join "`n"

Write-Host "Verifying the summary does not claim complete removal when nothing was installed..." -ForegroundColor Cyan
if ($emptyText -match '(?i)completely removed') { Write-Host $emptyText; throw "Uninstall claimed the package was completely removed when nothing was installed" }

Write-Host "[OK] Test 13 passed successfully! Uninstall reports what was actually removed and what was kept." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 14: A project path containing non-ASCII characters installs and uninstalls
# without duplicating manifest entries
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 14: A project path with non-ASCII characters installs and uninstalls cleanly..." -ForegroundColor Yellow

$nonAsciiProject = Join-Path $sandboxDir "café-projëct-日本語"
New-Item -ItemType Directory -Path $nonAsciiProject -Force | Out-Null
Set-Location -Path $nonAsciiProject
git init -q -b main

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 14, first install) failed with exit status $LASTEXITCODE" }
if (-not (Test-Path ".claude\commands\qa.md")) { throw "Missing qa.md in non-ASCII project path" }
$firstInstallLines = @(Get-Content -LiteralPath ".qa-skills-manifest").Count

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 14, second install) failed with exit status $LASTEXITCODE" }
$secondInstallLines = @(Get-Content -LiteralPath ".qa-skills-manifest").Count

if ($firstInstallLines -ne $secondInstallLines) { throw "Re-installing into a non-ASCII path duplicated manifest entries ($firstInstallLines -> $secondInstallLines lines)" }

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall (Test 14) failed with exit status $LASTEXITCODE" }

if (Test-Path ".claude") { throw ".claude folder still exists in a non-ASCII path" }
if (Test-Path ".qa-skills-manifest") { throw "Manifest still exists after uninstall in a non-ASCII path" }

Write-Host "[OK] Test 14 passed successfully! A project path with non-ASCII characters installs and uninstalls cleanly with no duplicate manifest entries." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 15: The no-manifest fallback removes unmodified package files and keeps
# user-modified ones, for an install made before manifests existed
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 15: Uninstall without a manifest falls back to content-matching removal..." -ForegroundColor Yellow

$noManifestProject = Join-Path $sandboxDir "no-manifest-project"
New-Item -ItemType Directory -Path $noManifestProject -Force | Out-Null
Set-Location -Path $noManifestProject
git init -q -b main

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 15) failed with exit status $LASTEXITCODE" }
if (-not (Test-Path ".qa-skills-manifest")) { throw "Test setup error: install did not write .qa-skills-manifest" }

# Simulate a pre-v2.3.3 install: a file the user modified after installing, and no manifest.
Set-Content -Path ".claude\rules\testing-guidelines.md" -Value "user edited this" -Encoding utf8
Remove-Item -LiteralPath ".qa-skills-manifest" -Force

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall (Test 15) failed with exit status $LASTEXITCODE" }

Write-Host "Verifying the fallback removed an unmodified package file..." -ForegroundColor Cyan
if (Test-Path ".claude\rules\security-qa.md") { throw "No-manifest fallback left an unmodified package file behind" }
if (Test-Path ".claude\commands\qa.md") { throw "No-manifest fallback left an unmodified package file behind" }

Write-Host "Verifying the fallback kept the user's modified file..." -ForegroundColor Cyan
if ((Get-Content -Raw ".claude\rules\testing-guidelines.md").Trim() -ne "user edited this") { throw "No-manifest fallback deleted or changed the user's modified file" }

Write-Host "[OK] Test 15 passed successfully! The no-manifest fallback removed unmodified package files and kept the user's edit." -ForegroundColor Green

# Test 16 moved to conformance case 010 (plan 016 item 6).

# Test 17 moved to conformance case 003 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 18: A destination the user actually edited is still backed up and
# reported - the known-hash lookup must not misfire on real edits
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 18: A genuinely user-edited file is still backed up and reported..." -ForegroundColor Yellow

$userEditProject = Join-Path $sandboxDir "user-edit-project"
New-Item -ItemType Directory -Path $userEditProject -Force | Out-Null
Set-Location -Path $userEditProject
git init -q -b main

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 18) failed with exit status $LASTEXITCODE" }

# Content that was never shipped by any release, standing in for a real user edit made to a
# pre-manifest install.
$userContent = "MY OWN SECURITY POLICY - DO NOT TOUCH"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $userEditProject '.claude\rules\security-qa.md'), "$userContent`n", $utf8NoBom)
$userHash = (Get-FileHash -Algorithm SHA256 -LiteralPath ".claude\rules\security-qa.md").Hash.ToLower()
$knownHashes = Get-Content -LiteralPath "$repoDir\.qa-skills-known-hashes" -Encoding UTF8
if ($knownHashes -match "^$userHash\s") { throw "Test setup error: the user-edit content collides with a known release hash" }
Remove-Item -LiteralPath ".qa-skills-manifest" -Force

# A reinstall, not -Update: with no manifest, update adopts only files a release shipped and
# leaves this one alone (plan 033 item 3), so only install reaches the backup path.
powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 18, reinstall) failed with exit status $LASTEXITCODE" }

Write-Host "Verifying the user's edit was backed up, not silently discarded..." -ForegroundColor Cyan
$backup = Get-ChildItem -Path ".claude\rules" -Filter 'security-qa.md.qa-skills-backup-*' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $backup) { throw "A genuinely user-edited file was adopted instead of backed up" }
if ((Get-Content -Raw -LiteralPath $backup.FullName).Trim() -ne $userContent) { throw "Backup does not contain the user's edit" }
if ((Get-Content -Raw ".claude\rules\security-qa.md") -notmatch "OWASP") { throw "The current release's content was not installed" }

Write-Host "[OK] Test 18 passed successfully! A genuinely user-edited file was backed up and reported." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 19: The full no-manifest upgrade path leaves no spurious backups and
# then uninstalls to a clean tree
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 19: A full no-manifest upgrade leaves no spurious backups and uninstalls cleanly..." -ForegroundColor Yellow

$fullUpgradeProject = Join-Path $sandboxDir "full-upgrade-project"
New-Item -ItemType Directory -Path $fullUpgradeProject -Force | Out-Null
Set-Location -Path $fullUpgradeProject
git init -q -b main

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 19) failed with exit status $LASTEXITCODE" }

# Simulate a real pre-v2.3.3 install: several managed files still hold an older release's
# content, and there is no manifest at all.
foreach ($f in @('.claude/rules/security-qa.md', '.claude/rules/accessibility-qa.md', '.claude/commands/qa.md')) {
    $oldBytes = Get-ReleaseFixtureBytes -RelativePath $f
    $winPath = $f -replace '/', '\'
    [System.IO.File]::WriteAllBytes((Join-Path $fullUpgradeProject $winPath), $oldBytes)
}
Remove-Item -LiteralPath ".qa-skills-manifest" -Force

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Update
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Update (Test 19) failed with exit status $LASTEXITCODE" }

Write-Host "Verifying the upgrade left no spurious backups..." -ForegroundColor Cyan
$spurious = Get-ChildItem -Path ".claude" -Recurse -Filter '*.qa-skills-backup-*' -ErrorAction SilentlyContinue
if ($spurious) { throw "The no-manifest upgrade created spurious backups: $($spurious.FullName -join ', ')" }
if ((Get-Content -Raw ".claude\rules\security-qa.md") -notmatch "OWASP") { throw "security-qa.md was not updated to the current release" }

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall (Test 19) failed with exit status $LASTEXITCODE" }

Write-Host "Verifying uninstall left a clean tree..." -ForegroundColor Cyan
if (Test-Path ".claude") { throw ".claude survived uninstall after a no-manifest upgrade" }
if (Test-Path ".qa-skills-manifest") { throw "Manifest survived uninstall" }

Write-Host "[OK] Test 19 passed successfully! The no-manifest upgrade path left no spurious backups and uninstalled to a clean tree." -ForegroundColor Green

# Test 20 moved to conformance case 002 (plan 016 item 6).

# Test 21 moved to conformance case 008 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 22: `qa-instinct uninstall` removes only unmodified installed files,
# keeps untracked and user-modified files, and cleans up the manifest
# (plan 012, item 3)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 22: qa-instinct uninstall removes only unmodified installed files..." -ForegroundColor Yellow

$cliUninstallProject = Join-Path $sandboxDir "cli-uninstall-project"
New-Item -ItemType Directory -Path $cliUninstallProject -Force | Out-Null
Set-Location -Path $cliUninstallProject

node "$repoDir\cli\qa-instinct.js" init
if ($LASTEXITCODE -ne 0) { throw "cli/qa-instinct.js init (Test 22) failed with exit status $LASTEXITCODE" }
if (-not (Test-Path ".claude\commands\qa.md")) { throw "Test setup error: cli/qa-instinct.js init did not complete" }

Add-Content -Path ".claude\rules\security-qa.md" -Value "user edit"
Set-Content -Path ".claude\rules\my-own-notes.md" -Value "untracked" -Encoding utf8

node "$repoDir\cli\qa-instinct.js" uninstall
if ($LASTEXITCODE -ne 0) { throw "cli/qa-instinct.js uninstall (Test 22) failed with exit status $LASTEXITCODE" }

Write-Host "Verifying unmodified installed files were removed..." -ForegroundColor Cyan
if (Test-Path ".claude\commands\qa.md") { throw "uninstall left an unmodified installed file behind" }
if (Test-Path ".claude\rules\testing-guidelines.md") { throw "uninstall left an unmodified installed file behind" }

Write-Host "Verifying the user-modified file was kept..." -ForegroundColor Cyan
if ((Get-Content -Raw ".claude\rules\security-qa.md") -notmatch "user edit") { throw "uninstall discarded the user's edit" }

Write-Host "Verifying the untracked file was kept..." -ForegroundColor Cyan
if ((Get-Content -Raw ".claude\rules\my-own-notes.md").Trim() -ne "untracked") { throw "uninstall touched an untracked file" }

Write-Host "[OK] Test 22 passed successfully! qa-instinct uninstall removed only unmodified installed files." -ForegroundColor Green

# Test 23 moved to conformance case 003 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 24: The manifest cli/qa-instinct.js writes is interchangeable with install.ps1's
# - install with one implementation, uninstall with the other, both directions
# (plan 012, item 5 - cross-implementation round trip)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 24: A cross-implementation install/uninstall round trip works both ways..." -ForegroundColor Yellow

# --- 24a: install with cli/qa-instinct.js, uninstall with install.ps1 ---
$cliThenPs1Project = Join-Path $sandboxDir "cli-then-ps1-project"
New-Item -ItemType Directory -Path $cliThenPs1Project -Force | Out-Null
Set-Location -Path $cliThenPs1Project
git init -q -b main

node "$repoDir\cli\qa-instinct.js" init
if ($LASTEXITCODE -ne 0) { throw "cli/qa-instinct.js init (Test 24a) failed with exit status $LASTEXITCODE" }
if (-not (Test-Path ".claude\commands\qa.md")) { throw "Test setup error: cli/qa-instinct.js init did not complete" }

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall (Test 24a) failed with exit status $LASTEXITCODE" }

Write-Host "Verifying install.ps1 fully uninstalled a cli/qa-instinct.js install..." -ForegroundColor Cyan
if (Test-Path ".claude") { throw "install.ps1 left .claude behind after uninstalling a cli/qa-instinct.js install" }
if (Test-Path ".qa-skills-manifest") { throw "Manifest survived install.ps1's uninstall" }

# --- 24b: install with install.ps1, uninstall with cli/qa-instinct.js ---
$ps1ThenCliProject = Join-Path $sandboxDir "ps1-then-cli-project"
New-Item -ItemType Directory -Path $ps1ThenCliProject -Force | Out-Null
Set-Location -Path $ps1ThenCliProject
git init -q -b main

powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 24b) failed with exit status $LASTEXITCODE" }
if (-not (Test-Path ".claude\commands\qa.md")) { throw "Test setup error: install.ps1 did not complete" }

node "$repoDir\cli\qa-instinct.js" uninstall
if ($LASTEXITCODE -ne 0) { throw "cli/qa-instinct.js uninstall (Test 24b) failed with exit status $LASTEXITCODE" }

Write-Host "Verifying cli/qa-instinct.js fully uninstalled an install.ps1 install..." -ForegroundColor Cyan
if (Test-Path ".claude") { throw "cli/qa-instinct.js left .claude behind after uninstalling an install.ps1 install" }
if (Test-Path ".qa-skills-manifest") { throw "Manifest survived cli/qa-instinct.js's uninstall" }

Write-Host "[OK] Test 24 passed successfully! The manifest format round-trips between cli/qa-instinct.js and install.ps1 in both directions." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 25: cli/qa-instinct.js skips a read-only destination instead of crashing part-way
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 25: cli/qa-instinct.js init skips a read-only file and still completes..." -ForegroundColor Yellow

$cliRoProject = Join-Path $sandboxDir "cli-readonly"
New-Item -ItemType Directory -Path "$cliRoProject\.claude\rules" -Force | Out-Null
Set-Location -Path $cliRoProject
git init -q -b main
$cliRoContent = "PROTECTED BY READ-ONLY"
Set-Content -Path ".claude\rules\code-style-qa.md" -Value $cliRoContent -Encoding utf8
Set-ItemProperty -Path ".claude\rules\code-style-qa.md" -Name IsReadOnly -Value $true

node "$repoDir\cli\qa-instinct.js" init | Out-Null
if ($LASTEXITCODE -ne 0) { throw "cli/qa-instinct.js init aborted instead of skipping the read-only destination" }

Write-Host "Verifying the read-only file was left untouched and not backed up..." -ForegroundColor Cyan
if ((Get-Content -Raw ".claude\rules\code-style-qa.md").Trim() -ne $cliRoContent) { throw "cli/qa-instinct.js overwrote the read-only destination" }
if (Get-ChildItem -Path ".claude\rules" -Filter 'code-style-qa.md.qa-skills-backup-*') { throw "A skipped read-only file should leave no backup" }

Write-Host "Verifying the rest of the tree still installed completely..." -ForegroundColor Cyan
foreach ($sub in @('commands', 'rules', 'skills', 'agents', 'hooks')) {
    if (-not (Test-Path ".claude\$sub")) { throw ".claude\$sub is missing - the install stopped part-way" }
}
if (Select-String -Path ".qa-skills-manifest" -Pattern 'code-style-qa.md' -Quiet) { throw "A skipped file must not be recorded in the manifest" }

# Clear the read-only bit so the sandbox cleanup at the end can remove it.
Set-ItemProperty -Path ".claude\rules\code-style-qa.md" -Name IsReadOnly -Value $false

Set-Location -Path $repoDir
Write-Host "[OK] Test 25 passed successfully! cli/qa-instinct.js skipped the read-only file and completed the install." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 26: cli/qa-instinct.js `init --editor <name>` installs a non-claude editor's
# compiled adapter at install.ps1's own target path, byte-for-byte, recorded
# under that editor's own name in the manifest (plan 008)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 26: cli/qa-instinct.js init --editor cursor installs the right file at the right path..." -ForegroundColor Yellow

$cliEditorCursorProject = Join-Path $sandboxDir "cli-editor-cursor"
New-Item -ItemType Directory -Path $cliEditorCursorProject -Force | Out-Null
Set-Location -Path $cliEditorCursorProject

node "$repoDir\cli\qa-instinct.js" init --editor cursor
if ($LASTEXITCODE -ne 0) { throw "cli/qa-instinct.js init --editor cursor (Test 26) failed with exit status $LASTEXITCODE" }

Write-Host "Verifying the rules and skills were installed byte-for-byte at install.ps1's own target paths..." -ForegroundColor Cyan
$expectedCursorBytes = [System.IO.File]::ReadAllBytes("$repoDir\adapters\cursor\rules\qa-instinct.mdc")
# .NET file APIs resolve relative paths against the process working directory, which
# Set-Location does NOT change — pass an absolute path built from the sandbox project.
$actualCursorBytes = [System.IO.File]::ReadAllBytes((Join-Path $cliEditorCursorProject '.cursor\rules\qa-instinct.mdc'))
if (Compare-Object $expectedCursorBytes $actualCursorBytes -SyncWindow 0) { throw ".cursor/rules/qa-instinct.mdc does not match adapters/cursor/rules/qa-instinct.mdc byte-for-byte" }
$expectedSkillBytes = [System.IO.File]::ReadAllBytes("$repoDir\adapters\skills\qa-cases\SKILL.md")
$actualSkillBytes = [System.IO.File]::ReadAllBytes((Join-Path $cliEditorCursorProject '.cursor\skills\qa-cases\SKILL.md'))
if (Compare-Object $expectedSkillBytes $actualSkillBytes -SyncWindow 0) { throw ".cursor/skills/qa-cases/SKILL.md does not match adapters/skills/qa-cases/SKILL.md byte-for-byte" }

Write-Host "Verifying the manifest records them under 'cursor', not 'claude'..." -ForegroundColor Cyan
if ((Get-Content -Raw ".qa-skills-manifest") -notmatch [regex]::Escape("  cursor  .cursor/rules/qa-instinct.mdc")) { throw "Manifest did not record the cursor install under the 'cursor' editor" }
if ((Get-Content -Raw ".qa-skills-manifest") -notmatch [regex]::Escape("  cursor  .cursor/skills/qa/SKILL.md")) { throw "Manifest did not record the cursor skills under the 'cursor' editor" }

Write-Host "Verifying no claude tree was installed alongside it..." -ForegroundColor Cyan
if (Test-Path ".claude") { throw "--editor cursor unexpectedly installed the claude tree too" }

Write-Host "[OK] Test 26 passed successfully! cli/qa-instinct.js init --editor cursor installed the right file at the right path." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 27: A file colliding with a non-claude editor's target path is backed
# up, not destroyed, exactly like a claude-tree collision (plan 008)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 27: cli/qa-instinct.js init --editor copilot backs up a colliding file, not destroy it..." -ForegroundColor Yellow

$cliEditorCollisionProject = Join-Path $sandboxDir "cli-editor-collision"
New-Item -ItemType Directory -Path "$cliEditorCollisionProject\.github" -Force | Out-Null
Set-Location -Path $cliEditorCollisionProject

$cliEditorUserContent = "MY OWN COPILOT INSTRUCTIONS - IRREPLACEABLE"
Set-Content -Path ".github\copilot-instructions.md" -Value $cliEditorUserContent -Encoding utf8

node "$repoDir\cli\qa-instinct.js" init --editor copilot
if ($LASTEXITCODE -ne 0) { throw "cli/qa-instinct.js init --editor copilot (Test 27) failed with exit status $LASTEXITCODE" }

Write-Host "Verifying the package's file was installed..." -ForegroundColor Cyan
$expectedCopilotBytes = [System.IO.File]::ReadAllBytes("$repoDir\adapters\copilot\rules\copilot-instructions.md")
$actualCopilotBytes = [System.IO.File]::ReadAllBytes((Join-Path $cliEditorCollisionProject '.github\copilot-instructions.md'))
if (Compare-Object $expectedCopilotBytes $actualCopilotBytes -SyncWindow 0) { throw "The package's copilot-instructions.md was not installed" }

Write-Host "Verifying the user's original content is recoverable from a backup..." -ForegroundColor Cyan
$cliEditorBackup = Get-ChildItem -Path ".github" -Filter 'copilot-instructions.md.qa-skills-backup-*' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $cliEditorBackup) { throw "cli/qa-instinct.js init --editor copilot did not back up the colliding file" }
if ((Get-Content -Raw -LiteralPath $cliEditorBackup.FullName).Trim() -ne $cliEditorUserContent) { throw "Backup does not contain the user's original content" }

Write-Host "[OK] Test 27 passed successfully! cli/qa-instinct.js backed up the colliding non-claude file instead of destroying it." -ForegroundColor Green

# Test 28 moved to conformance case 010 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 29: `qa-instinct init` with no --editor and no TTY (CI, piped) behaves
# exactly like `--editor claude` - no prompt, no hang, no other editor
# installed (plan 008 backward-compatibility requirement)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 29: Non-TTY default behaves exactly like --editor claude..." -ForegroundColor Yellow

$cliNonTtyProject = Join-Path $sandboxDir "cli-nontty-default"
$cliExplicitClaudeProject = Join-Path $sandboxDir "cli-explicit-claude"
New-Item -ItemType Directory -Path $cliNonTtyProject -Force | Out-Null
New-Item -ItemType Directory -Path $cliExplicitClaudeProject -Force | Out-Null

Set-Location -Path $cliNonTtyProject
node "$repoDir\cli\qa-instinct.js" init | Out-Null
if ($LASTEXITCODE -ne 0) { throw "cli/qa-instinct.js init (Test 29, non-TTY default) failed with exit status $LASTEXITCODE" }
if (-not (Test-Path ".claude\commands")) { throw "Non-TTY default did not install the claude tree" }
foreach ($nonClaudeDest in @(".cursor", ".windsurfrules", ".windsurf", ".github", ".clinerules", ".cline", ".agents")) {
    if (Test-Path $nonClaudeDest) { throw "Non-TTY default with no --editor unexpectedly installed $nonClaudeDest" }
}

Set-Location -Path $cliExplicitClaudeProject
node "$repoDir\cli\qa-instinct.js" init --editor claude | Out-Null
if ($LASTEXITCODE -ne 0) { throw "cli/qa-instinct.js init --editor claude (Test 29) failed with exit status $LASTEXITCODE" }
if (-not (Test-Path ".claude\commands")) { throw "Test setup error: --editor claude did not install" }

Write-Host "Verifying both produced the same manifest content (modulo the recorded hash)..." -ForegroundColor Cyan
$stripHash = { param($path) (Get-Content -Path $path) -replace '^[0-9a-f]+', '' | Sort-Object }
$nonTtyManifest = & $stripHash (Join-Path $cliNonTtyProject ".qa-skills-manifest")
$explicitManifest = & $stripHash (Join-Path $cliExplicitClaudeProject ".qa-skills-manifest")
if (Compare-Object $nonTtyManifest $explicitManifest) { throw "Non-TTY default manifest differs from an explicit --editor claude install" }

Write-Host "[OK] Test 29 passed successfully! The non-TTY default behaves exactly like --editor claude." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 30: A tampered manifest cannot delete files outside the install tree
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 30: Uninstall refuses an absolute manifest path outside the base..." -ForegroundColor Yellow

$traversalProject = Join-Path $sandboxDir "traversal-project"
$traversalOutside = Join-Path $sandboxDir "traversal-outside"
New-Item -ItemType Directory -Path $traversalProject, $traversalOutside -Force | Out-Null
$victimFile = Join-Path $traversalOutside "victim.txt"
$victimContent = "A FILE OUTSIDE THE INSTALL TREE"
Set-Content -Path $victimFile -Value $victimContent -Encoding utf8

# The real hash, so the refusal is proven even when an attacker knows the target's content.
$victimHash = (Get-FileHash -LiteralPath $victimFile -Algorithm SHA256).Hash.ToLower()

Set-Location -Path $traversalProject
git init -q -b main
powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks | Out-Null
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 30) failed with exit status $LASTEXITCODE" }

# The relative escape is conformance case 005; the absolute path cannot be written as a case
# (the sandbox path is not known in advance), so it stays here.
foreach ($evilRel in @($victimFile)) {
    Set-Content -Path ".qa-skills-manifest" -Value "$victimHash  claude  $evilRel" -Encoding utf8
    $uninstallOutput = & powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall 2>&1

    if (-not (Test-Path -LiteralPath $victimFile)) { throw "Uninstall deleted a file outside the install tree via '$evilRel'" }
    if ((Get-Content -Raw -LiteralPath $victimFile).Trim() -ne $victimContent) { throw "The outside file's content changed via '$evilRel'" }
    # Out-String first: -match/-notmatch on an array filters rather than returning a boolean,
    # so `if ($array -notmatch ...)` is true whenever any single line fails to match.
    $uninstallText = $uninstallOutput | Out-String
    if ($uninstallText -notmatch 'Refusing') { throw "Uninstall did not report refusing '$evilRel'. Output was: $uninstallText" }
}

Set-Location -Path $repoDir
Write-Host "[OK] Test 30 passed successfully! A tampered manifest cannot reach outside the install tree." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 31: `qa-instinct update` refreshes an unmodified installed file to the
# current release (plan 013, item 1)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 31: An unmodified installed file is refreshed to the current version..." -ForegroundColor Yellow

$updateRefreshProject = Join-Path $sandboxDir "update-refresh-project"
New-Item -ItemType Directory -Path "$updateRefreshProject\.claude\rules" -Force | Out-Null
Set-Location -Path $updateRefreshProject

# Simulate a file installed back when the package still shipped an older release's content: the
# file itself, and the manifest hash recorded for it, both match that older release - i.e.
# unmodified since install, but stale relative to the current package.
$oldBytes31 = Get-ReleaseFixtureBytes -RelativePath '.claude/rules/security-qa.md'
[System.IO.File]::WriteAllBytes((Join-Path $updateRefreshProject '.claude\rules\security-qa.md'), $oldBytes31)
$oldHash31 = (Get-FileHash -Algorithm SHA256 -LiteralPath ".claude\rules\security-qa.md").Hash.ToLower()
Set-Content -Path ".qa-skills-manifest" -Value "$oldHash31  claude  .claude/rules/security-qa.md" -Encoding utf8
# The exact current-release hash, so refresh is proven precisely rather than by a substring
# that might already appear in the older release's content too.
$currentHash31 = (Get-FileHash -Algorithm SHA256 -LiteralPath "$repoDir\.claude\rules\security-qa.md").Hash.ToLower()

$updateOutput31 = & node "$repoDir\cli\qa-instinct.js" update 2>&1
if ($LASTEXITCODE -ne 0) { throw "qa-instinct update (Test 31) failed with exit status $LASTEXITCODE" }
$updateText31 = $updateOutput31 | Out-String

Write-Host "Verifying the stale-but-unmodified file was refreshed to the current release..." -ForegroundColor Cyan
$newHash31 = (Get-FileHash -Algorithm SHA256 -LiteralPath ".claude\rules\security-qa.md").Hash.ToLower()
if ($newHash31 -ne $currentHash31) { throw "update did not refresh a stale, unmodified file to the current release" }
$refreshBackups31 = Get-ChildItem -Path ".claude\rules" -Filter 'security-qa.md.qa-skills-backup-*' -ErrorAction SilentlyContinue
if ($refreshBackups31) { throw "An unmodified file was backed up instead of refreshed in place" }
if ((Get-Content -Raw ".qa-skills-manifest") -notmatch [regex]::Escape("$newHash31  claude  .claude/rules/security-qa.md")) { throw "The manifest was not updated to the refreshed file's new hash" }
if ($updateText31 -notmatch [regex]::Escape("Refreshed .claude/rules/security-qa.md")) { throw "update did not report the file as refreshed. Output was: $updateText31" }

Set-Location -Path $repoDir
Write-Host "[OK] Test 31 passed successfully! An unmodified installed file was refreshed to the current version." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 32: `qa-instinct update` backs up a user-modified file instead of
# silently overwriting it (plan 013, item 1)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 32: A user-modified file is backed up, not silently overwritten..." -ForegroundColor Yellow

$updateBackupProject = Join-Path $sandboxDir "update-backup-project"
New-Item -ItemType Directory -Path "$updateBackupProject\.claude\rules" -Force | Out-Null
Set-Location -Path $updateBackupProject

# The manifest records the hash of whatever was installed originally (an older release), not
# the user's later edit, so update sees a genuine change rather than "still unmodified".
$installBytes32 = Get-ReleaseFixtureBytes -RelativePath '.claude/rules/security-qa.md'
[System.IO.File]::WriteAllBytes((Join-Path $updateBackupProject '.claude\rules\security-qa.md'), $installBytes32)
$installHash32 = (Get-FileHash -Algorithm SHA256 -LiteralPath ".claude\rules\security-qa.md").Hash.ToLower()
Set-Content -Path ".qa-skills-manifest" -Value "$installHash32  claude  .claude/rules/security-qa.md" -Encoding utf8

$userContent32 = "MY OWN SECURITY POLICY - DO NOT TOUCH"
Set-Content -Path ".claude\rules\security-qa.md" -Value $userContent32 -Encoding utf8
$userHash32 = (Get-FileHash -Algorithm SHA256 -LiteralPath ".claude\rules\security-qa.md").Hash.ToLower()
$knownHashes32 = Get-Content -LiteralPath "$repoDir\.qa-skills-known-hashes" -Encoding UTF8
if ($knownHashes32 -match "^$userHash32\s") { throw "Test setup error: the user-edit content collides with a known release hash" }
$currentHash32 = (Get-FileHash -Algorithm SHA256 -LiteralPath "$repoDir\.claude\rules\security-qa.md").Hash.ToLower()

$updateOutput32 = & node "$repoDir\cli\qa-instinct.js" update 2>&1
if ($LASTEXITCODE -ne 0) { throw "qa-instinct update (Test 32) failed with exit status $LASTEXITCODE" }
$updateText32 = $updateOutput32 | Out-String

Write-Host "Verifying the user's edit was backed up, not silently discarded..." -ForegroundColor Cyan
$backup32 = Get-ChildItem -Path ".claude\rules" -Filter 'security-qa.md.qa-skills-backup-*' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $backup32) { throw "update did not back up a user-modified file" }
if ((Get-Content -Raw -LiteralPath $backup32.FullName).Trim() -ne $userContent32) { throw "Backup does not contain the user's edit" }
$afterHash32 = (Get-FileHash -Algorithm SHA256 -LiteralPath ".claude\rules\security-qa.md").Hash.ToLower()
if ($afterHash32 -ne $currentHash32) { throw "The current release's content was not installed over the user's edit" }
if ($updateText32 -notmatch 'backed up') { throw "update did not report backing up the modified file. Output was: $updateText32" }

Set-Location -Path $repoDir
Write-Host "[OK] Test 32 passed successfully! A user-modified file was backed up, not silently overwritten." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 33: `qa-instinct update` removes a no-longer-shipped file when
# unmodified, and keeps it when the user changed it (plan 013, item 2)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 33: A file the package no longer ships is removed when unmodified, kept when modified..." -ForegroundColor Yellow

$updateRemoveProject = Join-Path $sandboxDir "update-remove-project"
New-Item -ItemType Directory -Path "$updateRemoveProject\.claude\rules" -Force | Out-Null
Set-Location -Path $updateRemoveProject

# Case A: still exactly as installed - update must remove it.
Set-Content -Path ".claude\rules\deprecated-rule.md" -Value "an old rule this package no longer ships" -Encoding utf8
$depHash33 = (Get-FileHash -Algorithm SHA256 -LiteralPath ".claude\rules\deprecated-rule.md").Hash.ToLower()

# Case B: changed since install - update must leave it alone.
Set-Content -Path ".claude\rules\deprecated-rule-2.md" -Value "an old rule, later edited by the user" -Encoding utf8
$dep2InstallHash33 = (Get-FileHash -Algorithm SHA256 -LiteralPath ".claude\rules\deprecated-rule-2.md").Hash.ToLower()
Add-Content -Path ".claude\rules\deprecated-rule-2.md" -Value "the user's own addition" -Encoding utf8

Set-Content -Path ".qa-skills-manifest" -Value @(
    "$depHash33  claude  .claude/rules/deprecated-rule.md",
    "$dep2InstallHash33  claude  .claude/rules/deprecated-rule-2.md"
) -Encoding utf8

$updateOutput33 = & node "$repoDir\cli\qa-instinct.js" update 2>&1
if ($LASTEXITCODE -ne 0) { throw "qa-instinct update (Test 33) failed with exit status $LASTEXITCODE" }
$updateText33 = $updateOutput33 | Out-String

Write-Host "Verifying the unmodified no-longer-shipped file was removed..." -ForegroundColor Cyan
if (Test-Path ".claude\rules\deprecated-rule.md") { throw "update left an unmodified, no-longer-shipped file in place" }
if (Test-Path ".qa-skills-manifest") {
    if ((Get-Content -Raw ".qa-skills-manifest") -match [regex]::Escape("deprecated-rule.md")) { throw "The removed file's stale manifest entry survived" }
}
if ($updateText33 -notmatch [regex]::Escape("Removed .claude/rules/deprecated-rule.md")) { throw "update did not report removing the dropped file. Output was: $updateText33" }

Write-Host "Verifying the modified no-longer-shipped file was kept..." -ForegroundColor Cyan
if (-not (Test-Path ".claude\rules\deprecated-rule-2.md")) { throw "update deleted a no-longer-shipped file the user had changed" }
if ((Get-Content -Raw ".claude\rules\deprecated-rule-2.md") -notmatch "the user's own addition") { throw "The user's edit to a dropped file was lost" }
if ($updateText33 -notmatch [regex]::Escape("Kept .claude/rules/deprecated-rule-2.md")) { throw "update did not report keeping the modified dropped file. Output was: $updateText33" }

Set-Location -Path $repoDir
Write-Host "[OK] Test 33 passed successfully! A dropped file was removed when unmodified and kept when modified." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 34: `qa-instinct update` adopts a pre-manifest install, and never
# touches the user's own files at another shipped path (plan 013, item 3)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 34: A pre-manifest install is picked up and adopted, and the user's own files survive it..." -ForegroundColor Yellow

$updateAdoptProject = Join-Path $sandboxDir "update-adopt-project"
New-Item -ItemType Directory -Path "$updateAdoptProject\.claude\rules" -Force | Out-Null
Set-Location -Path $updateAdoptProject

# Simulate the state every pre-v2.3.3 install is in: a managed file still holding an older
# release's content, and no manifest recording it (manifests didn't exist yet).
$adoptBytes34 = Get-ReleaseFixtureBytes -RelativePath '.claude/rules/security-qa.md'
[System.IO.File]::WriteAllBytes((Join-Path $updateAdoptProject '.claude\rules\security-qa.md'), $adoptBytes34)
$adoptHash34 = (Get-FileHash -Algorithm SHA256 -LiteralPath ".claude\rules\security-qa.md").Hash.ToLower()
$knownHashes34 = Get-Content -LiteralPath "$repoDir\.qa-skills-known-hashes" -Encoding UTF8
if (-not ($knownHashes34 -match "^$adoptHash34\s")) { throw "Test setup error: v2.2.0's security-qa.md hash is not in the known-hash list" }

# The user's own file, sitting at another path this package also ships - update must leave it
# alone; its hash proves nothing, so it is never adopted on the strength of its path alone.
$userContent34 = "MY OWN NOTES - NOT PACKAGE CONTENT"
Set-Content -Path ".claude\rules\accessibility-qa.md" -Value $userContent34 -Encoding utf8

$currentHash34 = (Get-FileHash -Algorithm SHA256 -LiteralPath "$repoDir\.claude\rules\security-qa.md").Hash.ToLower()

$updateOutput34 = & node "$repoDir\cli\qa-instinct.js" update 2>&1
if ($LASTEXITCODE -ne 0) { throw "qa-instinct update (Test 34) failed with exit status $LASTEXITCODE" }
$updateText34 = $updateOutput34 | Out-String

Write-Host "Verifying the pre-manifest install was detected and adopted..." -ForegroundColor Cyan
$afterHash34 = (Get-FileHash -Algorithm SHA256 -LiteralPath ".claude\rules\security-qa.md").Hash.ToLower()
if ($afterHash34 -ne $currentHash34) { throw "update did not adopt a pre-manifest install matching a known release" }
$adoptBackups34 = Get-ChildItem -Path ".claude\rules" -Filter 'security-qa.md.qa-skills-backup-*' -ErrorAction SilentlyContinue
if ($adoptBackups34) { throw "A file matching a previous release was backed up instead of adopted" }
if ($updateText34 -notmatch [regex]::Escape("Adopted .claude/rules/security-qa.md")) { throw "update did not report adopting the pre-manifest file. Output was: $updateText34" }

Write-Host "Verifying the user's own file at another shipped path survived untouched..." -ForegroundColor Cyan
if ((Get-Content -Raw ".claude\rules\accessibility-qa.md").Trim() -ne $userContent34) { throw "update touched the user's own file at a shipped path" }

Set-Location -Path $repoDir
Write-Host "[OK] Test 34 passed successfully! A pre-manifest install was adopted and the user's own files survived." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 35: `qa-instinct update` installs nothing when nothing is installed
# (plan 013, item 4/5)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 35: Update with nothing installed does not install anything..." -ForegroundColor Yellow

$updateEmptyProject = Join-Path $sandboxDir "update-empty-project"
New-Item -ItemType Directory -Path $updateEmptyProject -Force | Out-Null
Set-Location -Path $updateEmptyProject

$updateOutput35 = & node "$repoDir\cli\qa-instinct.js" update 2>&1
if ($LASTEXITCODE -ne 0) { throw "qa-instinct update (Test 35) failed with exit status $LASTEXITCODE" }
$updateText35 = $updateOutput35 | Out-String

Write-Host "Verifying update did not install anything when nothing was there..." -ForegroundColor Cyan
if (Test-Path ".claude") { throw "update created .claude/ out of nothing" }
if (Test-Path ".qa-skills-manifest") { throw "update created a manifest out of nothing" }
if ($updateText35 -notmatch 'Nothing installed') { throw "update did not honestly report that nothing is installed. Output was: $updateText35" }

Set-Location -Path $repoDir
Write-Host "[OK] Test 35 passed successfully! Update with nothing installed did not install anything." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 36: A tampered manifest cannot make `qa-instinct update` delete files
# outside the install tree (regression for the fix alongside plan 013 item 2)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 36: Update refuses manifest paths that escape the base..." -ForegroundColor Yellow

$updateTraversalProject = Join-Path $sandboxDir "update-traversal-project"
$updateTraversalOutside = Join-Path $sandboxDir "update-traversal-outside"
New-Item -ItemType Directory -Path $updateTraversalProject, $updateTraversalOutside -Force | Out-Null
$victimFile36 = Join-Path $updateTraversalOutside "victim.txt"
$victimContent36 = "A FILE OUTSIDE THE INSTALL TREE"
Set-Content -Path $victimFile36 -Value $victimContent36 -Encoding utf8
$victimHash36 = (Get-FileHash -LiteralPath $victimFile36 -Algorithm SHA256).Hash.ToLower()

Set-Location -Path $updateTraversalProject
node "$repoDir\cli\qa-instinct.js" init | Out-Null
if ($LASTEXITCODE -ne 0) { throw "cli/qa-instinct.js init (Test 36) failed with exit status $LASTEXITCODE" }

# A manifest entry naming a file this package no longer ships, at a path that escapes the
# project tree, must never reach update's removal branch (fs.rmSync) without a refusal.
foreach ($evilRel in @("../update-traversal-outside/victim.txt", $victimFile36)) {
    Set-Content -Path ".qa-skills-manifest" -Value "$victimHash36  claude  $evilRel" -Encoding utf8
    $updateOutput36 = & node "$repoDir\cli\qa-instinct.js" update 2>&1
    $updateText36 = $updateOutput36 | Out-String

    if (-not (Test-Path -LiteralPath $victimFile36)) { throw "update deleted a file outside the install tree via '$evilRel'" }
    if ((Get-Content -Raw -LiteralPath $victimFile36).Trim() -ne $victimContent36) { throw "The outside file's content changed via '$evilRel'" }
    if ($updateText36 -notmatch 'Refusing') { throw "update did not report refusing '$evilRel'. Output was: $updateText36" }
}

Set-Location -Path $repoDir
Write-Host "[OK] Test 36 passed successfully! A tampered manifest cannot make update reach outside the install tree." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 37: Project installs of copilot and cline still work, and the cursor uninstall report
# uses the shared label. Their global installs (plan 058) are conformance cases 069-074; only the
# project-install half and the label stay here (plan 014 item A2).
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 37: Project install of copilot and cline still works, cursor uninstall label is shared..." -ForegroundColor Yellow

$project37 = Join-Path $sandboxDir "project-37"
New-Item -ItemType Directory -Path $project37 -Force | Out-Null
Set-Location -Path $project37
foreach ($ed in @('copilot', 'cline', 'cursor')) {
    powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor $ed -NonInteractive -NoHooks | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Target project -Editor $ed (Test 37) failed with exit status $LASTEXITCODE" }
}
if (-not (Test-Path '.github\copilot-instructions.md')) { throw "Project install of copilot no longer writes .github\copilot-instructions.md" }
if (-not (Test-Path '.cline\rules\qa-instinct.md')) { throw "Project install of cline no longer writes .cline\rules\qa-instinct.md" }

# The one uninstall message that said 'Cursor' where every other place says 'Cursor / Trae'.
$cursorOut37 = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor cursor -NonInteractive -Uninstall 2>&1 | Out-String
if ($cursorOut37 -notmatch 'Cursor / Trae - Project') { throw "The cursor uninstall report does not use the shared 'Cursor / Trae' label. Output was: $cursorOut37" }

Set-Location -Path $repoDir
Write-Host "[OK] Test 37 passed successfully! Project installs of copilot and cline still work and the cursor uninstall label is shared." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 38: A global uninstall removes the copilot/cline files older versions of
# install.ps1 left in the home directory, and says there is nothing to remove when there are none
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 38: Global uninstall cleans up what older versions left in the home directory..." -ForegroundColor Yellow

# Reproduce what install.ps1 up to 2.7.x left behind: the cline adapter at its project path of
# the time, inside the home directory, recorded in the home manifest. The text stands in for that
# adapter, which the package no longer generates (plan 047).
$debris38 = Join-Path $env:USERPROFILE '.clinerules'
[System.IO.File]::WriteAllText($debris38, "OLD CLINE ADAPTER`n")
$debrisHash38 = (Get-FileHash -LiteralPath $debris38 -Algorithm SHA256).Hash.ToLower()
$homeManifest38 = Join-Path $env:USERPROFILE '.qa-skills-manifest'
$utf8NoBom38 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::AppendAllText($homeManifest38, "$debrisHash38  cline  .clinerules`n", $utf8NoBom38)

$caller38 = Join-Path $sandboxDir "global-caller-38"
New-Item -ItemType Directory -Path $caller38 -Force | Out-Null
Set-Location -Path $caller38
$cleanupOut38 = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target global -Editor cline -NonInteractive -Uninstall 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall -Target global -Editor cline (Test 38) failed with exit status $LASTEXITCODE" }
if (Test-Path -LiteralPath $debris38) { throw "Global uninstall left the .clinerules an older install.ps1 wrote into the home directory" }
if ($cleanupOut38 -notmatch 'Uninstalled \(Cline - Global\)') { throw "Global uninstall did not report removing the old home-directory .clinerules. Output was: $cleanupOut38" }
if ((Test-Path $homeManifest38) -and ((Get-Content -Raw $homeManifest38) -match '  cline  ')) { throw "The cleaned-up .clinerules is still recorded in the home manifest" }

# With nothing there, a global uninstall of cline says there is nothing to remove, exactly as
# install.sh does. Until plan 058 cline had no global target and this stayed silent.
$silentOut38 = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target global -Editor cline -NonInteractive -Uninstall 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw "Second global uninstall of cline (Test 38) failed with exit status $LASTEXITCODE" }
if ($silentOut38 -notmatch 'Nothing to remove \(Cline - Global\)') { throw "A clean global uninstall of cline did not say there was nothing to remove, as install.sh does. Output was: $silentOut38" }

Set-Location -Path $repoDir
Write-Host "[OK] Test 38 passed successfully! Old home-directory debris is removed, and a clean uninstall says there is nothing to remove." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 39: The project pre-commit hook never replaces a hook it did not write, never
# registers where git will not look, and is removed on uninstall only when it is ours
# (plan 026 item 2)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 39: Project pre-commit hook is never overwritten and respects core.hooksPath..." -ForegroundColor Yellow

$hookMarker39 = 'Pre-commit hook to validate test cases in qa-skills'

# A repository without the global template hook an earlier test may have configured, so the
# only pre-commit hook present is the one this test seeds.
function New-HookRepo39 {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Recurse -Force }
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    git -C $Path -c "init.templateDir=" init -q -b main
    New-Item -ItemType Directory -Path (Join-Path $Path '.git\hooks') -Force | Out-Null
}

# 39a: the user's own hook survives install and uninstall byte for byte.
$repo39a = Join-Path $sandboxDir "hook-own"
New-HookRepo39 $repo39a
$ownHook39 = Join-Path $repo39a '.git\hooks\pre-commit'
[System.IO.File]::WriteAllText($ownHook39, "#!/bin/sh`necho mine`n", (New-Object System.Text.UTF8Encoding($false)))
$ownHash39 = (Get-FileHash -LiteralPath $ownHook39 -Algorithm SHA256).Hash
Set-Location -Path $repo39a
$out39a = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 39a) failed with exit status $LASTEXITCODE. Output was: $out39a" }
if ($out39a -notmatch 'Kept your existing pre-commit hook') { throw "install did not say it kept the user's pre-commit hook. Output was: $out39a" }
if ((Get-FileHash -LiteralPath $ownHook39 -Algorithm SHA256).Hash -ne $ownHash39) { throw "install changed the user's pre-commit hook" }
powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall | Out-Null
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall (Test 39a) failed with exit status $LASTEXITCODE" }
if (-not (Test-Path -LiteralPath $ownHook39)) { throw "uninstall removed the user's pre-commit hook" }
if ((Get-FileHash -LiteralPath $ownHook39 -Algorithm SHA256).Hash -ne $ownHash39) { throw "uninstall changed the user's pre-commit hook" }

# 39b: with core.hooksPath set git never runs .git\hooks, so nothing is written there.
$repo39b = Join-Path $sandboxDir "hook-hookspath"
New-HookRepo39 $repo39b
git -C $repo39b config core.hooksPath .husky/_
Set-Location -Path $repo39b
$out39b = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 39b) failed with exit status $LASTEXITCODE. Output was: $out39b" }
if ($out39b -notmatch 'core\.hooksPath is set') { throw "install did not report core.hooksPath. Output was: $out39b" }
if (Test-Path -LiteralPath (Join-Path $repo39b '.git\hooks\pre-commit')) { throw "install wrote .git\hooks\pre-commit although core.hooksPath is set" }

# 39c: with no hook present, install creates ours and uninstall removes it.
$repo39c = Join-Path $sandboxDir "hook-none"
New-HookRepo39 $repo39c
Set-Location -Path $repo39c
powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive | Out-Null
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 39c) failed with exit status $LASTEXITCODE" }
$hook39c = Join-Path $repo39c '.git\hooks\pre-commit'
if (-not (Test-Path -LiteralPath $hook39c)) { throw "install did not create the pre-commit hook in a repository without one" }
if (-not (Get-Content -LiteralPath $hook39c -Raw).Contains($hookMarker39)) { throw "the created pre-commit hook lacks our marker" }
powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall | Out-Null
if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall (Test 39c) failed with exit status $LASTEXITCODE" }
if (Test-Path -LiteralPath $hook39c) { throw "uninstall left our pre-commit hook behind" }

# 39d: a linked worktree has a .git file, not a directory; the hook goes where git looks.
$wt39 = Join-Path $sandboxDir "hook-worktree"
if (Test-Path -LiteralPath $wt39) { Remove-Item -LiteralPath $wt39 -Recurse -Force }
git -C $repo39c -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
git -C $repo39c worktree add -q -b wt-39 $wt39
Set-Location -Path $wt39
powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive | Out-Null
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 39d) failed with exit status $LASTEXITCODE" }
if (-not (Test-Path -LiteralPath $hook39c)) { throw "install did not register the hook for a worktree checkout" }

Set-Location -Path $repoDir
Write-Host "[OK] Test 39 passed successfully! The user's own hook and core.hooksPath were respected, and our hook was created and removed." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 40: The global pre-commit hook adds and removes only its own block, never rewrites a hook
# it cannot append to, and never replaces a git init.templateDir the user already has
# (plan 026 item 3)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 40: Global hook append and removal touch only our own block..." -ForegroundColor Yellow

# Runs install.ps1 against its own throwaway home so no earlier test's global state leaks in.
function Invoke-GlobalInstall40 {
    param([string]$HomeDir, [bool]$Uninstall)
    $savedProfile = $env:USERPROFILE; $savedHome = $env:HOME; $savedGit = $env:GIT_CONFIG_GLOBAL
    $env:USERPROFILE = $HomeDir; $env:HOME = $HomeDir; $env:GIT_CONFIG_GLOBAL = (Join-Path $HomeDir '.gitconfig')
    try {
        if ($Uninstall) {
            $out = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target global -Editor claude -NonInteractive -Uninstall 2>&1 | Out-String
        }
        else {
            $out = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target global -Editor claude -NonInteractive 2>&1 | Out-String
        }
        if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 40, uninstall=$Uninstall) failed with exit status $LASTEXITCODE. Output was: $out" }
        return $out
    }
    finally {
        $env:USERPROFILE = $savedProfile; $env:HOME = $savedHome; $env:GIT_CONFIG_GLOBAL = $savedGit
    }
}

$utf8NoBom40 = New-Object System.Text.UTF8Encoding($false)
$caller40 = Join-Path $sandboxDir "global-caller-40"
New-Item -ItemType Directory -Path $caller40 -Force | Out-Null
Set-Location -Path $caller40

# 40a: appended to the user's bash hook as LF, and removed again leaving exactly the user's lines.
$home40a = Join-Path $sandboxDir "home-40a"
New-Item -ItemType Directory -Path (Join-Path $home40a '.git-templates\hooks') -Force | Out-Null
$hook40a = Join-Path $home40a '.git-templates\hooks\pre-commit'
[System.IO.File]::WriteAllText($hook40a, "#!/usr/bin/env bash`necho before`n", $utf8NoBom40)
$env:GIT_CONFIG_GLOBAL = (Join-Path $home40a '.gitconfig')
git config --global init.templateDir "$home40a/their-templates"
$env:GIT_CONFIG_GLOBAL = $null
Invoke-GlobalInstall40 $home40a $false | Out-Null
$appended40a = [System.IO.File]::ReadAllText($hook40a)
if (-not $appended40a.Contains('# >>> bem-te-vi global pre-commit >>>')) { throw "global install did not append its block to the user's hook" }
if ($appended40a.Contains("`r")) { throw "the appended global hook contains a CR; bash would reject it" }
$env:GIT_CONFIG_GLOBAL = (Join-Path $home40a '.gitconfig')
$templateDir40a = (git config --global init.templateDir)
$env:GIT_CONFIG_GLOBAL = $null
if ($templateDir40a -ne "$home40a/their-templates") { throw "global install replaced the user's init.templateDir (now '$templateDir40a')" }
[System.IO.File]::AppendAllText($hook40a, "echo after`n", $utf8NoBom40)
Invoke-GlobalInstall40 $home40a $true | Out-Null
$left40a = [System.IO.File]::ReadAllText($hook40a)
if ($left40a -cne "#!/usr/bin/env bash`necho before`necho after`n") { throw "global uninstall did not leave exactly the user's lines. Hook was: $left40a" }

# 40b: a hook an older release appended to has no end marker; only its block may go.
$home40b = Join-Path $sandboxDir "home-40b"
New-Item -ItemType Directory -Path (Join-Path $home40b '.git-templates\hooks') -Force | Out-Null
$hook40b = Join-Path $home40b '.git-templates\hooks\pre-commit'
$oldBlock40b = @'

# Added by qa-skills global installer
GLOBAL_VALIDATOR="$HOME/.claude/hooks/validate-tc-format.sh"
if [ -f "$GLOBAL_VALIDATOR" ]; then
    STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.md$' || true)
    if [ -n "$STAGED_FILES" ]; then
        for FILE in $STAGED_FILES; do
            if ! "$GLOBAL_VALIDATOR" "$FILE"; then
                exit 1
            fi
        done
    fi
fi
'@
$oldBlock40b = $oldBlock40b -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($hook40b, ("#!/bin/sh`necho before`n" + $oldBlock40b + "`necho after`n"), $utf8NoBom40)
Invoke-GlobalInstall40 $home40b $true | Out-Null
$left40b = [System.IO.File]::ReadAllText($hook40b)
if ($left40b -cne "#!/bin/sh`necho before`necho after`n") { throw "uninstalling an older appended block did not leave exactly the user's lines. Hook was: $left40b" }

# 40c: a hook that is not a sh or bash script is left alone.
$home40c = Join-Path $sandboxDir "home-40c"
New-Item -ItemType Directory -Path (Join-Path $home40c '.git-templates\hooks') -Force | Out-Null
$hook40c = Join-Path $home40c '.git-templates\hooks\pre-commit'
$python40c = "#!/usr/bin/env python3`nprint('mine')`n"
[System.IO.File]::WriteAllText($hook40c, $python40c, $utf8NoBom40)
$out40c = Invoke-GlobalInstall40 $home40c $false
if ([System.IO.File]::ReadAllText($hook40c) -cne $python40c) { throw "global install modified a hook that is not a sh or bash script" }
if ($out40c -notmatch 'Kept your existing global pre-commit hook') { throw "global install did not say it kept the user's hook. Output was: $out40c" }

# 40d: with no hook present, install creates ours and uninstall removes the file.
$home40d = Join-Path $sandboxDir "home-40d"
New-Item -ItemType Directory -Path $home40d -Force | Out-Null
$hook40d = Join-Path $home40d '.git-templates\hooks\pre-commit'
Invoke-GlobalInstall40 $home40d $false | Out-Null
if (-not (Test-Path -LiteralPath $hook40d)) { throw "global install did not create the hook" }
if ([System.IO.File]::ReadAllText($hook40d).Contains("`r")) { throw "the created global hook contains a CR; bash would reject it" }
Invoke-GlobalInstall40 $home40d $true | Out-Null
if (Test-Path -LiteralPath $hook40d) { throw "global uninstall left our hook behind" }

Set-Location -Path $repoDir
Write-Host "[OK] Test 40 passed successfully! The global hook block was appended and removed without touching the user's lines or init.templateDir." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 41: The installed hooks validate every staged test-case file, whatever its name, and
# a failed validation still aborts the commit (plan 026 item 4)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 41: Hooks validate staged files with spaces, non-ASCII names and renames..." -ForegroundColor Yellow

$fix41 = Join-Path $repoDir 'tests\fixtures\tc-format'

# Commits and reports whether git accepted it. The hook runs under Git for Windows' bash.
function Test-Commit41 {
    param([string]$Repo, [string]$Message)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & git -C $Repo -c user.name=t -c user.email=t@t commit -q -m $Message *> $null
        return ($LASTEXITCODE -eq 0)
    }
    finally { $ErrorActionPreference = $previous }
}

$repo41 = Join-Path $sandboxDir "hook-names"
if (Test-Path -LiteralPath $repo41) { Remove-Item -LiteralPath $repo41 -Recurse -Force }
New-Item -ItemType Directory -Path $repo41 -Force | Out-Null
git -C $repo41 -c "init.templateDir=" init -q -b main
New-Item -ItemType Directory -Path (Join-Path $repo41 '.git\hooks') -Force | Out-Null
Set-Location -Path $repo41
powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive | Out-Null
if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 41) failed with exit status $LASTEXITCODE" }

$cedilla41 = "TC-A$([char]0x00C7)$([char]0x00C3)O.md"
foreach ($rel in @("docs\My Tests\TC-AUTH.md", "docs\casos\$cedilla41")) {
    $full = Join-Path $repo41 $rel
    New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $fix41 'missing-field.md') -Destination $full -Force
    git -C $repo41 add -- $rel
    if (Test-Commit41 $repo41 'invalid') { throw "an invalid staged test-case file was committed: $rel" }
    git -C $repo41 reset -q
    Copy-Item -LiteralPath (Join-Path $fix41 'complete.md') -Destination $full -Force
    git -C $repo41 add -- $rel
    if (-not (Test-Commit41 $repo41 'valid')) { throw "a valid test-case file was refused: $rel" }
}

Copy-Item -LiteralPath (Join-Path $fix41 'complete.md') -Destination (Join-Path $repo41 'docs\old name.md')
git -C $repo41 add -- 'docs/old name.md'
if (-not (Test-Commit41 $repo41 'add old')) { throw "a valid test-case file was refused" }
git -C $repo41 mv 'docs/old name.md' 'docs/new name.md'
Copy-Item -LiteralPath (Join-Path $fix41 'missing-field.md') -Destination (Join-Path $repo41 'docs\new name.md') -Force
git -C $repo41 add -- 'docs/new name.md'
if (Test-Commit41 $repo41 'renamed') { throw "an invalid renamed test-case file was committed" }

Set-Location -Path $repoDir
Write-Host "[OK] Test 41 passed successfully! Names with spaces, non-ASCII characters and renames are validated, and a failure still aborts the commit." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 42c: install.ps1's three menus, driven with answers piped to powershell.exe -File and no
# parameter for the menu under test (plan 037 step 4; Test 39c in test-lifecycle.sh). Read-Host
# reads piped stdin, so no stub is needed. install.ps1 re-prompts on an invalid answer for all
# three menus, and install.sh now does the same (Test 39c); each invalid case sends the bad value
# and then a valid one, and checks the error was shown.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 42c: install.ps1 menus map every answer to the right operation, scope and editor..." -ForegroundColor Yellow

$menuRoot42c = Join-Path $sandboxDir 'menus-42c'
$menuCount42c = 0
# install.ps1 asks "Continue anyway?" first when no `claude` command is on PATH, which would take
# the first menu answer on a machine without Claude Code (CI). A stub keeps every machine alike.
$menuBin42c = Join-Path $menuRoot42c 'bin'
New-Item -ItemType Directory -Path $menuBin42c -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $menuBin42c 'claude.cmd'), "@exit /b 0`r`n")
$editorFiles42c = [ordered]@{
    claude      = '.claude\commands\qa.md'
    cursor      = '.cursor\rules\qa-instinct.mdc'
    windsurf    = '.windsurf\rules\qa-instinct.md'
    copilot     = '.github\copilot-instructions.md'
    cline       = '.cline\rules\qa-instinct.md'
    antigravity = '.agents\rules\qa-instinct.md'
}

# Runs install.ps1 in a fresh project and home with the answers piped in; returns the output.
function Invoke-Menu42c {
    param([string[]]$Answers, [bool]$PreInstalled, [string[]]$InstallerArguments)
    $script:menuCount42c++
    $script:menuProject42c = Join-Path $menuRoot42c "$script:menuCount42c\project"
    $script:menuHome42c = Join-Path $menuRoot42c "$script:menuCount42c\home"
    New-Item -ItemType Directory -Path $script:menuProject42c, $script:menuHome42c -Force | Out-Null
    $savedProfile = $env:USERPROFILE; $savedHome = $env:HOME; $savedPath = $env:PATH
    $env:USERPROFILE = $script:menuHome42c; $env:HOME = $script:menuHome42c
    $env:PATH = "$menuBin42c;$env:PATH"
    Push-Location -Path $script:menuProject42c
    try {
        if ($PreInstalled) {
            powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -NoHooks 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "Test 42c: the pre-install failed with exit status $LASTEXITCODE" }
        }
        $out = ($Answers + @('n', 'n', 'n')) | powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -NoHooks @InstallerArguments 2>&1 | Out-String
        $script:menuExit42c = $LASTEXITCODE
    }
    finally {
        Pop-Location
        $env:USERPROFILE = $savedProfile; $env:HOME = $savedHome; $env:PATH = $savedPath
    }
    return $out
}
function Assert-Menu42c {
    param([string]$Where, [bool]$Present, [string]$Relative, [string]$Output, [string]$Case)
    $base = if ($Where -eq 'home') { $script:menuHome42c } else { $script:menuProject42c }
    $exists = Test-Path -LiteralPath (Join-Path $base $Relative)
    if ($Present -and -not $exists) { throw "Test 42c ($Case): $Relative is missing under the $Where directory. Output was: $Output" }
    if (-not $Present -and $exists) { throw "Test 42c ($Case): $Relative should not exist under the $Where directory. Output was: $Output" }
}
function Get-ManifestEditors42c {
    $manifest = Join-Path $script:menuProject42c '.qa-skills-manifest'
    if (-not (Test-Path -LiteralPath $manifest)) { return '' }
    $names = foreach ($line in [System.IO.File]::ReadAllLines($manifest)) {
        if ($line -match '^[0-9a-fA-F]{64}  (\S+)  ') { $Matches[1] }
    }
    return (($names | Sort-Object -Unique -CaseSensitive) -join ' ')
}
$claudeFile42c = $editorFiles42c['claude']
$projectFlags42c = @('-Target', 'project', '-Editor', 'claude')

# Operation menu: 1 install, empty = install, 2 update, 3 uninstall, invalid then 1 = re-prompt.
$out = Invoke-Menu42c @('1') $false $projectFlags42c
if ($script:menuExit42c -ne 0) { throw "Test 42c: operation 1 failed ($script:menuExit42c). Output was: $out" }
Assert-Menu42c 'project' $true $claudeFile42c $out 'operation 1'
$out = Invoke-Menu42c @('') $false $projectFlags42c
if ($script:menuExit42c -ne 0) { throw "Test 42c: an empty operation failed ($script:menuExit42c). Output was: $out" }
Assert-Menu42c 'project' $true $claudeFile42c $out 'operation empty'
$out = Invoke-Menu42c @('2') $true $projectFlags42c
if ($script:menuExit42c -ne 0) { throw "Test 42c: operation 2 failed ($script:menuExit42c). Output was: $out" }
if ($out -notmatch 'Everything is up to date') { throw "Test 42c: operation 2 did not run an update. Output was: $out" }
Assert-Menu42c 'project' $true $claudeFile42c $out 'operation 2'
$out = Invoke-Menu42c @('3') $true $projectFlags42c
if ($script:menuExit42c -ne 0) { throw "Test 42c: operation 3 failed ($script:menuExit42c). Output was: $out" }
Assert-Menu42c 'project' $false $claudeFile42c $out 'operation 3'
$out = Invoke-Menu42c @('9', '1') $false $projectFlags42c
if ($script:menuExit42c -ne 0) { throw "Test 42c: an invalid operation failed ($script:menuExit42c). Output was: $out" }
if ($out -notmatch "Invalid choice '9'") { throw "Test 42c: an invalid operation was not reported. Output was: $out" }
Assert-Menu42c 'project' $true $claudeFile42c $out 'operation 9 then 1'

# Target menu (the first answer is the operation): 1 project, 2 global, 3 both, empty = project,
# invalid then 1 = re-prompt.
$targetCases42c = @(
    @{ Answer = '1'; Project = $true;  Home = $false },
    @{ Answer = '2'; Project = $false; Home = $true },
    @{ Answer = '3'; Project = $true;  Home = $true },
    @{ Answer = '';  Project = $true;  Home = $false }
)
foreach ($case in $targetCases42c) {
    $out = Invoke-Menu42c @('1', $case.Answer) $false @('-Editor', 'claude')
    if ($script:menuExit42c -ne 0) { throw "Test 42c: target answer '$($case.Answer)' failed ($script:menuExit42c). Output was: $out" }
    Assert-Menu42c 'project' $case.Project $claudeFile42c $out "target '$($case.Answer)'"
    Assert-Menu42c 'home' $case.Home $claudeFile42c $out "target '$($case.Answer)'"
}
$out = Invoke-Menu42c @('1', '7', '1') $false @('-Editor', 'claude')
if ($script:menuExit42c -ne 0) { throw "Test 42c: an invalid target failed ($script:menuExit42c). Output was: $out" }
if ($out -notmatch "Invalid choice '7'") { throw "Test 42c: an invalid target was not reported. Output was: $out" }
Assert-Menu42c 'project' $true $claudeFile42c $out 'target 7 then 1'
Assert-Menu42c 'home' $false $claudeFile42c $out 'target 7 then 1'

# Editor menu (the first answer is the operation): 1-6 one editor each, 7 all, empty = Claude Code,
# invalid then 1 = re-prompt.
$editorNames42c = @($editorFiles42c.Keys)
$editorAnswers42c = @(
    @('1'), @('2'), @('3'), @('4'), @('5'), @('6'), @('7'), @(''), @('9', '1')
)
foreach ($answers in $editorAnswers42c) {
    $label = $answers -join ' then '
    $out = Invoke-Menu42c (@('1') + $answers) $false @('-Target', 'project')
    if ($script:menuExit42c -ne 0) { throw "Test 42c: editor answer '$label' failed ($script:menuExit42c). Output was: $out" }
    $last = $answers[-1]
    $want = if ($last -eq '' -or $last -eq '1') { @('claude') }
            elseif ($last -eq '7') { $editorNames42c }
            else { @($editorNames42c[[int]$last - 1]) }
    foreach ($name in $editorNames42c) {
        Assert-Menu42c 'project' ($want -contains $name) $editorFiles42c[$name] $out "editor '$label'"
    }
    $expected = (($want | Sort-Object -Unique -CaseSensitive) -join ' ')
    $actual = Get-ManifestEditors42c
    if ($actual -ne $expected) { throw "Test 42c: editor answer '$label': manifest records '$actual', expected '$expected'. Output was: $out" }
    if ($answers.Count -eq 2 -and $out -notmatch "Invalid choice '9'") { throw "Test 42c: an invalid editor was not reported. Output was: $out" }
}
Write-Host "[OK] Test 42c passed successfully! $menuCount42c menu runs matched their operation, scope and editor." -ForegroundColor Green
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 42: After `qa-instinct link`, install.ps1 install and uninstall must not write or delete
# through the linked folders: they are the npm package's own files (plan 033 item 1; Test 44 in
# test-lifecycle.sh)
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 42: install.ps1 never writes or deletes through folders qa-instinct link created..." -ForegroundColor Yellow

$subs42 = @('agents', 'commands', 'rules', 'skills', 'hooks')
$pkg42 = Join-Path $sandboxDir 'linked-pkg-42'
$proj42 = Join-Path $sandboxDir 'linked-project-42'
New-Item -ItemType Directory -Path (Join-Path $pkg42 '.claude'), $proj42 -Force | Out-Null
foreach ($item in @('cli', 'package.json', '.qa-skills-known-hashes', '.qa-skills-editor-map')) {
    Copy-Item -LiteralPath (Join-Path $repoDir $item) -Destination $pkg42 -Recurse -Force
}
foreach ($sub in $subs42) {
    Copy-Item -LiteralPath (Join-Path $repoDir ".claude\$sub") -Destination (Join-Path $pkg42 '.claude') -Recurse -Force
}
function Get-PackageHashes42 {
    $root = Join-Path $pkg42 '.claude'
    @(Get-ChildItem -LiteralPath $root -Recurse -File | Sort-Object FullName | ForEach-Object {
        "$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)  $($_.FullName.Substring($root.Length))"
    })
}
$before42 = Get-PackageHashes42

Set-Location -Path $proj42
git init -q -b main
# `qa-instinct link` needs symlink rights; without them, create the same links by hand, and
# without those either, report the test as not run rather than pass it.
$previous42 = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
node (Join-Path $pkg42 'cli\qa-instinct.js') link *> $null
$ErrorActionPreference = $previous42
$linked42 = $true
foreach ($sub in $subs42) {
    $dest = Join-Path $proj42 ".claude\$sub"
    $item = Get-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType) { continue }
    try {
        New-Item -ItemType Directory -Path (Join-Path $proj42 '.claude') -Force | Out-Null
        New-Item -ItemType SymbolicLink -Path $dest -Target (Join-Path $pkg42 ".claude\$sub") -ErrorAction Stop | Out-Null
    }
    catch { $linked42 = $false; break }
}

if (-not $linked42) {
    Write-Host "[SKIP] Test 42 not run: creating a symlink needs Developer Mode or an elevated shell." -ForegroundColor Yellow
}
else {
    $out42 = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "install.ps1 (Test 42) failed with exit status $LASTEXITCODE. Output was: $out42" }
    $out42 += powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "install.ps1 -Uninstall (Test 42) failed with exit status $LASTEXITCODE. Output was: $out42" }
    $after42 = Get-PackageHashes42
    if (($before42.Count -eq 0) -or (($before42 -join "`n") -ne ($after42 -join "`n"))) {
        throw "install.ps1 changed the linked package: $($before42.Count) files before, $($after42.Count) after. Output was: $out42"
    }
    if ($out42 -notmatch 'symbolic link') { throw "install.ps1 did not say it skipped a linked folder. Output was: $out42" }
    if ($out42 -notmatch "qa-instinct unlink") { throw "install.ps1 did not suggest 'qa-instinct unlink' for a qa-instinct link. Output was: $out42" }
    foreach ($sub in $subs42) {
        $item = Get-Item -LiteralPath (Join-Path $proj42 ".claude\$sub") -Force -ErrorAction SilentlyContinue
        if (-not ($item -and $item.LinkType)) { throw ".claude\$sub is no longer the link qa-instinct link created" }
    }
    Write-Host "[OK] Test 42 passed successfully! install.ps1 left the linked package's $($before42.Count) files untouched." -ForegroundColor Green
}
# Remove the links themselves before the sandbox is deleted: Remove-Item -Recurse on Windows
# PowerShell 5.1 follows a directory link.
foreach ($sub in $subs42) {
    $dest = Join-Path $proj42 ".claude\$sub"
    $item = Get-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType) { [System.IO.Directory]::Delete($dest, $false) }
}
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 42b: `qa-instinct link` and `unlink` on Windows: the project round trip (Test 39 in
# test-lifecycle.sh), then --global, a stale link and a real directory in the way (plan 037 step 2).
# `link` makes a symlink where it may (Developer Mode or an elevated shell) and a directory
# junction otherwise, which needs no privilege on NTFS (plan 046 item 4). Either way it must get
# the same result as Linux, and nothing may be written or deleted through a junction: a failure
# there is a product defect, not a test problem. Only where a junction cannot be made either (a
# drive that is not NTFS) does the test check the other side: `link` refuses with a clear message
# and changes nothing (Tests 39b-4 and 62 in test-lifecycle.sh).
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 42b: link and unlink at project and global scope, over a stale link and a real directory..." -ForegroundColor Yellow

$subs42b = @('agents', 'commands', 'rules', 'skills', 'hooks')
function New-Package42b {
    param([string]$Path)
    New-Item -ItemType Directory -Path (Join-Path $Path '.claude') -Force | Out-Null
    foreach ($item in @('cli', 'package.json', '.qa-skills-known-hashes', '.qa-skills-editor-map')) {
        Copy-Item -LiteralPath (Join-Path $repoDir $item) -Destination $Path -Recurse -Force
    }
    foreach ($sub in $subs42b) {
        Copy-Item -LiteralPath (Join-Path $repoDir ".claude\$sub") -Destination (Join-Path $Path '.claude') -Recurse -Force
    }
}
function Invoke-Cli42b {
    param([string]$Package, [string[]]$CliArguments)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $out = & node (Join-Path $Package 'cli\qa-instinct.js') @CliArguments 2>&1 | Out-String
    $script:cliExit42b = $LASTEXITCODE
    $ErrorActionPreference = $previous
    return $out
}
# The path's own attributes, so a link whose target was removed (a stale junction) still counts.
function Test-Link42b {
    param([string]$Path)
    try { $attributes = [System.IO.File]::GetAttributes($Path) }
    catch { return $false }
    return [bool]($attributes -band [System.IO.FileAttributes]::ReparsePoint)
}
function Remove-Links42b {
    param([string]$ClaudeDir)
    foreach ($sub in $subs42b) {
        $dest = Join-Path $ClaudeDir $sub
        if (Test-Link42b $dest) { [System.IO.Directory]::Delete($dest, $false) }
    }
}
function Get-FileCount42b {
    param([string]$Path)
    return @(Get-ChildItem -LiteralPath $Path -Recurse -File).Count
}

# Can this machine create a directory symlink at all?
$probeTarget42b = Join-Path $sandboxDir 'probe-target-42b'
$probeLink42b = Join-Path $sandboxDir 'probe-link-42b'
New-Item -ItemType Directory -Path $probeTarget42b -Force | Out-Null
$canLink42b = $true
try { New-Item -ItemType SymbolicLink -Path $probeLink42b -Target $probeTarget42b -ErrorAction Stop | Out-Null }
catch { $canLink42b = $false }
if (Test-Link42b $probeLink42b) { [System.IO.Directory]::Delete($probeLink42b, $false) }

# Without that right, can Node create one? (Developer Mode lets Node, but not Windows PowerShell
# 5.1's New-Item, create a symlink unelevated.)
$nodeCanLink42b = $false
if (-not $canLink42b) {
    $previous42bProbe = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    node -e "require('fs').symlinkSync(process.argv[1], process.argv[2], 'dir')" $probeTarget42b $probeLink42b *> $null
    $ErrorActionPreference = $previous42bProbe
    $nodeCanLink42b = Test-Link42b $probeLink42b
    if ($nodeCanLink42b) { [System.IO.Directory]::Delete($probeLink42b, $false) }
}

# Without that right, `link` makes junctions, and the test makes its own links (a foreign link) as
# junctions too, which Windows PowerShell 5.1 creates unprivileged.
$canJunction42b = $canLink42b
if (-not $canLink42b) {
    $canJunction42b = $true
    try { New-Item -ItemType Junction -Path $probeLink42b -Target $probeTarget42b -ErrorAction Stop | Out-Null }
    catch { $canJunction42b = $false }
    if (Test-Link42b $probeLink42b) { [System.IO.Directory]::Delete($probeLink42b, $false) }
}
$junction42b = -not ($canLink42b -or $nodeCanLink42b)
$handLinkType42b = if ($canLink42b) { 'SymbolicLink' } else { 'Junction' }

if ((-not $canJunction42b) -and $nodeCanLink42b) {
    Write-Host "[SKIP] Test 42b not run: Node can create a symlink here but Windows PowerShell can create neither a symlink nor a junction, and the test needs both." -ForegroundColor Yellow
}
elseif (-not $canJunction42b) {
    # Neither a symlink nor a junction (a drive that is not NTFS): `link` must stop with one clear
    # line, exit non-zero and leave the tree as it was, never a stack trace or a half-made .claude
    # folder (plan 037, decided 2026-10-18). The linking cases below are not run here.
    $pkg42b = Join-Path $sandboxDir 'link-pkg-42b'
    New-Package42b $pkg42b
    function Assert-LinkRefused42b {
        param([string]$Output, [string]$Case)
        if ($script:cliExit42b -eq 0) { throw "Test 42b ($Case): link exited 0 although no symlink could be created. Output was: $Output" }
        if ($Output -match 'symlinkSync|node:internal') { throw "Test 42b ($Case): link printed a stack trace instead of a message. Output was: $Output" }
        if ($Output -notmatch 'cannot create symbolic links') { throw "Test 42b ($Case): link did not say why it stopped. Output was: $Output" }
        if ($Output -notmatch 'Developer Mode') { throw "Test 42b ($Case): link did not name Developer Mode. Output was: $Output" }
        if ($Output -notmatch 'qa-instinct init') { throw "Test 42b ($Case): link did not name 'qa-instinct init' as the alternative. Output was: $Output" }
    }

    # A project with nothing in it stays empty.
    $projRefused42b = Join-Path $sandboxDir 'link-project-42b-refused'
    New-Item -ItemType Directory -Path $projRefused42b -Force | Out-Null
    Set-Location -Path $projRefused42b
    $out = Invoke-Cli42b $pkg42b @('link')
    Assert-LinkRefused42b $out 'project'
    $left42b = @(Get-ChildItem -LiteralPath $projRefused42b -Force)
    if ($left42b.Count -ne 0) { throw "Test 42b: link left $($left42b.Name -join ', ') in the project after it could not link. Output was: $out" }

    # A home whose .claude already holds a file of the user's keeps exactly that.
    $homeRefused42b = Join-Path $sandboxDir 'link-home-42b-refused'
    New-Item -ItemType Directory -Path (Join-Path $homeRefused42b '.claude') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $homeRefused42b '.claude\settings.json'), "{}`n")
    $savedProfile42b = $env:USERPROFILE
    $env:USERPROFILE = $homeRefused42b
    try { $out = Invoke-Cli42b $pkg42b @('link', '--global') }
    finally { $env:USERPROFILE = $savedProfile42b }
    Assert-LinkRefused42b $out 'global'
    $left42b = @(Get-ChildItem -LiteralPath (Join-Path $homeRefused42b '.claude') -Force | ForEach-Object { $_.Name })
    if (($left42b -join ' ') -ne 'settings.json') { throw "Test 42b: link --global changed .claude after it could not link: $($left42b -join ', '). Output was: $out" }
    $left42b = @(Get-ChildItem -LiteralPath $homeRefused42b -Force | ForEach-Object { $_.Name })
    if (($left42b -join ' ') -ne '.claude') { throw "Test 42b: link --global left $($left42b -join ', ') in the home folder. Output was: $out" }

    Write-Host "[OK] Test 42b passed successfully! Able to create neither a symlink nor a junction, link stopped with a clear message and changed nothing (the linking cases were not run)." -ForegroundColor Green
}
else {
    $pkg42b = Join-Path $sandboxDir 'link-pkg-42b'
    $proj42b = Join-Path $sandboxDir 'link-project-42b'
    New-Package42b $pkg42b
    New-Item -ItemType Directory -Path $proj42b -Force | Out-Null
    $before42b = Get-FileCount42b (Join-Path $pkg42b '.claude')
    if ($before42b -eq 0) { throw "Test 42b: the package copy is empty" }
    function Get-PackageHashes42b {
        $root = Join-Path $pkg42b '.claude'
        (@(Get-ChildItem -LiteralPath $root -Recurse -File | Sort-Object FullName | ForEach-Object {
            "$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)  $($_.FullName.Substring($root.Length))"
        }) -join "`n")
    }
    $hashes42b = Get-PackageHashes42b
    if ($junction42b) { Write-Host "  (no right to create a symlink here: link is checked with directory junctions)" }
    # Every link `link` made is a junction where it may not make a symlink, and `link` says so
    # (checked when its output is passed; an empty one only checks the links are still there).
    function Assert-LinkKind42b {
        param([string]$ClaudeDir, [string]$Output)
        foreach ($sub in $subs42b) {
            $item = Get-Item -LiteralPath (Join-Path $ClaudeDir $sub) -Force -ErrorAction SilentlyContinue
            if (-not ($item -and $item.LinkType)) { throw "link did not create $ClaudeDir\$sub as a link. Output was: $Output" }
            if ($junction42b -and $item.LinkType -ne 'Junction') { throw "link made $ClaudeDir\$sub a $($item.LinkType), expected a junction. Output was: $Output" }
        }
        if ($junction42b -and $Output -and $Output -notmatch 'directory junctions') { throw "link did not say it used directory junctions. Output was: $Output" }
    }

    # 1. Test 39: link, then init and uninstall leave the package alone; unlink; a foreign link
    # survives.
    Set-Location -Path $proj42b
    git init -q -b main
    $out = Invoke-Cli42b $pkg42b @('link')
    if ($script:cliExit42b -ne 0) { throw "qa-instinct link failed with exit status $script:cliExit42b on this machine, which can create a symlink or a junction. Output was: $out" }
    Assert-LinkKind42b (Join-Path $proj42b '.claude') $out
    $out = Invoke-Cli42b $pkg42b @('init', '--editor', 'claude')
    if ($script:cliExit42b -ne 0) { throw "init over linked folders failed with exit status $script:cliExit42b. Output was: $out" }
    if ($out -notmatch 'nothing was written through it') { throw "init did not say it skipped a linked folder. Output was: $out" }
    $out = Invoke-Cli42b $pkg42b @('uninstall')
    if ($script:cliExit42b -ne 0) { throw "uninstall over linked folders failed with exit status $script:cliExit42b. Output was: $out" }
    if ((Get-PackageHashes42b) -ne $hashes42b) { throw "link then init and uninstall changed the package. Output was: $out" }
    if ($out -notmatch 'link to the package') { throw "uninstall did not say it skipped a linked folder. Output was: $out" }
    Assert-LinkKind42b (Join-Path $proj42b '.claude') ''

    $out = Invoke-Cli42b $pkg42b @('unlink')
    foreach ($sub in $subs42b) {
        if (Test-Path -LiteralPath (Join-Path $proj42b ".claude\$sub")) { throw "unlink left .claude\$sub behind. Output was: $out" }
    }
    $foreign42b = Join-Path $sandboxDir 'link-foreign-42b'
    New-Item -ItemType Directory -Path $foreign42b -Force | Out-Null
    New-Item -ItemType $handLinkType42b -Path (Join-Path $proj42b '.claude\rules') -Target $foreign42b | Out-Null
    $out = Invoke-Cli42b $pkg42b @('unlink')
    if (-not (Test-Link42b (Join-Path $proj42b '.claude\rules'))) { throw "unlink removed a link that does not point to the package. Output was: $out" }
    if ($out -notmatch 'Kept rules/') { throw "unlink did not report the link it kept. Output was: $out" }
    $out = Invoke-Cli42b $pkg42b @('link')
    $kept42b = Get-Item -LiteralPath (Join-Path $proj42b '.claude\rules') -Force
    if ("$($kept42b.Target)" -notlike '*link-foreign-42b*') { throw "link replaced a link that does not point to a qa-instinct package. Output was: $out" }
    Remove-Links42b (Join-Path $proj42b '.claude')

    # 2. link --global, then unlink --global, with a home directory of its own.
    $home42b = Join-Path $sandboxDir 'link-home-42b'
    New-Item -ItemType Directory -Path $home42b -Force | Out-Null
    $savedProfile42b = $env:USERPROFILE
    $env:USERPROFILE = $home42b
    $out = Invoke-Cli42b $pkg42b @('link', '--global')
    if ($script:cliExit42b -ne 0) { $env:USERPROFILE = $savedProfile42b; throw "qa-instinct link --global failed with exit status $script:cliExit42b. Output was: $out" }
    try { Assert-LinkKind42b (Join-Path $home42b '.claude') $out }
    catch { $env:USERPROFILE = $savedProfile42b; throw }
    $out = Invoke-Cli42b $pkg42b @('unlink', '--global')
    $env:USERPROFILE = $savedProfile42b
    foreach ($sub in $subs42b) {
        if (Test-Path -LiteralPath (Join-Path $home42b ".claude\$sub")) { throw "unlink --global left $sub behind in the home directory. Output was: $out" }
    }
    if ((Get-FileCount42b (Join-Path $pkg42b '.claude')) -ne $before42b) { throw "link --global then unlink --global changed the package" }

    # 3. A link left by a removed package is refreshed to the new package.
    $pkgA42b = Join-Path $sandboxDir 'link-pkg-42b-a'
    $pkgB42b = Join-Path $sandboxDir 'link-pkg-42b-b'
    $projStale42b = Join-Path $sandboxDir 'link-project-42b-stale'
    New-Package42b $pkgA42b
    New-Package42b $pkgB42b
    New-Item -ItemType Directory -Path $projStale42b -Force | Out-Null
    Set-Location -Path $projStale42b
    $out = Invoke-Cli42b $pkgA42b @('link')
    Remove-Item -LiteralPath $pkgA42b -Recurse -Force
    # Links to the removed package: uninstall and unlink from another copy keep them and fail on none.
    foreach ($command in @('uninstall', 'unlink')) {
        $out = Invoke-Cli42b $pkgB42b @($command)
        if ($script:cliExit42b -ne 0) { throw "$command over links to a removed package failed with exit status $script:cliExit42b. Output was: $out" }
        foreach ($sub in $subs42b) {
            if (-not (Test-Link42b (Join-Path $projStale42b ".claude\$sub"))) { throw "$command removed the stale link .claude\$sub. Output was: $out" }
        }
    }
    $out = Invoke-Cli42b $pkgB42b @('link')
    Assert-LinkKind42b (Join-Path $projStale42b '.claude') $out
    foreach ($sub in $subs42b) {
        $item = Get-Item -LiteralPath (Join-Path $projStale42b ".claude\$sub") -Force -ErrorAction SilentlyContinue
        if (-not ($item -and $item.LinkType) -or "$($item.Target)" -notlike '*link-pkg-42b-b*') {
            throw ".claude\$sub does not point into the second package after link from it. Output was: $out"
        }
    }
    Remove-Links42b (Join-Path $projStale42b '.claude')

    # 4. A real directory is never replaced, and the message names a command that can resolve it.
    $projReal42b = Join-Path $sandboxDir 'link-project-42b-real'
    New-Item -ItemType Directory -Path (Join-Path $projReal42b '.claude\rules') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $projReal42b '.claude\rules\mine.md'), "MY OWN RULE 42B`n")
    Set-Location -Path $projReal42b
    $out = Invoke-Cli42b $pkgB42b @('link')
    $realRules42b = Join-Path $projReal42b '.claude\rules'
    if ((Test-Link42b $realRules42b) -or -not (Test-Path -LiteralPath (Join-Path $realRules42b 'mine.md'))) { throw "link replaced or changed a real directory. Output was: $out" }
    if ($out -match "run 'unlink' first") { throw "link told the user to run 'unlink', which does not remove a real directory. Output was: $out" }
    if ($out -notmatch 'remove or rename it first') { throw "link did not say how to resolve a real directory. Output was: $out" }
    Remove-Links42b (Join-Path $projReal42b '.claude')

    $kind42b = if ($junction42b) { 'junctions' } else { 'symlinks' }
    Write-Host "[OK] Test 42b passed successfully! link and unlink work with $kind42b at both scopes, over a stale link and a real directory, and nothing was written or deleted through them." -ForegroundColor Green
}
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 43: Install-File refuses a destination outside its base, so it can never record an entry
# that does not resolve against that base (plan 033 item 6). The script cannot be dot-sourced (it
# ends by calling Main), so its functions are taken from its syntax tree, the way the bash suite
# extracts install_file for Test 13.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 43: Install-File refuses a destination outside its base..." -ForegroundColor Yellow

$tokens43 = $null; $errors43 = $null
$ast43 = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repoDir 'install.ps1'), [ref]$tokens43, [ref]$errors43)
$functions43 = $ast43.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
foreach ($f in $functions43) { . ([scriptblock]::Create($f.Extent.Text)) }
$script:ManifestBuffer = @{}; $script:ReportedLinks = @{}; $script:KnownHashes = @{}; $script:UpdateReport = $false

$base43 = Join-Path $sandboxDir 'guard-base-43'
$outside43 = Join-Path $sandboxDir 'guard-base-43-outside\escaped.md'
New-Item -ItemType Directory -Path $base43 -Force | Out-Null
$refused43 = $null
try { Install-File $base43 'claude' (Join-Path $repoDir '.claude\commands\qa.md') $outside43 }
catch { $refused43 = $_.Exception.Message }
if (-not $refused43 -or $refused43 -notmatch 'not inside base') { throw "Install-File did not refuse a destination outside its base (got: '$refused43')" }
if (Test-Path -LiteralPath $outside43) { throw "Install-File wrote a file outside its base" }
if (@($script:ManifestBuffer.Values | ForEach-Object { $_ }).Count -ne 0) { throw "Install-File recorded a path outside its base" }
Write-Host "[OK] Test 43 passed successfully! A destination outside the base was refused and never recorded." -ForegroundColor Green
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 44: A folder is a link only when its reparse tag says so (plan 044 item 1). OneDrive's
# Files-On-Demand marks every folder it syncs as a reparse point with a cloud tag and no link type;
# treating that attribute as a link made the installer skip real folders as links. OneDrive itself
# cannot be used here (its folders sync to the cloud), so the test makes a folder carrying a
# reparse point of a third-party tag, which an unelevated user may set on a folder they own, and
# checks the decision on it, on a plain folder, a junction and a junction whose target is gone.
# Junctions stand in for links because creating one needs no privilege. Install-File cannot be run
# into the tagged folder: with no filter driver to handle its tag, nothing can be opened inside it.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 44: Test-IsLink decides from the reparse tag, not the reparse-point attribute..." -ForegroundColor Yellow

Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
public static class ReparseTag44 {
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern SafeFileHandle CreateFileW(string name, uint access, uint share, IntPtr sa, uint disposition, uint flags, IntPtr template);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool DeviceIoControl(SafeFileHandle handle, uint code, byte[] inBuffer, int inSize, IntPtr outBuffer, int outSize, out int returned, IntPtr overlapped);
    // A REPARSE_GUID_DATA_BUFFER: tag, data length, reserved, GUID, data.
    static byte[] Buffer(uint tag, int dataLength) {
        byte[] b = new byte[24 + dataLength];
        BitConverter.GetBytes(tag).CopyTo(b, 0);
        BitConverter.GetBytes((ushort)dataLength).CopyTo(b, 4);
        new Guid("6f1b5c8e-3b0a-4f3c-9a51-2a8d1b7e4c10").ToByteArray().CopyTo(b, 8);
        return b;
    }
    static void Control(string path, uint code, byte[] buffer) {
        // GENERIC_WRITE, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT.
        using (SafeFileHandle h = CreateFileW(path, 0x40000000, 7, IntPtr.Zero, 3, 0x02000000 | 0x00200000, IntPtr.Zero)) {
            if (h.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
            int returned;
            if (!DeviceIoControl(h, code, buffer, buffer.Length, IntPtr.Zero, 0, out returned, IntPtr.Zero))
                throw new Win32Exception(Marshal.GetLastWin32Error());
        }
    }
    public static void Set(string path, uint tag) { Control(path, 0x000900A4, Buffer(tag, 4)); }
    public static void Remove(string path, uint tag) { Control(path, 0x000900AC, Buffer(tag, 0)); }
}
'@

$tokens44 = $null; $errors44 = $null
$ast44 = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repoDir 'install.ps1'), [ref]$tokens44, [ref]$errors44)
foreach ($f in $ast44.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
    . ([scriptblock]::Create($f.Extent.Text))
}

# A non-Microsoft tag (bit 31 clear), which no driver on this machine handles.
$tag44 = [uint32]0x00000123
$base44 = Join-Path $sandboxDir 'reparse-44'
$top44 = Join-Path $base44 'top'
New-Item -ItemType Directory -Path (Join-Path $top44 'plain'), (Join-Path $top44 'tagged'), (Join-Path $base44 'target'), (Join-Path $base44 'gone') -Force | Out-Null
New-Item -ItemType Junction -Path (Join-Path $top44 'junction') -Value (Join-Path $base44 'target') | Out-Null
New-Item -ItemType Junction -Path (Join-Path $top44 'dangling') -Value (Join-Path $base44 'gone') | Out-Null
Remove-Item -LiteralPath (Join-Path $base44 'gone') -Force
[ReparseTag44]::Set((Join-Path $top44 'tagged'), $tag44)
try {
    $attributes44 = [System.IO.File]::GetAttributes((Join-Path $top44 'tagged'))
    if (-not ($attributes44 -band [System.IO.FileAttributes]::ReparsePoint)) { throw "Test 44 setup: the tagged folder is not a reparse point ($attributes44)" }
    $cases44 = [ordered]@{ plain = $false; tagged = $false; junction = $true; dangling = $true }
    foreach ($name in $cases44.Keys) {
        $got = Test-IsLink (Join-Path $top44 $name)
        if ($got -ne $cases44[$name]) { throw "Test 44: Test-IsLink says $got for the $name folder, expected $($cases44[$name])" }
        $ancestor = Get-LinkedAncestor $base44 "top/$name/qa.md"
        $want = if ($cases44[$name]) { "top/$name" } else { $null }
        if ($ancestor -ne $want) { throw "Test 44: Get-LinkedAncestor gives '$ancestor' for top/$name/qa.md, expected '$want'" }
    }
}
finally {
    [ReparseTag44]::Remove((Join-Path $top44 'tagged'), $tag44)
    # Remove the junctions themselves: Remove-Item -Recurse on Windows PowerShell 5.1 follows them.
    foreach ($name in 'junction', 'dangling') { [System.IO.Directory]::Delete((Join-Path $top44 $name), $false) }
}
Write-Host "[OK] Test 44 passed successfully! A folder with a non-link reparse tag is a folder; junctions, dangling ones included, are links." -ForegroundColor Green
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 45: A run that fails part-way still records what it installed before the failure (plan 044
# item 2). .agents\skills is a file, so creating .agents\skills\qa for antigravity, the last editor
# of -Editor all, fails; every editor before it was installed and must be in the manifest, or
# uninstall could never remove those files.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 45: a failed run keeps the manifest entries of what it installed..." -ForegroundColor Yellow

$proj45 = Join-Path $sandboxDir 'abort-45'
New-Item -ItemType Directory -Path (Join-Path $proj45 '.agents') -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $proj45 '.agents\skills'), "NOT A FOLDER`n")
Set-Location -Path $proj45
$out45 = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor all -NonInteractive -NoHooks 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) { throw "Test 45: install.ps1 exited 0 although .agents\skills is a file. Output was: $out45" }
$manifest45 = Join-Path $proj45 '.qa-skills-manifest'
if (-not (Test-Path -LiteralPath $manifest45)) { throw "Test 45: the failed run saved no manifest, orphaning every file it installed. Output was: $out45" }
$lines45 = [System.IO.File]::ReadAllLines($manifest45)
# Antigravity's rule files come before its skills (plan 047), so they were installed and recorded.
foreach ($entry in @('claude  .claude/commands/qa.md', 'cursor  .cursor/rules/qa-instinct.mdc', 'cline  .cline/rules/qa-instinct.md', 'antigravity  .agents/rules/qa-instinct.md')) {
    if (-not ($lines45 | Where-Object { $_.EndsWith("  $entry") })) { throw "Test 45: the manifest lacks '$entry'. Manifest: $($lines45 -join ' | ')" }
}
if ($lines45 | Where-Object { $_ -match '  antigravity  \.agents/skills/' }) { throw "Test 45: the manifest records antigravity skills, which were not installed" }
if ((Get-Content -Raw -LiteralPath (Join-Path $proj45 '.agents\skills')) -ne "NOT A FOLDER`n") { throw "Test 45: the file at .agents\skills changed" }
Write-Host "[OK] Test 45 passed successfully! The run failed on antigravity and still recorded every file it installed before it." -ForegroundColor Green
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 46: A global uninstall with no git on PATH finishes and cleans the hook (plan 044 item 3).
# install.sh reads core.hooksPath as empty when git is missing and cleans ~/.git-templates/hooks;
# install.ps1 called git directly and stopped with exit 1 after removing the files.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 46: global uninstall with no git on PATH..." -ForegroundColor Yellow

$home46 = Join-Path $sandboxDir 'nogit-46\home'
$proj46 = Join-Path $sandboxDir 'nogit-46\project'
New-Item -ItemType Directory -Path $home46, $proj46 -Force | Out-Null
$savedProfile46 = $env:USERPROFILE; $savedHome46 = $env:HOME; $savedPath46 = $env:PATH
$env:USERPROFILE = $home46; $env:HOME = $home46
Set-Location -Path $proj46
try {
    $out46 = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target global -Editor claude -NonInteractive 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Test 46: the global install failed with exit status $LASTEXITCODE. Output was: $out46" }
    $hook46 = Join-Path $home46 '.git-templates\hooks\pre-commit'
    if (-not (Test-Path -LiteralPath $hook46)) { throw "Test 46 setup: the global install wrote no hook at $hook46. Output was: $out46" }

    $env:PATH = (($env:PATH -split ';') | Where-Object {
            $_ -and -not (Test-Path -LiteralPath (Join-Path $_ 'git.exe')) -and -not (Test-Path -LiteralPath (Join-Path $_ 'git.cmd'))
        }) -join ';'
    if (Get-Command git -ErrorAction SilentlyContinue) { throw "Test 46 setup: git is still on PATH" }
    $out46 = & "$PSHOME\powershell.exe" -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target global -Editor claude -NonInteractive -Uninstall 2>&1 | Out-String
    $exit46 = $LASTEXITCODE
}
finally {
    $env:USERPROFILE = $savedProfile46; $env:HOME = $savedHome46; $env:PATH = $savedPath46
}
if ($exit46 -ne 0) { throw "Test 46: the global uninstall without git exited $exit46. Output was: $out46" }
if (Test-Path -LiteralPath (Join-Path $home46 '.claude\commands\qa.md')) { throw "Test 46: the global uninstall left .claude\commands\qa.md" }
if (Test-Path -LiteralPath $hook46) { throw "Test 46: the global uninstall without git left the hook at $hook46. Output was: $out46" }
if ($out46 -notmatch 'Uninstallation successful') { throw "Test 46: the uninstall did not report success. Output was: $out46" }
Write-Host "[OK] Test 46 passed successfully! Without git the global uninstall removed the files and the hook, and exited 0." -ForegroundColor Green
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 47: -Target project run from the home folder is a project install (plan 044 item 4). The
# scope came from comparing the folder with the home folder, so Cline and Copilot were skipped as
# global-only and Windsurf went to its global path. install.sh and the CLI take it from the target.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 47: -Target project from the home folder installs the project paths..." -ForegroundColor Yellow

$home47 = Join-Path $sandboxDir 'home-as-project-47'
New-Item -ItemType Directory -Path $home47 -Force | Out-Null
$savedProfile47 = $env:USERPROFILE; $savedHome47 = $env:HOME
$env:USERPROFILE = $home47; $env:HOME = $home47
Set-Location -Path $home47
try {
    $out47 = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor all -NonInteractive -NoHooks 2>&1 | Out-String
    $exit47 = $LASTEXITCODE
    $present47 = @{}
    foreach ($rel in '.cline\rules\qa-instinct.md', '.windsurf\rules\qa-instinct.md', '.github\copilot-instructions.md', '.cursor\rules\qa-instinct.mdc', '.agents\skills\qa\SKILL.md', '.codeium\windsurf\skills\qa\SKILL.md', '.gemini\config\skills\qa\SKILL.md') {
        $present47[$rel] = Test-Path -LiteralPath (Join-Path $home47 $rel)
    }
    $manifest47 = Join-Path $home47 '.qa-skills-manifest'
    $lines47 = if (Test-Path -LiteralPath $manifest47) { [System.IO.File]::ReadAllLines($manifest47) } else { @() }
    $outUn47 = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor all -NonInteractive -NoHooks -Uninstall 2>&1 | Out-String
    $exitUn47 = $LASTEXITCODE
}
finally {
    $env:USERPROFILE = $savedProfile47; $env:HOME = $savedHome47
}
if ($exit47 -ne 0) { throw "Test 47: the install exited $exit47. Output was: $out47" }
foreach ($rel in '.cline\rules\qa-instinct.md', '.windsurf\rules\qa-instinct.md', '.github\copilot-instructions.md', '.cursor\rules\qa-instinct.mdc', '.agents\skills\qa\SKILL.md') {
    if (-not $present47[$rel]) { throw "Test 47: a project install from the home folder did not write $rel. Output was: $out47" }
}
foreach ($rel in '.codeium\windsurf\skills\qa\SKILL.md', '.gemini\config\skills\qa\SKILL.md') {
    if ($present47[$rel]) { throw "Test 47: a project install from the home folder wrote the global path $rel" }
}
foreach ($entry in @('cline  .cline/rules/qa-instinct.md', 'copilot  .github/copilot-instructions.md', 'windsurf  .windsurf/rules/qa-instinct.md')) {
    if (-not ($lines47 | Where-Object { $_.EndsWith("  $entry") })) { throw "Test 47: the manifest lacks '$entry'. Manifest: $($lines47 -join ' | ')" }
}
if ($exitUn47 -ne 0) { throw "Test 47: the uninstall exited $exitUn47. Output was: $outUn47" }
foreach ($rel in '.cline', '.windsurf', '.github', '.cursor', '.agents', '.claude', '.qa-skills-manifest') {
    if (Test-Path -LiteralPath (Join-Path $home47 $rel)) { throw "Test 47: a project uninstall from the home folder left $rel. Output was: $outUn47" }
}
Write-Host "[OK] Test 47 passed successfully! From the home folder, -Target project installed and removed the project paths." -ForegroundColor Green
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 48: An interactive run with -Editor uses that editor and shows no editor menu (plan 044
# item 8). Main checked $PSBoundParameters, which inside a function holds the function's own
# parameters, never the script's, so the menu always showed and its default replaced -Editor.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 48: an interactive run keeps -Editor and skips the editor menu..." -ForegroundColor Yellow

$proj48 = Join-Path $sandboxDir 'editor-flag-48\project'
$bin48 = Join-Path $sandboxDir 'editor-flag-48\bin'
New-Item -ItemType Directory -Path $proj48, $bin48 -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $bin48 'claude.cmd'), "@exit /b 0`r`n")
$savedPath48 = $env:PATH
$env:PATH = "$bin48;$env:PATH"
Set-Location -Path $proj48
try {
    # One answer, for the operation menu (install). An editor menu would take the empty input that
    # follows as its default, Claude Code.
    $out48 = @('1') | powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor cursor -NoHooks 2>&1 | Out-String
    $exit48 = $LASTEXITCODE
}
finally { $env:PATH = $savedPath48 }
if ($exit48 -ne 0) { throw "Test 48: the install exited $exit48. Output was: $out48" }
if ($out48 -match 'Editor Target') { throw "Test 48: the editor menu was shown although -Editor was given. Output was: $out48" }
if (-not (Test-Path -LiteralPath (Join-Path $proj48 '.cursor\rules\qa-instinct.mdc'))) { throw "Test 48: -Editor cursor did not install the Cursor rule. Output was: $out48" }
if (Test-Path -LiteralPath (Join-Path $proj48 '.claude')) { throw "Test 48: -Editor cursor installed Claude Code. Output was: $out48" }
Write-Host "[OK] Test 48 passed successfully! -Editor cursor installed Cursor only, with no editor menu." -ForegroundColor Green
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 49: The commit offer commits only what the installer recorded (plan 044 items 5 and 7). It
# listed every path the package ships, editor paths hard-coded, so a .clinerules folder the install
# skipped was staged and committed with the user's rules in it. Since plan 047 Cline installs into
# .cline/, so the skipped folder stands at Copilot's .github\copilot-instructions.md instead. The project is a git worktree, so
# .git is a file, and its manifest carries tampered entries, which must never reach git add.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 49: the commit offer commits only the files the installer recorded..." -ForegroundColor Yellow

$root49 = Join-Path $sandboxDir 'commit-49'
$main49 = Join-Path $root49 'main'
$proj49 = Join-Path $root49 'worktree'
$bin49 = Join-Path $root49 'bin'
New-Item -ItemType Directory -Path $main49, $bin49 -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $bin49 'claude.cmd'), "@exit /b 0`r`n")
git -C $main49 -c "init.templateDir=" init -q -b main
git -C $main49 config user.name 'QA Tester Win'
git -C $main49 config user.email 'qa-win@tester.com'
# No line-ending conversion: its warnings on stderr would stop this script under 'Stop'.
git -C $main49 config core.autocrlf false
[System.IO.File]::WriteAllText((Join-Path $main49 'notes.md'), "first`n")
git -C $main49 add -- notes.md
git -C $main49 commit -q -m 'initial'
git -C $main49 worktree add -q $proj49 -b work49
if (-not (Test-Path -LiteralPath (Join-Path $proj49 '.git') -PathType Leaf)) { throw "Test 49 setup: the worktree's .git is not a file" }
# The user's own work: a folder where the package installs a file, not yet committed, and an edit
# to a tracked file.
New-Item -ItemType Directory -Path (Join-Path $proj49 '.github\copilot-instructions.md') -Force | Out-Null
[System.IO.File]::WriteAllText((Join-Path $proj49 '.github\copilot-instructions.md\01-mine.md'), "MY RULE`n")
[System.IO.File]::WriteAllText((Join-Path $proj49 'notes.md'), "edited`n")
[System.IO.File]::WriteAllText((Join-Path $root49 'outside-49.md'), "OUTSIDE`n")
# Two tampered entries: one outside the project, one that climbs back into it to the user's file.
$zeros49 = '0' * 64
[System.IO.File]::WriteAllText((Join-Path $proj49 '.qa-skills-manifest'), "$zeros49  claude  ../outside-49.md`n$zeros49  claude  .cursor/../notes.md`n")
$savedPath49 = $env:PATH
$env:PATH = "$bin49;$env:PATH"
Set-Location -Path $proj49
try {
    # Answers: the operation menu (install), the commit offer (yes), the push offer (no).
    $out49 = @('1', 'y', 'n') | powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor all -NoHooks 2>&1 | Out-String
    $exit49 = $LASTEXITCODE
}
finally { $env:PATH = $savedPath49 }
if ($exit49 -ne 0) { throw "Test 49: the install exited $exit49. Output was: $out49" }
$subject49 = (git -C $proj49 log -1 --format=%s) | Out-String
if ($subject49 -notmatch 'Add/update QA skill') { throw "Test 49: the installer made no commit. Output was: $out49" }
$committed49 = @(git -C $proj49 -c core.quotepath=false show --name-only --format= HEAD | Where-Object { $_ })
foreach ($rel in '.claude/commands/qa.md', '.cursor/rules/qa-instinct.mdc', '.windsurf/rules/qa-instinct.md', '.github/skills/qa/SKILL.md', '.cline/rules/qa-instinct.md', '.agents/skills/qa/SKILL.md', '.qa-skills-manifest') {
    if ($committed49 -notcontains $rel) { throw "Test 49: the commit lacks $rel. It holds: $($committed49 -join ', ')" }
}
foreach ($rel in '.github/copilot-instructions.md/01-mine.md', 'notes.md') {
    if ($committed49 -contains $rel) { throw "Test 49: the commit took the user's $rel. It holds: $($committed49 -join ', ')" }
}
if ($committed49 | Where-Object { $_ -match 'outside-49' }) { throw "Test 49: the commit took a path outside the project" }
if ((Get-Content -Raw -LiteralPath (Join-Path $proj49 'notes.md')) -ne "edited`n") { throw "Test 49: the user's edit to notes.md changed" }
Set-Location -Path $repoDir
git -C $main49 worktree remove --force $proj49
Write-Host "[OK] Test 49 passed successfully! In a worktree, the commit held the recorded files and the manifest, and none of the user's own." -ForegroundColor Green
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 50: An install of release 4.0.1 moves to the native layout, one editor at a time (plan 047
# step 6). 4.0.1 shipped no install.ps1 that this machine could run from the fixture, so the install
# is rebuilt from tests\fixtures\release-v4.0.1\.qa-skills-editor-map, the paths 4.0.1 wrote: one
# file per path, recorded in the manifest with its hash. Migration depends on paths and recorded
# hashes, not on the adapter text, so the text is a stand-in. Update must remove each old file it
# no longer ships, saying so, add the editor's rules and skills, and leave nothing on uninstall;
# uninstall straight from 4.0.1 must leave nothing either. tests/test-lifecycle.sh Test 63 runs
# the real 4.0.1 installer.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 50: a 4.0.1 install of each editor updates to the native layout and uninstalls to nothing..." -ForegroundColor Yellow

$utf8NoBom50 = New-Object System.Text.UTF8Encoding($false)
$map401 = @{}
foreach ($line in [System.IO.File]::ReadAllLines((Join-Path $repoDir 'tests\fixtures\release-v4.0.1\.qa-skills-editor-map'))) {
    if (-not $line) { continue }
    $parts = $line -split "`t"
    $map401[$parts[0]] = @{ project = $parts[2]; global = $parts[3] }
}
$mapNow = @{}
foreach ($line in [System.IO.File]::ReadAllLines((Join-Path $repoDir '.qa-skills-editor-map'))) {
    if (-not $line) { continue }
    $parts = $line -split "`t"
    $mapNow[$parts[0]] = $parts[3]
}

# Seeds 4.0.1's files of one editor into a fresh project and home; returns their relative paths.
function New-Install401 {
    param([string]$Editor, [string]$Root)
    $old = @()
    foreach ($scope in @('project', 'home')) {
        $base = Join-Path $Root $scope
        New-Item -ItemType Directory -Path $base -Force | Out-Null
        $rel = if ($scope -eq 'project') { $map401[$Editor].project } else { $map401[$Editor].global }
        if ($rel -eq '-') { continue }
        $file = Join-Path $base ($rel -replace '/', '\')
        New-Item -ItemType Directory -Path (Split-Path -Parent $file) -Force | Out-Null
        [System.IO.File]::WriteAllText($file, "BEM-TE-VI 4.0.1 $Editor ADAPTER`n", $utf8NoBom50)
        $hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLower()
        [System.IO.File]::AppendAllText((Join-Path $base '.qa-skills-manifest'), "$hash  $Editor  $rel`n", $utf8NoBom50)
        $old += "$scope/$rel"
    }
    return ,$old
}
function Invoke-Current50 {
    param([string]$Op, [string]$Editor, [string]$Root)
    $savedProfile = $env:USERPROFILE; $savedHome = $env:HOME
    $env:USERPROFILE = Join-Path $Root 'home'; $env:HOME = $env:USERPROFILE
    Set-Location -Path (Join-Path $Root 'project')
    try {
        $out = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target both -Editor $Editor -NonInteractive -NoHooks "-$Op" 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { throw "Test 50: install.ps1 -$Op over 4.0.1's $Editor install exited $LASTEXITCODE. Output was: $out" }
    }
    finally { $env:USERPROFILE = $savedProfile; $env:HOME = $savedHome; Set-Location -Path $repoDir }
    return $out
}
# Windows PowerShell started with this home as its profile creates AppData\Roaming there itself;
# that folder is PowerShell's, not the installer's, and is not counted.
function Get-Left50 {
    param([string]$Root)
    return @(Get-ChildItem -LiteralPath (Join-Path $Root 'project'), (Join-Path $Root 'home') -Recurse -Force -ErrorAction SilentlyContinue |
        ForEach-Object { $_.FullName.Substring($Root.Length + 1) } | Where-Object { $_ -notlike 'home\AppData*' })
}

foreach ($ed in @('cursor', 'windsurf', 'copilot', 'cline', 'antigravity')) {
    $root50 = Join-Path $sandboxDir "migrate-50\$ed"
    $old50 = New-Install401 $ed $root50
    $out50 = Invoke-Current50 'Update' $ed $root50
    if ($out50 -notmatch 'Added') { throw "Test 50: update of 4.0.1's $ed install added nothing. Output was: $out50" }
    # Copilot is the one editor whose 4.0.1 file is still shipped where it was.
    if ($ed -ne 'copilot' -and $out50 -notmatch 'no longer shipped') { throw "Test 50: update of 4.0.1's $ed install removed no old file. Output was: $out50" }
    if ($out50 -match 'Kept |backed up') { throw "Test 50: update of 4.0.1's $ed install kept or backed up a file. Output was: $out50" }
    foreach ($rel in $old50) {
        if ($rel -in @('project/.github/copilot-instructions.md', 'project/.agents/skills/qa/SKILL.md')) { continue }
        if (Test-Path -LiteralPath (Join-Path $root50 ($rel -replace '/', '\'))) { throw "Test 50: update left 4.0.1's $rel" }
        $scope = ($rel -split '/', 2)[0]; $path = ($rel -split '/', 2)[1]
        $mf = Join-Path (Join-Path $root50 $scope) '.qa-skills-manifest'
        if ((Test-Path -LiteralPath $mf) -and ([System.IO.File]::ReadAllLines($mf) | Where-Object { $_.EndsWith("  $path") })) { throw "Test 50: update still records 4.0.1's $rel" }
    }
    $skills50 = Join-Path (Join-Path $root50 'project') ($mapNow[$ed] -replace '/', '\')
    foreach ($f in @(Get-ChildItem -LiteralPath (Join-Path $repoDir 'adapters\skills') -Recurse -File)) {
        $rel = $f.FullName.Substring((Join-Path $repoDir 'adapters\skills').Length + 1)
        $dest = Join-Path $skills50 $rel
        if (-not (Test-Path -LiteralPath $dest) -or (Get-FileHash -LiteralPath $dest).Hash -ne (Get-FileHash -LiteralPath $f.FullName).Hash) { throw "Test 50: update did not install $ed's skill file $rel" }
    }
    if (Get-ChildItem -LiteralPath $root50 -Recurse -Force -Filter '*.qa-skills-backup-*') { throw "Test 50: update of 4.0.1's $ed install made a backup" }

    $null = Invoke-Current50 'Uninstall' $ed $root50
    $left50 = Get-Left50 $root50
    if ($left50.Count -gt 0) { throw "Test 50: uninstall after the update of $ed left: $($left50 -join ', ')" }

    # Uninstall straight from 4.0.1: the manifest leads to the old paths.
    Remove-Item -LiteralPath $root50 -Recurse -Force
    $null = New-Install401 $ed $root50
    $null = Invoke-Current50 'Uninstall' $ed $root50
    $left50 = Get-Left50 $root50
    if ($left50.Count -gt 0) { throw "Test 50: uninstall of 4.0.1's $ed install left: $($left50 -join ', ')" }
}
Write-Host "[OK] Test 50 passed successfully! Each editor's 4.0.1 install moved to the native layout and uninstalled to nothing." -ForegroundColor Green
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 51: An editor none of whose files was written is not reported as installed (plan 053 I14).
# Conformance case 062 links the folders, which this machine may not be allowed to do; junctions,
# which need no privilege, are links to install.ps1 too. Four .claude folders and both Cursor
# folders are junctions, and the two hooks are read-only copies, so every destination is skipped.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 51: an editor nothing was written for is not reported installed..." -ForegroundColor Yellow

$root51 = Join-Path $sandboxDir 'nothing-written-51'
$proj51 = Join-Path $root51 'project'
$shared51 = Join-Path $root51 'shared'
foreach ($rel in '.claude\commands', '.claude\rules', '.claude\skills', '.claude\agents', '.cursor\rules', '.cursor\skills') {
    $target = Join-Path $shared51 ($rel -replace '\\', '-')
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path -Parent (Join-Path $proj51 $rel)) -Force | Out-Null
    New-Item -ItemType Junction -Path (Join-Path $proj51 $rel) -Target $target | Out-Null
}
New-Item -ItemType Directory -Path (Join-Path $proj51 '.claude\hooks') -Force | Out-Null
foreach ($hook in 'check-test-evidence.sh', 'validate-tc-format.sh') {
    $dest = Join-Path $proj51 ".claude\hooks\$hook"
    Copy-Item -LiteralPath (Join-Path $repoDir ".claude\hooks\$hook") -Destination $dest
    Set-ItemProperty -LiteralPath $dest -Name IsReadOnly -Value $true
}
Set-Location -Path $proj51
$out51 = ''
foreach ($ed in 'claude', 'cursor') {
    $out51 += powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor $ed -NonInteractive -NoHooks 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Test 51: install.ps1 -Editor $ed exited $LASTEXITCODE. Output was: $out51" }
}
Set-Location -Path $repoDir
if ($out51 -notmatch 'symbolic link') { throw "Test 51: install.ps1 did not report the linked folders. Output was: $out51" }
if ($out51 -match 'scaffolded') { throw "Test 51: install.ps1 reported Claude Code installed with nothing written. Output was: $out51" }
if ($out51 -match [regex]::Escape('.cursor/rules/ and .cursor/skills/')) { throw "Test 51: install.ps1 reported Cursor installed with nothing written. Output was: $out51" }
if (([regex]::Matches($out51, [regex]::Escape('Nothing was installed: every destination was skipped (see above).'))).Count -ne 2) { throw "Test 51: install.ps1 did not say, once per run, that nothing was installed. Output was: $out51" }
if ($out51 -match 'Installation successful!|Next steps') { throw "Test 51: install.ps1 reported success with nothing written. Output was: $out51" }
$written51 = @(Get-ChildItem -LiteralPath $shared51 -Recurse -Force -File)
if ($written51.Count -gt 0) { throw "Test 51: install.ps1 wrote through a junction: $($written51.FullName -join ', ')" }
if (Test-Path -LiteralPath (Join-Path $proj51 '.qa-skills-manifest')) { throw "Test 51: install.ps1 recorded something although nothing was written" }
Get-ChildItem -LiteralPath (Join-Path $proj51 '.claude\hooks') -File | ForEach-Object { $_.IsReadOnly = $false }
# Remove the junctions themselves: Remove-Item -Recurse on Windows PowerShell 5.1 follows them.
foreach ($rel in '.claude\commands', '.claude\rules', '.claude\skills', '.claude\agents', '.cursor\rules', '.cursor\skills') { [System.IO.Directory]::Delete((Join-Path $proj51 $rel), $false) }
Write-Host "[OK] Test 51 passed successfully! Neither editor was reported installed, and nothing was written through a junction." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 52: A link planted at the exact name of a backup, of a backup's .link-target file or of the
# manifest's temp file is never written through, and the name is passed over (plan 053 I10).
# install.ps1's functions are taken from its syntax tree, as in Test 43. Get-Date is pinned, so
# the backup names are known, and Set-ManifestLines is redefined with its first temp name pinned.
# A junction is planted everywhere, since any user may create one; a file symlink to a victim
# only where this machine may create a symlink, otherwise that part reports "not run", as the
# conformance runner does. The last part runs the CLI here over a junction at its backup name.
# tests/test-lifecycle.sh Tests 46b, 49 and 66 cover install.sh and the CLI on Linux and macOS.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 52: install.ps1 never writes through a link planted at a name it creates..." -ForegroundColor Yellow

$tokens52 = $null; $errors52 = $null
$ast52 = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repoDir 'install.ps1'), [ref]$tokens52, [ref]$errors52)
foreach ($f in $ast52.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
    $text52 = $f.Extent.Text
    if ($f.Name -eq 'Set-ManifestLines') {
        $pinnedText52 = $text52.Replace("[guid]::NewGuid().ToString('N')", '(Get-TempName52)')
        if ($pinnedText52 -eq $text52) { throw "Test 52: Set-ManifestLines no longer names its temp file with a GUID; update the test" }
        $text52 = $pinnedText52
    }
    . ([scriptblock]::Create($text52))
}
$script:ManifestBuffer = @{}; $script:ReportedLinks = @{}; $script:KnownHashes = @{}; $script:UpdateReport = $false
$script:tempNames52 = @('planted')
function Get-TempName52 {
    if ($script:tempNames52.Count -gt 0) { $name = $script:tempNames52[0]; $script:tempNames52 = @($script:tempNames52 | Select-Object -Skip 1); return $name }
    return [guid]::NewGuid().ToString('N')
}
function Get-Date { return New-Object DateTime 2026, 10, 19, 5, 2, 0, ([DateTimeKind]::Utc) }
$stamp52 = '20261019T050200Z'

$root52 = Join-Path $sandboxDir 'planted-52'
$victimDir52 = Join-Path $root52 'victim-folder'
New-Item -ItemType Directory -Path $victimDir52 -Force | Out-Null
$utf8NoBom52 = New-Object System.Text.UTF8Encoding($false)
$symlinks52 = $true
$probe52 = Join-Path $root52 'symlink-probe'
try { New-Item -ItemType SymbolicLink -Path $probe52 -Target $victimDir52 -ErrorAction Stop | Out-Null; [System.IO.Directory]::Delete($probe52, $false) }
catch {
    if ($_.FullyQualifiedErrorId -notlike 'NewItemSymbolicLinkElevationRequired*') { throw }
    $symlinks52 = $false
}
# Plants a link of the given kind at the name: a junction to the victim folder, or a file symlink
# to a victim file holding VICTIM.
function New-Plant52([string]$Name, [string]$Kind) {
    if ($Kind -eq 'junction') { New-Item -ItemType Junction -Path $Name -Target $victimDir52 | Out-Null; return }
    $victim = "$Name.victim"
    [System.IO.File]::WriteAllText($victim, "VICTIM`n", $utf8NoBom52)
    New-Item -ItemType SymbolicLink -Path $Name -Target $victim | Out-Null
}
function Assert-Plant52([string]$Name, [string]$Kind, [string]$What) {
    if (-not (Test-IsLink $Name)) { throw "Test 52: the $Kind planted at the $What name was removed or replaced" }
    if ($Kind -eq 'junction') {
        if (@(Get-ChildItem -LiteralPath $victimDir52 -Force).Count -gt 0) { throw "Test 52: install.ps1 wrote into the folder a junction at the $What name leads to" }
    }
    elseif ([System.IO.File]::ReadAllText("$Name.victim") -ne "VICTIM`n") { throw "Test 52: install.ps1 wrote through a symlink planted at the $What name" }
}
$kinds52 = @('junction')
if ($symlinks52) { $kinds52 += 'symlink' } else { Write-Host "  - the file-symlink part is not run: creating a symlink needs Developer Mode or an elevated shell" -ForegroundColor Yellow }

foreach ($kind in $kinds52) {
    $dir = Join-Path $root52 $kind
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    # A backup: the user's file collides with the package's, and its backup name is taken.
    $dest = Join-Path $dir 'security-qa.md'
    [System.IO.File]::WriteAllText($dest, "THE USER'S OWN RULES`n", $utf8NoBom52)
    New-Plant52 "$dest.qa-skills-backup-$stamp52" $kind
    $backup = Backup-Destination $dir 'claude' 'security-qa.md' $dest (Join-Path $repoDir '.claude\rules\security-qa.md')
    Assert-Plant52 "$dest.qa-skills-backup-$stamp52" $kind 'backup'
    if (-not $backup -or $backup.Path -ne "$dest.qa-skills-backup-$stamp52-1") { throw "Test 52: the backup over a $kind at its name went to '$($backup.Path)', expected the next name" }
    if ([System.IO.File]::ReadAllText($backup.Path) -ne "THE USER'S OWN RULES`n") { throw "Test 52: the backup over a $kind at its name holds the wrong content" }

    # The manifest's temp file.
    $mf = Join-Path $dir '.qa-skills-manifest'
    $script:tempNames52 = @('planted')
    New-Plant52 "$mf.tmp-planted" $kind
    Set-ManifestLines $mf @('0000000000000000000000000000000000000000000000000000000000000000  claude  .claude/rules/security-qa.md')
    Assert-Plant52 "$mf.tmp-planted" $kind 'manifest temp'
    if ((Test-IsLink $mf) -or [System.IO.File]::ReadAllText($mf) -notmatch '  claude  \.claude/rules/security-qa\.md') { throw "Test 52: no manifest was written beside a $kind at its temp name" }
}

if ($symlinks52) {
    # A .link-target file: the destination is a symlink to the user's file, so its content is
    # backed up and the link's target recorded beside the backup, whose .link-target name is taken.
    $dir = Join-Path $root52 'link-target'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $theirs = Join-Path $dir 'theirs.md'
    [System.IO.File]::WriteAllText($theirs, "THE USER'S OWN RULES`n", $utf8NoBom52)
    $dest = Join-Path $dir 'security-qa.md'
    New-Item -ItemType SymbolicLink -Path $dest -Target $theirs | Out-Null
    New-Plant52 "$dest.qa-skills-backup-$stamp52.link-target" 'symlink'
    $out52 = Install-File $dir 'claude' (Join-Path $repoDir '.claude\rules\security-qa.md') $dest 6>&1 | Out-String
    Assert-Plant52 "$dest.qa-skills-backup-$stamp52.link-target" 'symlink' '.link-target'
    if (Test-IsLink $dest) { throw "Test 52: the symlinked destination was not replaced" }
    if ([System.IO.File]::ReadAllText($theirs) -ne "THE USER'S OWN RULES`n") { throw "Test 52: install.ps1 wrote through the symlinked destination" }
}
else { Write-Host "  - the .link-target part is not run: it needs a symlinked destination" -ForegroundColor Yellow }

# The CLI on Windows: its backup is a copy with COPYFILE_EXCL, which fails with EPERM, not EEXIST,
# on a junction. A Date preload pins the clock, as lifecycle Test 49 does in the bash suite.
$cliDir52 = Join-Path $root52 'cli'
New-Item -ItemType Directory -Path (Join-Path $cliDir52 '.claude\rules') -Force | Out-Null
$clock52 = Join-Path $root52 'date.js'
[System.IO.File]::WriteAllText($clock52, "const RealDate = Date;`nconst PINNED = RealDate.UTC(2026, 9, 19, 5, 2, 0);`nglobal.Date = class extends RealDate {`n  constructor(...args) { if (args.length === 0) super(PINNED); else super(...args); }`n  static now() { return PINNED; }`n};`n", $utf8NoBom52)
$cliDest52 = Join-Path $cliDir52 '.claude\rules\security-qa.md'
[System.IO.File]::WriteAllText($cliDest52, "THE USER'S OWN RULES`n", $utf8NoBom52)
New-Plant52 "$cliDest52.qa-skills-backup-$stamp52" 'junction'
Set-Location -Path $cliDir52
$savedPreference52 = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
try { $outCli52 = node --require $clock52 "$repoDir\cli\qa-instinct.js" init --editor claude 2>&1 | Out-String; $exitCli52 = $LASTEXITCODE }
finally { $ErrorActionPreference = $savedPreference52; Set-Location -Path $repoDir }
Assert-Plant52 "$cliDest52.qa-skills-backup-$stamp52" 'junction' "CLI's backup"
if ($exitCli52 -ne 0) { throw "Test 52: the CLI exited $exitCli52 over a junction at its backup name. Output was: $outCli52" }
if (-not (Test-Path -LiteralPath "$cliDest52.qa-skills-backup-$stamp52-1") -or [System.IO.File]::ReadAllText("$cliDest52.qa-skills-backup-$stamp52-1") -ne "THE USER'S OWN RULES`n") { throw "Test 52: the CLI did not back up the user's file to the next name. Output was: $outCli52" }

# Remove the links themselves: Remove-Item -Recurse on Windows PowerShell 5.1 follows junctions.
foreach ($j in @(Get-ChildItem -LiteralPath $root52 -Recurse -Force | Where-Object { $_.LinkType })) {
    if ($j.PSIsContainer) { [System.IO.Directory]::Delete($j.FullName, $false) } else { [System.IO.File]::Delete($j.FullName) }
}
Remove-Item Function:\Get-Date
Write-Host "[OK] Test 52 passed successfully! Every planted name was passed over and nothing was written through it ($($kinds52 -join ', '))." -ForegroundColor Green
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 53: A file destination that is a junction to a folder is skipped as a directory, as
# install.sh skips it (conformance cases 078 and 079, which need a symlink and report "not run"
# where this machine may not create one; a junction needs no privilege). Nothing is written into
# the folder, the junction is neither backed up nor removed, nothing is recorded for it, and the
# rest installs: install.ps1 for Claude Code and Copilot, and the CLI here (plan 061 B2).
# powershell.exe -NonInteractive turns a confirmation prompt into an error instead of a hang.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 53: a file destination that is a junction to a folder is skipped as a directory..." -ForegroundColor Yellow

$root53 = Join-Path $sandboxDir 'junction-dest-53'
$utf8NoBom53 = New-Object System.Text.UTF8Encoding($false)
$junctions53 = @()
function New-JunctionDest53([string]$Project, [string]$Rel, [string]$Folder) {
    New-Item -ItemType Directory -Path $Folder -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $Folder 'mine.md'), "MY OWN NOTES`n", $utf8NoBom53)
    $link = Join-Path $Project $Rel
    New-Item -ItemType Directory -Path (Split-Path -Parent $link) -Force | Out-Null
    New-Item -ItemType Junction -Path $link -Target $Folder | Out-Null
    $script:junctions53 += $link
}
function Assert-JunctionDest53([string]$Project, [string]$Rel, [string]$Folder, [string]$Who, [string]$Out) {
    $link = Join-Path $Project $Rel
    $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if (-not $item -or -not $item.LinkType) { throw "Test 53: $Who removed or replaced the junction at $Rel. Output was: $Out" }
    if ([System.IO.File]::ReadAllText((Join-Path $Folder 'mine.md')) -ne "MY OWN NOTES`n") { throw "Test 53: $Who changed the user's file behind $Rel. Output was: $Out" }
    if (@(Get-ChildItem -LiteralPath $Folder -Force).Count -ne 1) { throw "Test 53: $Who wrote into the folder behind $Rel. Output was: $Out" }
    if (@(Get-ChildItem -LiteralPath (Split-Path -Parent $link) -Force -Filter "$(Split-Path -Leaf $link).qa-skills-backup-*").Count -ne 0) { throw "Test 53: $Who backed up $Rel. Output was: $Out" }
    $mf = Join-Path $Project '.qa-skills-manifest'
    if ((Test-Path -LiteralPath $mf) -and (@(Get-Content -LiteralPath $mf | Where-Object { $_ -like "*  $Rel" -or $_ -like ("*  " + ($Rel -replace '\\', '/')) }).Count -ne 0)) { throw "Test 53: $Who recorded $Rel. Output was: $Out" }
}
function Assert-Recorded53([string]$Project, [string]$Rel, [string]$Who, [string]$Out) {
    $mf = Join-Path $Project '.qa-skills-manifest'
    if (-not (Test-Path -LiteralPath $mf) -or @(Get-Content -LiteralPath $mf | Where-Object { $_ -like "*  $Rel" }).Count -ne 1) { throw "Test 53: $Who did not install and record $Rel. Output was: $Out" }
}

$savedPreference53 = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
try {
    $proj53 = Join-Path $root53 'ps1'
    New-JunctionDest53 $proj53 '.claude\commands\qa.md' (Join-Path $root53 'ps1-commands')
    New-JunctionDest53 $proj53 '.github\copilot-instructions.md' (Join-Path $root53 'ps1-copilot')
    Set-Location -Path $proj53
    $out53 = ''
    foreach ($ed in 'claude', 'copilot') {
        $out53 += powershell.exe -NonInteractive -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor $ed -NonInteractive -NoHooks 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { throw "Test 53: install.ps1 -Editor $ed exited $LASTEXITCODE. Output was: $out53" }
    }
    Set-Location -Path $repoDir
    Assert-JunctionDest53 $proj53 '.claude\commands\qa.md' (Join-Path $root53 'ps1-commands') 'install.ps1' $out53
    Assert-JunctionDest53 $proj53 '.github\copilot-instructions.md' (Join-Path $root53 'ps1-copilot') 'install.ps1' $out53
    Assert-Recorded53 $proj53 '.claude/rules/security-qa.md' 'install.ps1' $out53
    Assert-Recorded53 $proj53 '.github/skills/qa/SKILL.md' 'install.ps1' $out53
    if ($out53 -notmatch 'is a directory') { throw "Test 53: install.ps1 did not say the destination is a directory. Output was: $out53" }

    $cli53 = Join-Path $root53 'cli'
    New-JunctionDest53 $cli53 '.claude\commands\qa.md' (Join-Path $root53 'cli-commands')
    New-JunctionDest53 $cli53 '.github\copilot-instructions.md' (Join-Path $root53 'cli-copilot')
    Set-Location -Path $cli53
    $outCli53 = ''
    foreach ($ed in 'claude', 'copilot') {
        $outCli53 += node "$repoDir\cli\qa-instinct.js" init --editor $ed 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { throw "Test 53: the CLI's init --editor $ed exited $LASTEXITCODE. Output was: $outCli53" }
    }
    Set-Location -Path $repoDir
    Assert-JunctionDest53 $cli53 '.claude\commands\qa.md' (Join-Path $root53 'cli-commands') 'the CLI' $outCli53
    Assert-JunctionDest53 $cli53 '.github\copilot-instructions.md' (Join-Path $root53 'cli-copilot') 'the CLI' $outCli53
    Assert-Recorded53 $cli53 '.claude/rules/security-qa.md' 'the CLI' $outCli53
    Assert-Recorded53 $cli53 '.github/skills/qa/SKILL.md' 'the CLI' $outCli53
    if ($outCli53 -notmatch 'is a directory') { throw "Test 53: the CLI did not say the destination is a directory. Output was: $outCli53" }
}
finally {
    $ErrorActionPreference = $savedPreference53
    Set-Location -Path $repoDir
    # Remove the junctions themselves: Remove-Item -Recurse on Windows PowerShell 5.1 follows them.
    foreach ($j in $junctions53) { if (Test-Path -LiteralPath $j) { [System.IO.Directory]::Delete($j, $false) } }
}
Write-Host "[OK] Test 53 passed successfully! A junction at a file destination was skipped as a directory, and the rest installed." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 54: A global uninstall removes only the hook file, never the hooks folder: not the user's
# own core.hooksPath folder, and not an empty ~/.git-templates/hooks or ~/.git-templates this run
# did not create, as install.sh's purge_git_hook (plan 061 S1). Here nothing was registered
# (-NoHooks), so the run removes nothing at all.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 54: a global uninstall keeps the user's empty hooks folders..." -ForegroundColor Yellow

function Invoke-Global54([string]$HomeDir, [string[]]$Extra) {
    $savedProfile = $env:USERPROFILE; $savedHome = $env:HOME; $savedGit = $env:GIT_CONFIG_GLOBAL
    $env:USERPROFILE = $HomeDir; $env:HOME = $HomeDir; $env:GIT_CONFIG_GLOBAL = (Join-Path $HomeDir '.gitconfig')
    try {
        $out = powershell.exe -NonInteractive -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target global -Editor claude -NonInteractive -NoHooks @Extra 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { throw "Test 54: install.ps1 $($Extra -join ' ') exited $LASTEXITCODE. Output was: $out" }
        return $out
    }
    finally { $env:USERPROFILE = $savedProfile; $env:HOME = $savedHome; $env:GIT_CONFIG_GLOBAL = $savedGit }
}

# core.hooksPath names the user's own empty folder.
$home54a = Join-Path $sandboxDir 'hooks-home-54a'
New-Item -ItemType Directory -Path (Join-Path $home54a '.githooks') -Force | Out-Null
$savedGit54 = $env:GIT_CONFIG_GLOBAL; $env:GIT_CONFIG_GLOBAL = (Join-Path $home54a '.gitconfig')
try { git config --global core.hooksPath '~/.githooks' } finally { $env:GIT_CONFIG_GLOBAL = $savedGit54 }
$out54a = Invoke-Global54 $home54a @()
$out54a += Invoke-Global54 $home54a @('-Uninstall')
if (-not (Test-Path -LiteralPath (Join-Path $home54a '.githooks') -PathType Container)) { throw "Test 54: install.ps1 removed the user's empty core.hooksPath folder. Output was: $out54a" }

# No core.hooksPath: the user's empty ~/.git-templates/hooks, and ~/.git-templates holding only it.
$home54b = Join-Path $sandboxDir 'hooks-home-54b'
New-Item -ItemType Directory -Path (Join-Path $home54b '.git-templates\hooks') -Force | Out-Null
$out54b = Invoke-Global54 $home54b @()
$out54b += Invoke-Global54 $home54b @('-Uninstall')
if (-not (Test-Path -LiteralPath (Join-Path $home54b '.git-templates\hooks') -PathType Container)) { throw "Test 54: install.ps1 removed the user's empty ~/.git-templates/hooks. Output was: $out54b" }
Write-Host "[OK] Test 54 passed successfully! A global uninstall removed no hooks folder it did not empty." -ForegroundColor Green
Set-Location -Path $repoDir

# ---------------------------------------------------------------------------
# Test 55: Under WSL (WSL_DISTRO_NAME set), an Antigravity install says how to open the folder in
# a WSL window, in install.sh's and the CLI's words; without it, nothing (plan 062, lifecycle
# Test 70 in bash)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 55: an Antigravity install under WSL names the command that opens a WSL window..."
$tip55 = 'in WSL, open the folder in a WSL window: antigravity-ide --remote wsl+TestDistro'
$home55 = Join-Path $sandboxDir 'wsl-tip-home'
$dir55 = Join-Path $sandboxDir 'wsl-tip-project'
New-Item -ItemType Directory -Path $home55, $dir55 -Force | Out-Null
function Invoke-Antigravity55([string]$Scope, [string]$Distro) {
    $saved = @($env:USERPROFILE, $env:HOME, $env:WSL_DISTRO_NAME)
    $env:USERPROFILE = $home55; $env:HOME = $home55; $env:WSL_DISTRO_NAME = $Distro
    try {
        $out = powershell.exe -NonInteractive -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target $Scope -Editor antigravity -NonInteractive -NoHooks 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { throw "Test 55: install.ps1 -Target $Scope exited $LASTEXITCODE. Output was: $out" }
        return $out
    }
    finally { $env:USERPROFILE = $saved[0]; $env:HOME = $saved[1]; $env:WSL_DISTRO_NAME = $saved[2] }
}
Set-Location -Path $dir55
$out55 = Invoke-Antigravity55 'project' 'TestDistro'
$want55 = "$tip55 $((Get-Location).ProviderPath)"
if (-not $out55.Contains($want55)) { throw "Test 55: a project install under WSL did not print: $want55. Output was: $out55" }
$out55 = Invoke-Antigravity55 'global' 'TestDistro'
if (-not $out55.Contains("$tip55 <folder>")) { throw "Test 55: a global install under WSL did not print: $tip55 <folder>. Output was: $out55" }
$out55 = Invoke-Antigravity55 'project' ''
if ($out55.Contains('in WSL, open the folder')) { throw "Test 55: install.ps1 printed the WSL tip outside WSL. Output was: $out55" }
Write-Host "[OK] Test 55 passed successfully! Under WSL, install.ps1 names the command that opens a WSL window; outside WSL it does not." -ForegroundColor Green
Set-Location -Path $repoDir

# -----------------------------------------------------------------------------
# TEST 56: install.ps1 recognises, replaces and removes every git hook any release wrote
# (plan 064 item 1; lifecycle Test 72 in bash). tests/fixtures/git-hooks/ holds the bytes each
# release's installers wrote (extract.sh there lists the tags). A project hook is ours by the
# marker alone, so install replaces it and uninstall removes it, with or without a final line
# break; a global hook that already names validate-tc-format.sh is left byte for byte by install,
# a fresh one is removed by uninstall, and an appended block is cut out leaving exactly the
# user's lines.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 56: install.ps1 handles every git hook a release wrote..." -ForegroundColor Yellow

$hooks56 = Join-Path $repoDir 'tests\fixtures\git-hooks'
$work56 = Join-Path $sandboxDir 'hook-fixtures'
if (Test-Path -LiteralPath $work56) { Remove-Item -LiteralPath $work56 -Recurse -Force }
New-Item -ItemType Directory -Path $work56 -Force | Out-Null

function Get-Sha56([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }

# Runs install.ps1 against its own throwaway home so no earlier test's global state leaks in.
function Invoke-Global56 {
    param([string]$HomeDir, [bool]$Uninstall, [string]$Fixture)
    $savedProfile = $env:USERPROFILE; $savedHome = $env:HOME; $savedGit = $env:GIT_CONFIG_GLOBAL
    $env:USERPROFILE = $HomeDir; $env:HOME = $HomeDir; $env:GIT_CONFIG_GLOBAL = (Join-Path $HomeDir '.gitconfig')
    try {
        if ($Uninstall) {
            $out = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target global -Editor claude -NonInteractive -Uninstall 2>&1 | Out-String
        }
        else {
            $out = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target global -Editor claude -NonInteractive 2>&1 | Out-String
        }
        if ($LASTEXITCODE -ne 0) { throw "Test 56: install.ps1 (uninstall=$Uninstall) over $Fixture failed with exit status $LASTEXITCODE. Output was: $out" }
    }
    finally {
        $env:USERPROFILE = $savedProfile; $env:HOME = $savedHome; $env:GIT_CONFIG_GLOBAL = $savedGit
    }
}

# 56a: project hooks. A repository without the global template hook an earlier test may have
# configured, so the only pre-commit hook present is the one seeded. The replacement is the current
# text with or without its final line break: whether install.ps1 ends it with one is plan 064
# item 3, not this test.
$current56 = @((Get-Sha56 (Join-Path $hooks56 'project\current.lf.nl')), (Get-Sha56 (Join-Path $hooks56 'project\current.lf.nonl')))
foreach ($fixture56 in (Get-ChildItem -LiteralPath (Join-Path $hooks56 'project') -File)) {
    Set-Location -Path $work56
    $repo56 = Join-Path $work56 'repo'
    if (Test-Path -LiteralPath $repo56) { Remove-Item -LiteralPath $repo56 -Recurse -Force }
    New-Item -ItemType Directory -Path $repo56 -Force | Out-Null
    git -C $repo56 -c "init.templateDir=" init -q -b main
    $hookDir56 = Join-Path $repo56 '.git\hooks'
    New-Item -ItemType Directory -Path $hookDir56 -Force | Out-Null
    $hook56 = Join-Path $hookDir56 'pre-commit'
    Copy-Item -LiteralPath $fixture56.FullName -Destination $hook56
    Set-Location -Path $repo56
    $out56 = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Test 56: install.ps1 over project\$($fixture56.Name) failed with exit status $LASTEXITCODE. Output was: $out56" }
    if ($current56 -notcontains (Get-Sha56 $hook56)) { throw "Test 56: install did not replace project\$($fixture56.Name) with the current hook. Output was: $out56" }
    Copy-Item -LiteralPath $fixture56.FullName -Destination $hook56 -Force
    $out56 = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive -Uninstall 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Test 56: install.ps1 -Uninstall over project\$($fixture56.Name) failed with exit status $LASTEXITCODE. Output was: $out56" }
    if (Test-Path -LiteralPath $hook56) { throw "Test 56: uninstall left project\$($fixture56.Name) behind" }
}

# 56b: global hooks written fresh by a release: install leaves them byte for byte, uninstall
# removes the file. Each in its own throwaway home.
Set-Location -Path $work56
foreach ($fixture56 in (Get-ChildItem -LiteralPath (Join-Path $hooks56 'global-fresh') -File)) {
    $home56 = Join-Path $work56 'home'
    if (Test-Path -LiteralPath $home56) { Remove-Item -LiteralPath $home56 -Recurse -Force }
    New-Item -ItemType Directory -Path (Join-Path $home56 '.git-templates\hooks') -Force | Out-Null
    $hook56 = Join-Path $home56 '.git-templates\hooks\pre-commit'
    Copy-Item -LiteralPath $fixture56.FullName -Destination $hook56
    Invoke-Global56 $home56 $false "global-fresh\$($fixture56.Name)"
    if ((Get-Sha56 $hook56) -ne (Get-Sha56 $fixture56.FullName)) { throw "Test 56: global install changed global-fresh\$($fixture56.Name)" }
    Invoke-Global56 $home56 $true "global-fresh\$($fixture56.Name)"
    if (Test-Path -LiteralPath $hook56) { throw "Test 56: global uninstall left global-fresh\$($fixture56.Name) behind" }
}

# 56c: global blocks appended to a user's hook: uninstall leaves exactly the .expected bytes.
foreach ($fixture56 in (Get-ChildItem -LiteralPath (Join-Path $hooks56 'global-appended') -File | Where-Object { $_.Extension -ne '.expected' })) {
    $home56 = Join-Path $work56 'home'
    if (Test-Path -LiteralPath $home56) { Remove-Item -LiteralPath $home56 -Recurse -Force }
    New-Item -ItemType Directory -Path (Join-Path $home56 '.git-templates\hooks') -Force | Out-Null
    $hook56 = Join-Path $home56 '.git-templates\hooks\pre-commit'
    Copy-Item -LiteralPath $fixture56.FullName -Destination $hook56
    Invoke-Global56 $home56 $true "global-appended\$($fixture56.Name)"
    if (-not (Test-Path -LiteralPath $hook56)) { throw "Test 56: global uninstall removed global-appended\$($fixture56.Name) although the user's lines remain" }
    if ((Get-Sha56 $hook56) -ne (Get-Sha56 "$($fixture56.FullName).expected")) { throw "Test 56: global uninstall of global-appended\$($fixture56.Name) did not leave exactly the user's lines" }
}

Set-Location -Path $repoDir
Write-Host "[OK] Test 56 passed successfully! install.ps1 replaces, removes and cleans every git hook text a release wrote, with and without a final line break." -ForegroundColor Green

# -----------------------------------------------------------------------------
# TEST 57: install.ps1 writes exactly the hook bytes in tests\fixtures\git-hooks\current\
# (plan 064 item 2b; lifecycle Test 73 in bash). The fixtures are what install.sh writes. The text
# of the hooks is compared in the sources by tests/test-hook-parity.sh; the final newline is a
# property of how each installer writes, which only a run shows. A PowerShell here-string has no
# final line break, so the project hook is the byte this test finds missing until plan 064 item 3.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Running Test 57: install.ps1 writes the same git hook bytes as the fixtures..." -ForegroundColor Yellow

$current57 = Join-Path $repoDir 'tests\fixtures\git-hooks\current'
$work57 = Join-Path $sandboxDir 'hook-bytes'
if (Test-Path -LiteralPath $work57) { Remove-Item -LiteralPath $work57 -Recurse -Force }
New-Item -ItemType Directory -Path $work57 -Force | Out-Null

function Get-Sha57([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }

$repo57 = Join-Path $work57 'repo'
New-Item -ItemType Directory -Path $repo57 -Force | Out-Null
git -C $repo57 -c "init.templateDir=" init -q -b main
Set-Location -Path $repo57
$out57 = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target project -Editor claude -NonInteractive 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw "Test 57: project install failed with exit status $LASTEXITCODE. Output was: $out57" }
$projectHook57 = Join-Path $repo57 '.git\hooks\pre-commit'
# All three hooks are compared before failing, so one run shows every difference.
$mismatch57 = @()
$projectExpected57 = Join-Path $current57 'project'
if ((Get-Sha57 $projectHook57) -ne (Get-Sha57 $projectExpected57)) { $mismatch57 += "the project hook differs from current\project ($((Get-Item -LiteralPath $projectHook57).Length) bytes, expected $((Get-Item -LiteralPath $projectExpected57).Length))" }

Set-Location -Path $work57
foreach ($case57 in @('fresh', 'appended')) {
    $home57 = Join-Path $work57 "home-$case57"
    $hookDir57 = Join-Path $home57 '.git-templates\hooks'
    New-Item -ItemType Directory -Path $hookDir57 -Force | Out-Null
    $hook57 = Join-Path $hookDir57 'pre-commit'
    if ($case57 -eq 'appended') { [System.IO.File]::WriteAllText($hook57, "#!/bin/sh`necho before`n", (New-Object System.Text.UTF8Encoding($false))) }
    $savedProfile = $env:USERPROFILE; $savedHome = $env:HOME; $savedGit = $env:GIT_CONFIG_GLOBAL
    $env:USERPROFILE = $home57; $env:HOME = $home57; $env:GIT_CONFIG_GLOBAL = (Join-Path $home57 '.gitconfig')
    try {
        $out57 = powershell.exe -ExecutionPolicy Bypass -File "$repoDir\install.ps1" -Target global -Editor claude -NonInteractive 2>&1 | Out-String
        $exit57 = $LASTEXITCODE
    }
    finally {
        $env:USERPROFILE = $savedProfile; $env:HOME = $savedHome; $env:GIT_CONFIG_GLOBAL = $savedGit
    }
    if ($exit57 -ne 0) { throw "Test 57: global install ($case57) failed with exit status $exit57. Output was: $out57" }
    $expected57 = Join-Path $current57 "global-$case57"
    if ((Get-Sha57 $hook57) -ne (Get-Sha57 $expected57)) { $mismatch57 += "the $case57 global hook differs from current\global-$case57" }
}
if ($mismatch57.Count -gt 0) { throw "Test 57: $($mismatch57 -join '; ')" }

Set-Location -Path $repoDir
Write-Host "[OK] Test 57 passed successfully! install.ps1 writes the project hook, a fresh global hook and an appended global block byte for byte as the fixtures." -ForegroundColor Green

# Clean up sandbox
Set-Location -Path $repoDir
Remove-Item -Path $sandboxDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "ALL POWERSHELL INTEGRATION TESTS PASSED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Test 41 ends on a deliberately failed git commit; without this, the CI step wrapper
# (`exit $LASTEXITCODE`) would report the whole suite as failed.
exit 0

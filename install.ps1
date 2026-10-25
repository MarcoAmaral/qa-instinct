#Requires -Version 5.1

<#
.SYNOPSIS
    QA Instinct - Windows PowerShell Installer

.DESCRIPTION
    Installs QA Instinct (ISTQB CTFL v4.0 QA skills: test design, BDD, Playwright, Vitest)
    to project-level and/or global Claude Code commands directory, with optional
    multi-editor support.

.PARAMETER Target
    Installation target: 'project', 'global', or 'both'. Skips the target menu when provided.

.PARAMETER Editor
    Editor target: 'claude', 'cursor', 'windsurf', 'copilot', 'cline', 'antigravity', or 'all'.
    Skips the editor menu when provided. Default: 'claude'.

.PARAMETER NonInteractive
    Run without prompts. Requires -Target. Uses defaults for any unspecified option.
    Overwrites existing files, skips git operations.

.EXAMPLE
    .\install.ps1
    # Interactive installation with menus

.EXAMPLE
    .\install.ps1 -Target project -Editor claude
    # Install to project for Claude Code, interactive prompts for overwrite/git

.EXAMPLE
    .\install.ps1 -Target both -Editor all -NonInteractive
    # Fully automated install to both scopes for all editors
#>

[CmdletBinding()]
param(
    [ValidateSet('project', 'global', 'both')]
    [string]$Target,

    [ValidateSet('claude', 'cursor', 'windsurf', 'copilot', 'cline', 'antigravity', 'all')]
    [string]$Editor = 'claude',

    [switch]$NonInteractive,

    [switch]$NoHooks,

    [switch]$Update,

    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

# Windows PowerShell 5.1 cannot start in a folder whose name holds [ or ]: it reads the name as a
# wildcard, fails to enter it and starts in $PSHOME, so $PWD would name the wrong project. The
# process's own working directory is still right, so go back to it, literally. Only on that
# exact symptom: in an open session the process directory can lag behind a cd on purpose.
$startDir = [System.IO.Directory]::GetCurrentDirectory()
if (($PWD.Path -eq $PSHOME) -and ($startDir -ne $PSHOME) -and ($startDir -match '[\[\]]')) {
    Set-Location -LiteralPath $startDir
}

# ─── Helper Functions ────────────────────────────────────────────────────────

function Write-Header {
    Write-Host ""
    Write-Host ([char]0x2554 + ([string][char]0x2550 * 52) + [char]0x2557) -ForegroundColor Cyan
    Write-Host ([char]0x2551 + "   QA Instinct - Installation Script                " + [char]0x2551) -ForegroundColor Cyan
    Write-Host ([char]0x2551 + "   QA skills for AI editors                       " + [char]0x2551) -ForegroundColor Cyan
    Write-Host ([char]0x255A + ([string][char]0x2550 * 52) + [char]0x255D) -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success  { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Info     { param([string]$Message) Write-Host "[..] $Message" -ForegroundColor Yellow }
function Write-Err      { param([string]$Message) Write-Host "[!!] $Message" -ForegroundColor Red }
function Write-FilePath { param([string]$Message) Write-Host "     $Message" -ForegroundColor Cyan }

function Read-UserChoice {
    param(
        [string]$Prompt,
        [string[]]$ValidChoices,
        [string]$Default
    )

    if ($NonInteractive) {
        return $Default
    }

    while ($true) {
        $answer = Read-Host $Prompt
        if ([string]::IsNullOrWhiteSpace($answer) -and $Default) {
            return $Default
        }
        if ($ValidChoices -contains $answer) {
            return $answer
        }
        Write-Err "Invalid choice '$answer'. Valid options: $($ValidChoices -join ', ')"
    }
}

function Read-YesNo {
    param(
        [string]$Prompt,
        [string]$Default = 'n'
    )

    if ($NonInteractive) {
        return $Default
    }

    while ($true) {
        $answer = Read-Host "$Prompt (y/n)"
        if ([string]::IsNullOrWhiteSpace($answer)) {
            return $Default
        }
        if ($answer -match '^[yYnN]$') {
            return $answer.ToLower()
        }
        Write-Err "Please enter 'y' or 'n'."
    }
}

function Get-QAVersion {
    param([string]$FilePath)

    if (-not (Test-Path -LiteralPath $FilePath)) {
        return $null
    }

    try {
        $content = Get-Content -LiteralPath $FilePath -Raw -ErrorAction SilentlyContinue
        if ($content -match 'Version:\s*(\d+\.\d+\.\d+)') {
            return $Matches[1]
        }
        # Fallback: look for semver pattern near top of file
        $lines = Get-Content -LiteralPath $FilePath -TotalCount 30 -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ($line -match '(\d+\.\d+\.\d+)') {
                return $Matches[1]
            }
        }
    }
    catch {
        # Silently ignore read errors
    }
    return 'unknown'
}

function Test-VersionConflict {
    param(
        [string]$TargetPath,
        [string]$SourcePath
    )

    if ($global:OPERATION -eq 'update') {
        return $true
    }

    # A folder at the target is not a file to compare or overwrite: Install-File skips it.
    if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        return $true  # No conflict, proceed
    }

    $existingVer = Get-QAVersion -FilePath $TargetPath
    $newVer      = Get-QAVersion -FilePath $SourcePath

    if (-not $existingVer) { $existingVer = 'unknown' }
    if (-not $newVer)      { $newVer = 'unknown' }

    Write-Info "Existing file found at:"
    Write-FilePath $TargetPath
    Write-Host "  Installed version : $existingVer"
    Write-Host "  Package version   : $newVer"

    if ($NonInteractive) {
        Write-Info "Non-interactive mode: overwriting existing file."
        return $true
    }

    $overwrite = Read-YesNo -Prompt "Overwrite?" -Default 'n'
    if ($overwrite -ne 'y') {
        Write-FilePath "Skipping $TargetPath - no changes made."
        return $false
    }

    return $true
}

function Check-AdapterExists {
    param([string]$AdapterPath)
    if (-not (Test-Path -LiteralPath $AdapterPath)) {
        Write-Err "Adapter not found at $AdapterPath"
        Write-Host "Run ./generate-adapters.sh first to generate the adapters." -ForegroundColor Yellow
        return $false
    }
    return $true
}

# ─── Shared editor -> install-folder mapping ─────────────────────────────────
# Single source of truth for every non-claude editor's install folders and display label - shared
# with install.sh and cli/qa-instinct.js. See .qa-skills-editor-map. Format: tab-separated
# "<editor>`t<project rules>`t<global rules>`t<project skills>`t<global skills>`t<label>", '-'
# where the editor has none (plan 047). The generated rule files of adapters\<editor>\rules\ go
# into the rules folder, and the one Agent Skills tree adapters\skills\ into the skills folder. A
# skills column may name several folders separated by ',' (Antigravity's App and IDE share one
# global folder, its CLI reads another; plan 058); the tree goes into each, in that order. An
# editor installs for a target only when it has a skills folder there. `claude` is not listed: it
# copies the raw .claude\ tree and is handled separately in Install-ForEditor / Uninstall-ForEditor.

$Script:EditorMapPath = Join-Path $PSScriptRoot '.qa-skills-editor-map'
$Script:EditorMapCache = $null

function Get-EditorMap {
    if ($null -eq $Script:EditorMapCache) {
        $Script:EditorMapCache = @{}
        $lines = Get-Content -LiteralPath $Script:EditorMapPath -Encoding UTF8
        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $parts = $line -split "`t"
            $Script:EditorMapCache[$parts[0]] = [PSCustomObject]@{
                ProjectRules  = $parts[1]
                GlobalRules   = $parts[2]
                ProjectSkills = $parts[3]
                GlobalSkills  = $parts[4]
                Label         = $parts[5]
            }
        }
    }
    return $Script:EditorMapCache
}

# Removes each now-empty ancestor directory between $Dir (a just-uninstalled file's
# parent dir) and $StopDir (BaseDir, exclusive), stopping at the first non-empty one.
# Reproduces, generically, the fixed-depth cleanup each editor's uninstall used to
# hand-write against its own hardcoded path.
function Remove-EmptyAncestors {
    param([string]$Dir, [string]$StopDir)
    while (($Dir -ne $StopDir) -and (Test-Path -LiteralPath $Dir)) {
        # A linked folder is the user's: rmdir in install.sh and the CLI fails on one, and
        # Remove-Item would delete the link itself (plan 033 item 1).
        if (Test-IsLink $Dir) { break }
        if ((Get-ChildItem -LiteralPath $Dir -Force).Count -ne 0) { break }
        Remove-Item -LiteralPath $Dir -Force
        $Dir = Split-Path -Parent $Dir
    }
}

# Uninstall prunes only after an actual removal (plan 047): the paths, relative to the base, of
# the files this run removed for the editor being uninstalled.
$script:UninstallRemovedRels = @()
# Base folder -> whether it had a manifest when this run first reached it (see Uninstall-ForEditor).
$script:UninstallHadManifest = @{}

# The marker line the project hook carries; uninstall and the "is this ours?" check match on it.
$Script:ProjectHookMarker = 'Pre-commit hook to validate test cases in qa-skills'

# Runs git quietly and returns its exit code and first line of output. Under
# $ErrorActionPreference = 'Stop', Windows PowerShell 5.1 turns native stderr into a
# terminating error, so the preference is relaxed for the call.
function Invoke-GitQuiet {
    param([string[]]$GitArgs)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & git @GitArgs 2>$null
        $code = $LASTEXITCODE
    }
    catch {
        return [pscustomobject]@{ Code = 1; Out = '' }
    }
    finally {
        $ErrorActionPreference = $previous
    }
    return [pscustomobject]@{ Code = $code; Out = ("$(@($out)[0])").Trim() }
}

# Returns the hooks directory of the git repository rooted at $BaseDir, or $null when
# $BaseDir is not the root of one. Asking git (rather than assuming <BaseDir>\.git\hooks)
# handles a .git that is a file, as in a worktree or submodule.
function Get-ProjectHooksDir {
    param([string]$BaseDir)
    if (-not (Test-Path -LiteralPath (Join-Path $BaseDir '.git'))) { return $null }
    $r = Invoke-GitQuiet @('-C', $BaseDir, 'rev-parse', '--git-path', 'hooks')
    if (($r.Code -ne 0) -or (-not $r.Out)) { return $null }
    if ([System.IO.Path]::IsPathRooted($r.Out)) { return $r.Out }
    return (Join-Path $BaseDir $r.Out)
}

# A path is a link when its reparse tag is a symbolic link's or a junction's (mount point). The
# reparse-point attribute alone is not enough: OneDrive's Files-On-Demand sets it, with a cloud
# tag, on every folder it syncs, and those are real folders. Both the attributes and the tag are
# read from the path itself, never from what it points at, so a link whose target is missing is
# still recognised (Windows PowerShell 5.1's Get-Item may not find a dangling link).
function Test-IsLink {
    param([string]$Path)
    try { $attributes = [System.IO.File]::GetAttributes($Path) }
    catch { return $false }
    if (-not ($attributes -band [System.IO.FileAttributes]::ReparsePoint)) { return $false }
    # The method behind PowerShell's own LinkType property, given the path rather than an item:
    # 'SymbolicLink' or 'Junction' for those tags, nothing for any other. It opens the reparse point
    # itself. A tag it cannot read is treated as a link, the cautious answer this gave before.
    try {
        $type = [Microsoft.PowerShell.Commands.InternalSymbolicLinkLinkCodeMethods]::GetLinkType([psobject](New-Object System.IO.DirectoryInfo $Path))
        return (($type -eq 'SymbolicLink') -or ($type -eq 'Junction'))
    }
    catch { return $true }
}

# The global hook block is fenced by two exact marker lines so install and uninstall only ever
# touch their own lines of a hook that may be the user's. The old "Added by" line stays inside
# the block, and so does the old end line, so an older uninstaller still recognises it.
$Script:GlobalHookBegin = '# >>> bem-te-vi global pre-commit >>>'
$Script:GlobalHookEnd = '# <<< bem-te-vi global pre-commit <<<'
$Script:GlobalHookOldMarker = '# Added by qa-skills global installer'
$Script:GlobalHookOldEnd = '# GLOBAL_PRECOMMIT_APPEND'
$Script:GlobalHookFreshHeader = '# Global pre-commit hook to validate test cases in qa-skills'

# Matches a first line that is a sh or bash shebang, the only hooks a bash block can be appended to.
$Script:ShShebangPattern = '^#!\s*(/\S*/)?(env\s+)?(ba)?sh(\s|$)'

$Script:GlobalHookBlock = ((@'
# >>> bem-te-vi global pre-commit >>>
# Added by qa-skills global installer
GLOBAL_VALIDATOR="$HOME/.claude/hooks/validate-tc-format.sh"
if [ -f "$GLOBAL_VALIDATOR" ]; then
    # Validate every staged Markdown file, renamed ones included. The list is NUL-separated so
    # names with spaces, non-ASCII characters or glob characters arrive intact. bash does the
    # reading, so this block also works appended to a hook that runs under plain sh.
    git diff --cached --name-only -z --diff-filter=ACMR -- '*.md' | bash -c '
        while IFS= read -r -d "" FILE; do
            if grep -qE "^## TC-[A-Z0-9]+-[0-9]+:" "$FILE" 2>/dev/null; then
                if ! "$1" "$FILE"; then
                    printf "\033[0;31mError: Test case validation failed for %s. Commit aborted.\033[0m\n" "$FILE"
                    exit 1
                fi
            fi
        done' bash "$GLOBAL_VALIDATOR" || exit 1
fi
# GLOBAL_PRECOMMIT_APPEND
# <<< bem-te-vi global pre-commit <<<
'@) -replace "`r`n", "`n") + "`n"

# Returns $Content without the bem-te-vi block, or $null when the block cannot be located safely.
# The block is the lines between the two markers; for a hook written by an older release it runs
# from the old "Added by" line (or, for a fresh hook written by an older install.ps1, the header
# comment) to the first line that is exactly "fi", which is how the old block ends. One blank line
# right before the block, the separator the installer added, goes too. Splitting on LF only keeps
# every other line byte for byte, including any CR the user's own lines carry.
function Remove-GlobalHookBlock {
    param([string]$Content)

    $lines = $Content -split "`n"
    $trim = @($lines | ForEach-Object { $_.TrimEnd("`r") })

    $start = [array]::IndexOf($trim, $Script:GlobalHookBegin)
    $old = $false
    if ($start -lt 0) {
        $old = $true
        $start = [array]::IndexOf($trim, $Script:GlobalHookOldMarker)
    }
    if ($start -lt 0) { $start = [array]::IndexOf($trim, $Script:GlobalHookFreshHeader) }
    if ($start -lt 0) { return $null }

    $want = if ($old) { 'fi' } else { $Script:GlobalHookEnd }
    $end = -1
    for ($i = $start + 1; $i -lt $trim.Count; $i++) {
        if ($trim[$i] -eq $want) { $end = $i; break }
    }
    if ($end -lt 0) { return $null }
    if ($old -and (($end + 1) -lt $trim.Count) -and ($trim[$end + 1] -eq $Script:GlobalHookOldEnd)) { $end++ }
    if (($start -gt 0) -and ($trim[$start - 1] -eq '')) { $start-- }

    $kept = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if (($i -lt $start) -or ($i -gt $end)) { $kept += $lines[$i] }
    }
    return ($kept -join "`n")
}

function Register-GitHook {
    param(
        [string]$Scope,
        [string]$BaseDir
    )

    if ($NoHooks) {
        Write-Info "Skipping git hook registration (-NoHooks specified)."
        return
    }

    if ($Scope -eq 'project') {
        $hookDir = Get-ProjectHooksDir $BaseDir
        if (-not $hookDir) {
            Write-Info "Not a git repository, skipping project-level git hook."
            return
        }

        # A hook manager (husky, lefthook, ...) that sets core.hooksPath makes git ignore
        # .git/hooks entirely, so writing there would only pretend to register something.
        $hooksPathCfg = (Invoke-GitQuiet @('-C', $BaseDir, 'config', 'core.hooksPath')).Out
        if ($hooksPathCfg) {
            Write-Info "core.hooksPath is set ($hooksPathCfg); add the qa-instinct check to your hook manager yourself:"
            Write-FilePath 'bash .claude/hooks/validate-tc-format.sh <file>'
            return
        }

        $hookFile = Join-Path $hookDir 'pre-commit'
        # Never replace a hook we did not write: it is the user's (or their hook manager's).
        if (Test-Path -LiteralPath $hookFile) {
            $ours = $false
            if (-not (Test-IsLink $hookFile)) {
                $existingHook = Get-Content -LiteralPath $hookFile -Raw -ErrorAction SilentlyContinue
                $ours = [bool]($existingHook -and $existingHook.Contains($Script:ProjectHookMarker))
            }
            if (-not $ours) {
                Write-Info "Kept your existing pre-commit hook: $hookFile"
                Write-FilePath 'To validate test cases from it, run: bash .claude/hooks/validate-tc-format.sh <file>'
                return
            }
        }

        if (-not (Test-Path -LiteralPath $hookDir)) {
            New-Item -ItemType Directory -Path $hookDir -Force | Out-Null
        }

        $hookContent = @'
#!/usr/bin/env bash
# Pre-commit hook to validate test cases in qa-skills

SCRIPT_DIR="$(git rev-parse --show-toplevel)"
VALIDATOR="$SCRIPT_DIR/.claude/hooks/validate-tc-format.sh"

if [ -f "$VALIDATOR" ]; then
    # Validate every staged Markdown file, renamed ones included. The list is NUL-separated so
    # names with spaces, non-ASCII characters or glob characters arrive intact.
    git diff --cached --name-only -z --diff-filter=ACMR -- '*.md' |
    while IFS= read -r -d '' FILE; do
        # Only validate if the file contains test cases
        if grep -qE "^## TC-[A-Z0-9]+-[0-9]+:" "$SCRIPT_DIR/$FILE" 2>/dev/null; then
            if ! "$VALIDATOR" "$SCRIPT_DIR/$FILE"; then
                printf '\033[0;31mError: Test case validation failed for %s. Commit aborted.\033[0m\n' "$FILE"
                exit 1
            fi
        fi
    done
    # The loop ran in a subshell, so its failure only shows up here.
    [ "${PIPESTATUS[1]}" -eq 0 ] || exit 1
fi
'@
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($hookFile, $hookContent + "`n", $utf8NoBom)
        Write-Success "Registered project-level git pre-commit hook: $hookFile"
    }
    else {
        # Global registration
        $globalHooksDir = Join-Path $env:USERPROFILE '.git-templates\hooks'
        
        # Check if user has core.hooksPath set
        # Through Invoke-GitQuiet: with no git on PATH this reads as unset, as in install.sh, instead
        # of stopping the run.
        $existingHooksPath = (Invoke-GitQuiet @('config', '--global', 'core.hooksPath')).Out
        if ($existingHooksPath) {
            if ($existingHooksPath.StartsWith('~')) {
                $existingHooksPath = $existingHooksPath.Replace('~', $env:USERPROFILE)
            }
            $globalHooksDir = $existingHooksPath
        }

        $hookFile = Join-Path $globalHooksDir 'pre-commit'
        if (-not (Test-Path -LiteralPath $globalHooksDir)) {
            New-Item -ItemType Directory -Path $globalHooksDir -Force | Out-Null
        }

        if (Test-IsLink $hookFile) {
            Write-Info "Kept your existing global pre-commit hook (a symlink): $hookFile"
            Write-FilePath 'To validate test cases from it, run: bash ~/.claude/hooks/validate-tc-format.sh <file>'
        }
        elseif (Test-Path -LiteralPath $hookFile) {
            $existingContent = Get-Content -LiteralPath $hookFile -Raw
            if (-not $existingContent) { $existingContent = '' }
            if ($existingContent -notmatch 'validate-tc-format.sh') {
                $firstLine = ($existingContent -split "`n")[0]
                if ($firstLine -match $Script:ShShebangPattern) {
                    # Finish an unterminated last line, then add a blank separator and our block.
                    # Appended as LF with no BOM: bash rejects a "fi" line that ends in CR.
                    $separator = if ($existingContent.EndsWith("`n")) { "`n" } else { "`n`n" }
                    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                    [System.IO.File]::AppendAllText($hookFile, ($separator + $Script:GlobalHookBlock), $utf8NoBom)
                    Write-Success "Appended global pre-commit hook: $hookFile"
                }
                else {
                    Write-Info "Kept your existing global pre-commit hook (not a sh or bash script): $hookFile"
                    Write-FilePath 'To validate test cases from it, run: bash ~/.claude/hooks/validate-tc-format.sh <file>'
                }
            }
        }
        else {
            $globalHookContent = "#!/usr/bin/env bash`n$($Script:GlobalHookFreshHeader)`n`n" + $Script:GlobalHookBlock
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($hookFile, $globalHookContent, $utf8NoBom)
            Write-Success "Created global git pre-commit hook: $hookFile"
        }

        # Configure global git templates/hooks if core.hooksPath not set
        if (-not $existingHooksPath) {
            $existingTemplateDir = (Invoke-GitQuiet @('config', '--global', 'init.templateDir')).Out
            if (-not $existingTemplateDir) {
                git config --global init.templateDir "~/.git-templates" | Out-Null
                Write-Info "Configured git global init.templateDir to ~/.git-templates"
            }
            else {
                Write-Info "Kept your existing git init.templateDir: $existingTemplateDir"
            }
        }
    }
}

function Purge-GitHook {
    param(
        [string]$Scope,
        [string]$BaseDir
    )

    if ($Scope -eq 'project') {
        # The hooks directory git reports, and the plain .git\hooks an earlier release wrote to.
        $candidates = @(Get-ProjectHooksDir $BaseDir) + @(Join-Path (Join-Path $BaseDir '.git') 'hooks')
        foreach ($hookDir in ($candidates | Where-Object { $_ } | Select-Object -Unique)) {
            $hookFile = Join-Path $hookDir 'pre-commit'
            if ((Test-Path -LiteralPath $hookFile -PathType Leaf) -and (-not (Test-IsLink $hookFile))) {
                $content = Get-Content -LiteralPath $hookFile -Raw -ErrorAction SilentlyContinue
                if ($content -and $content.Contains($Script:ProjectHookMarker)) {
                    Remove-Item -LiteralPath $hookFile -Force
                    Write-Success "Purged project-level git pre-commit hook: $hookFile"
                }
            }
        }
    }
    else {
        # Global registration
        $globalHooksDir = Join-Path $env:USERPROFILE '.git-templates\hooks'
        # Through Invoke-GitQuiet: with no git on PATH this reads as unset, as in install.sh, instead
        # of stopping the run.
        $existingHooksPath = (Invoke-GitQuiet @('config', '--global', 'core.hooksPath')).Out
        if ($existingHooksPath) {
            if ($existingHooksPath.StartsWith('~')) {
                $existingHooksPath = $existingHooksPath.Replace('~', $env:USERPROFILE)
            }
            $globalHooksDir = $existingHooksPath
        }

        $hookFile = Join-Path $globalHooksDir 'pre-commit'
        if ((Test-Path -LiteralPath $hookFile -PathType Leaf) -and (-not (Test-IsLink $hookFile))) {
            $content = Get-Content -LiteralPath $hookFile -Raw
            if ($content -and $content.Contains('validate-tc-format.sh')) {
                # Strip only our own block, leaving every other line of the hook as it was.
                $cleanContent = Remove-GlobalHookBlock $content
                if ($null -eq $cleanContent) {
                    Write-Info "Kept global pre-commit hook - could not find the bem-te-vi block to remove: $hookFile"
                }
                else {
                    # Remove if nothing is left but the shebang and our own header comments
                    $remaining = @($cleanContent -split "`n" | Where-Object {
                            $t = $_.TrimEnd("`r")
                            ($t -notmatch '^\s*$') -and ($t -notmatch '^#!') -and
                            ($t -ne $Script:GlobalHookFreshHeader) -and ($t -ne $Script:GlobalHookOldEnd)
                        })
                    if ($remaining.Count -eq 0) {
                        Remove-Item -LiteralPath $hookFile -Force
                        Write-Success "Removed empty global hook file: $hookFile"
                    }
                    else {
                        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                        [System.IO.File]::WriteAllText($hookFile, $cleanContent, $utf8NoBom)
                        Write-Success "Cleaned global git pre-commit hook: $hookFile"
                    }
                }
            }
        }
        # Only the hook file is ever removed, never the folder that holds it, as install.sh's
        # purge_git_hook: core.hooksPath may name the user's own folder, and an empty
        # ~/.git-templates may be theirs too, or hold hidden files Get-ChildItem does not list
        # (plan 061 S1).
    }
}

# $Scope is 'Project' or 'Global', from -Target, never guessed from the folder: -Target project
# run from the home folder is a project install, as in install.sh and cli/qa-instinct.js.
function Uninstall-ForEditor {
    param(
        [string]$EditorName,
        [string]$BaseDir,
        [string]$Scope
    )

    $isGlobal = ($Scope -eq 'Global')
    $edRemovedStart = $global:UninstallRemovedCount
    $edKeptStart = $global:UninstallKeptCount
    # Whether a base had a manifest is decided once per run, before any editor is uninstalled from
    # it, as update and the CLI decide it: an earlier editor's uninstall can empty and delete the
    # manifest, and the next editor must not then take the base for a pre-manifest install.
    if (-not $script:UninstallHadManifest.ContainsKey($BaseDir)) {
        $script:UninstallHadManifest[$BaseDir] = Test-Path -LiteralPath (Get-ManifestPath $BaseDir)
    }

    switch ($EditorName) {
        'claude' {
            $targetDir = Join-Path $BaseDir '.claude'
            Write-Info "Removing Claude Code files..."
            
            # Remove only what was installed and is still unchanged (see the manifest helpers).
            # Files the project added or edited are kept, and reported.
            $script:UninstallRemovedRels = @()
            Uninstall-Recorded $BaseDir 'claude'
            if (-not $script:UninstallHadManifest[$BaseDir]) {
                # Installed before manifests existed: fall back to removing files whose content
                # still matches the package's current copy.
                $pkgClaude = Join-Path $PSScriptRoot '.claude'
                foreach ($folder in @('commands', 'rules', 'skills', 'agents', 'hooks')) {
                    $srcFolder = Join-Path $pkgClaude $folder
                    if (-not (Test-Path -LiteralPath $srcFolder)) { continue }
                    Get-ChildItem -LiteralPath $srcFolder -Recurse -File | ForEach-Object {
                        $rel = $_.FullName.Substring($pkgClaude.Length).TrimStart('\', '/')
                        Remove-IfMatches $BaseDir $_.FullName (Join-Path $targetDir $rel)
                    }
                }
            }
            
            # The folders this run emptied, up to the base and never inside a linked one: those of
            # each file it removed and, when it removed any, the package's five folders and
            # .claude. A folder it did not empty stays, even an empty one under .claude\skills\
            # (plan 061 L1, plan 047's rule for the other editors).
            if ($script:UninstallRemovedRels.Count -gt 0) {
                $rels = @($script:UninstallRemovedRels) + @('commands', 'rules', 'skills', 'agents', 'hooks' | ForEach-Object { ".claude/$_/-" })
                foreach ($rel in $rels) {
                    if (-not (Test-SafeManifestRel $rel) -or (Get-LinkedAncestor $BaseDir $rel)) { continue }
                    Remove-EmptyAncestors (Split-Path -Parent (Join-Path $BaseDir ($rel -replace '/', '\'))) $BaseDir
                }
            }

            Report-UninstallResult 'Claude Code' $Scope ($global:UninstallRemovedCount - $edRemovedStart) ($global:UninstallKeptCount - $edKeptStart)
            Purge-GitHook -Scope $Scope.ToLower() -BaseDir $BaseDir
        }
        default {
            # Every other editor: every file the manifest records for it, wherever it is (the
            # folders of plan 047 and the paths of earlier releases alike), then the folders those
            # removals left empty, never inside a linked one. With no manifest there is nothing
            # to remove: unlike Claude Code's, these destinations were never written without one,
            # and the package's older files here are not in .qa-skills-known-hashes, so a match
            # could only be a copy the user made (plan 047, review of #193).
            $entry = (Get-EditorMap)[$EditorName]
            if ($null -eq $entry) { return }
            $skillsRel = if ($isGlobal) { $entry.GlobalSkills } else { $entry.ProjectSkills }
            $script:UninstallRemovedRels = @()
            Uninstall-Recorded $BaseDir $EditorName
            # Get-EditorFiles returns its list as one object (return ,$pairs); @() would nest it.
            $pairs = Get-EditorFiles $EditorName $BaseDir $Scope
            # The folders this run emptied: those of each file it removed and, when it removed any,
            # the package's own folders of this editor. A folder of an editor with nothing removed
            # is never touched (plan 047).
            if ($script:UninstallRemovedRels.Count -gt 0) {
                $rels = @($script:UninstallRemovedRels)
                foreach ($pair in $pairs) { $rels += ($pair[1].Substring($BaseDir.Length).TrimStart('\', '/') -replace '\\', '/') }
                foreach ($rel in $rels) {
                    if (-not (Test-SafeManifestRel $rel) -or (Get-LinkedAncestor $BaseDir $rel)) { continue }
                    Remove-EmptyAncestors (Split-Path -Parent (Join-Path $BaseDir ($rel -replace '/', '\'))) $BaseDir
                }
            }
            $removed = $global:UninstallRemovedCount - $edRemovedStart
            $kept = $global:UninstallKeptCount - $edKeptStart
            # Never installed globally when the editor has no global skills folder (see
            # Install-ForEditor), so install.sh says nothing there and neither should this. But
            # install.ps1 up to 2.7.x did write these editors' project path into the home
            # directory; what the home manifest recorded there was removed above, still exactly as
            # installed, and is reported only if there was any.
            if ($skillsRel -ne '-' -or ($removed + $kept) -gt 0) {
                Report-UninstallResult $entry.Label $Scope $removed $kept
            }
        }
    }
}

# ─── Install manifest ────────────────────────────────────────────────────────
# Every file the installer writes is recorded in <base>\.qa-skills-manifest as
# "<sha256>  <editor>  <path relative to base>". Uninstall removes only files whose content
# still matches what was installed, so a project's own files are never destroyed - including
# ones whose names collide with the package's, and files this package shipped under a
# different name in an older version.
#
# The manifest is a portable format shared with install.sh: no BOM, LF line endings,
# forward-slash path separators, regardless of which platform wrote it. Recorded paths are
# normalized from Windows' backslash to forward slash before being written, and converted
# back to the platform's native separator when resolved to an actual file path.


function Get-ManifestPath { param([string]$BaseDir) Join-Path $BaseDir '.qa-skills-manifest' }

function Get-Sha256 {
    param([string]$Path)
    (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLower()
}

# The package's own file with CRLF line endings (a Windows checkout with core.autocrlf, a
# Windows editor) is still the package's file. A file on disk therefore *matches* a hash if its
# bytes hash to it, or its bytes with every carriage return removed do - the same rule in
# install.sh and cli/qa-instinct.js (plans/017). Hashes are still recorded as the raw bytes.
function Get-Sha256WithoutCR {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes((Get-Item -LiteralPath $Path -Force).FullName)
    $stream = New-Object System.IO.MemoryStream($bytes.Length)
    try {
        foreach ($b in $bytes) { if ($b -ne 13) { $stream.WriteByte($b) } }
        $stream.Position = 0
        return (Get-FileHash -Algorithm SHA256 -InputStream $stream).Hash.ToLower()
    } finally { $stream.Dispose() }
}

# A file that exists but may not be read (access denied): it can be neither hashed nor backed up,
# so nothing proves it is the package's (plan 053 I15). A missing file is not unreadable. Called on
# files only: opening a folder is refused the same way.
function Test-Unreadable {
    param([string]$Path)
    try { ([System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)).Dispose(); return $false }
    catch [System.UnauthorizedAccessException] { return $true }
    catch { return $false }
}

function Test-FileMatchesHash {
    param([string]$Path, [string]$Hash)
    if (-not $Hash) { return $false }
    if ((Get-Sha256 $Path) -eq $Hash) { return $true }
    return ((Get-Sha256WithoutCR $Path) -eq $Hash)
}

# Reads a manifest file's lines, tolerating a stray leading UTF-8 BOM, either CRLF or LF line
# endings, and backslash path separators from an older release - so manifests written by this
# script's own past versions, or by install.sh, parse identically. Get-Content already handles
# the BOM/CRLF/LF differences transparently; this just normalizes backslashes to forward
# slashes so entries recorded before this fix still match by path.
function Get-ManifestLines {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    @(Get-Content -LiteralPath $Path -Encoding UTF8) | ForEach-Object { $_ -replace '\\', '/' }
}

# Writes manifest lines with no BOM and LF line endings, matching install.sh's output exactly
# (Set-Content's default utf8 encoding on Windows PowerShell 5.1 adds a BOM and CRLF).
# Every manifest write goes to a new temp file created exclusively beside the manifest by
# Write-ExclusiveFile (CreateNew fails if anything, a planted link included, already has that
# name), then is renamed over it; a rename replaces a symlinked manifest instead of writing through
# it (plan 033 item 2). A name already taken is passed over for another, up to 20, as install.sh
# and the CLI do (plan 053 I10).
function Set-ManifestLines {
    param([string]$Path, [string[]]$Lines)
    $content = ''
    if ($Lines.Count -gt 0) { $content = ($Lines -join "`n") + "`n" }
    $bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($content)
    for ($n = 1; ; $n++) {
        $tmp = "$Path.tmp-$([guid]::NewGuid().ToString('N'))"
        if (Write-ExclusiveFile $tmp $bytes) { break }
        if ($n -ge 20) { throw "could not create a temporary file beside $Path" }
    }
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

# In-memory buffer of manifest entries pending a single, atomic write to disk - keyed by
# manifest path. Install-File calls Set-ManifestEntry once per installed file (there can be
# dozens), and previously each of those calls re-read and rewrote the entire manifest file on
# its own; an interrupted run could then leave a truncated-but-present manifest, which orphans
# every file installed after that point (the manifest exists, so the no-manifest fallback never
# runs). Buffering here means the whole install only touches the manifest once, via
# Save-ManifestBuffer's atomic temp-file-then-rename write.
$script:ManifestBuffer = @{}

function Get-ManifestBufferLines {
    param([string]$Path)
    if (-not $script:ManifestBuffer.ContainsKey($Path)) {
        $script:ManifestBuffer[$Path] = Get-ManifestLines $Path
    }
    return $script:ManifestBuffer[$Path]
}

function Get-ManifestEntry {
    param([string]$BaseDir, [string]$Editor, [string]$Rel)
    $mf = Get-ManifestPath $BaseDir
    foreach ($line in Get-ManifestBufferLines $mf) {
        $parts = $line -split '\s+', 3
        if ($parts.Count -eq 3 -and $parts[1] -eq $Editor -and $parts[2] -eq $Rel) { return $parts[0] }
    }
    return $null
}

function Set-ManifestEntry {
    param([string]$BaseDir, [string]$Editor, [string]$Rel, [string]$Hash)
    $mf = Get-ManifestPath $BaseDir
    # @(...) matters: a single-remaining-entry result would otherwise be treated as a scalar
    # string, and "+=" would then concatenate the next entry onto that line instead of adding
    # a new one.
    $kept = @(Get-ManifestBufferLines $mf | Where-Object {
        $parts = $_ -split '\s+', 3
        -not ($parts.Count -eq 3 -and $parts[1] -eq $Editor -and $parts[2] -eq $Rel)
    })
    $kept += "$Hash  $Editor  $Rel"
    $script:ManifestBuffer[$mf] = $kept
}

# Flushes BaseDir's buffered manifest entries to disk in a single write: write to a temp file in
# the same directory, then rename it over the real manifest (atomic on the same volume), so a
# process killed mid-install either leaves the manifest exactly as it was before this run, or
# fully reflects it - never a partial rewrite. No-op if nothing was buffered for BaseDir.
function Save-ManifestBuffer {
    param([string]$BaseDir)
    $mf = Get-ManifestPath $BaseDir
    if (-not $script:ManifestBuffer.ContainsKey($mf)) { return }
    # Update can prune the last entry: no entries left removes the manifest, as in the CLI.
    if (@($script:ManifestBuffer[$mf]).Count -eq 0) {
        if (Test-Path -LiteralPath $mf) { Remove-Item -LiteralPath $mf -Force }
    }
    else { Set-ManifestLines $mf $script:ManifestBuffer[$mf] }
    $script:ManifestBuffer.Remove($mf)
}

# Known-hash list: the SHA-256 of every file this package has ever shipped, across all tagged
# releases (see generate-known-hashes.sh and plans/011-release-hash-provenance.md). Lets the
# installer tell its own older file from the user's edit with certainty instead of guessing —
# loaded once per run, not once per file, since a typical run installs dozens of files.
$script:KnownHashes = $null

function Get-KnownHashes {
    if ($null -ne $script:KnownHashes) { return $script:KnownHashes }
    $script:KnownHashes = @{}
    $path = Join-Path $PSScriptRoot '.qa-skills-known-hashes'
    # Missing list (old checkout, trimmed package) is not an error: Test-KnownHash simply never
    # matches, and every differing destination falls back to today's back-up-and-warn behavior.
    if (-not (Test-Path -LiteralPath $path)) { return $script:KnownHashes }
    foreach ($line in (Get-Content -LiteralPath $path -Encoding UTF8)) {
        if ($line -match '^([0-9a-f]{64})\s') { $script:KnownHashes[$Matches[1]] = $true }
    }
    return $script:KnownHashes
}

function Test-KnownHash {
    param([string]$Hash)
    (Get-KnownHashes).ContainsKey($Hash)
}

function Backup-Destination {
    # If DestinationPath's content differs from both SourcePath and the manifest, returns an
    # object describing what to do:
    #   $null                       already matches src or the manifest - no action needed
    #   @{ Action = 'Adopted' }     hash matches a previous release's file - safe to overwrite,
    #                               no backup needed
    #   @{ Action = 'Backup'; Path = <path> }  the user's own content - backed up to <path>
    #                               (following symlinks, so a linked file's own content is
    #                               backed up, not the link)
    param([string]$BaseDir, [string]$Editor, [string]$Rel, [string]$DestinationPath, [string]$SourcePath)
    $srcHash = Get-Sha256 $SourcePath
    $recorded = Get-ManifestEntry $BaseDir $Editor $Rel
    # Raw bytes first; the carriage-return-free hash only when they match nothing (see
    # Test-FileMatchesHash).
    foreach ($pass in 'raw', 'without-cr') {
        if ($pass -eq 'raw') { $destHash = Get-Sha256 $DestinationPath }
        else { $destHash = Get-Sha256WithoutCR $DestinationPath }
        if ($destHash -eq $srcHash) { return $null }
        if ($destHash -eq $recorded) { return $null }
        if (Test-KnownHash $destHash) {
            return [pscustomobject]@{ Action = 'Adopted'; Path = $null }
        }
    }
    $suffix = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    $backup = "$DestinationPath.qa-skills-backup-$suffix"
    # Created exclusively, like the manifest's temp file: a name already taken, a link planted
    # there included, is never opened (CreateNew); the next number is tried instead.
    for ($n = 1; ; $n++) {
        if (Write-ExclusiveFile $backup ([System.IO.File]::ReadAllBytes((Get-Item -LiteralPath $DestinationPath -Force).FullName))) {
            return [pscustomobject]@{ Action = 'Backup'; Path = $backup }
        }
        if ($n -ge 100) { throw "could not back up $DestinationPath" }
        $backup = "$DestinationPath.qa-skills-backup-$suffix-$n"
    }
}

# Writes the bytes to a file that must not exist yet. Returns $false, writing nothing, when the
# name is taken, by a link planted there too: CreateNew never opens an existing name. A folder or a
# junction at the name fails with access denied rather than "exists", so any failure on a name
# that is there counts as taken (plan 053 I10).
function Write-ExclusiveFile {
    param([string]$Path, [byte[]]$Bytes)
    try { $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write) }
    catch {
        if ((Test-Path -LiteralPath $Path) -or (Test-IsLink $Path)) { return $false }
        throw
    }
    try { $stream.Write($Bytes, 0, $Bytes.Length) }
    finally { $stream.Dispose() }
    return $true
}

# A symlinked folder below the editor's top-level folder (.claude\rules, .agents\skills, ...) is
# never written or deleted through: after `qa-instinct link` those folders are the npm package's own
# files, and any other link leads outside the install tree. The top-level folder itself (.claude
# as a link into a dotfiles repository) is followed, as the editor follows it (plan 033 item 1).
# Returns the first such folder, relative to BaseDir with forward slashes, or $null.
function Get-LinkedAncestor {
    param([string]$BaseDir, [string]$Rel)
    $segments = @($Rel -split '/')
    for ($i = 2; $i -lt $segments.Count; $i++) {
        $prefix = $segments[0..($i - 1)] -join '/'
        if (Test-IsLink (Join-Path $BaseDir ($prefix -replace '/', [string][System.IO.Path]::DirectorySeparatorChar))) {
            return $prefix
        }
    }
    return $null
}

# Says once per link and run why the files under it were left alone.
$script:ReportedLinks = @{}
function Write-LinkedDir {
    param([string]$BaseDir, [string]$Dir, [string]$Action, [string]$Verb)
    if ($script:ReportedLinks.ContainsKey($Dir)) { return }
    $script:ReportedLinks[$Dir] = $true
    $hint = ''
    $item = Get-Item -LiteralPath (Join-Path $BaseDir ($Dir -replace '/', [string][System.IO.Path]::DirectorySeparatorChar)) -Force -ErrorAction SilentlyContinue
    $target = if ($item) { $item.Target } else { $null }
    if ($target -is [array]) { $target = $target[0] }
    # A junction made by Node (qa-instinct link on Windows without the symlink right) ends in '\'.
    if ($target) { $target = $target.TrimEnd([char]92, [char]47) }
    # A link `qa-instinct link` made points at some package's .claude\<same name>.
    $name = ($Dir -split '/')[-1]
    if ($target -and ('/' + ($target -replace '\\', '/')).EndsWith("/.claude/$name", [System.StringComparison]::OrdinalIgnoreCase)) {
        $hint = "; run 'qa-instinct unlink' first"
    }
    Write-Info "$Action $Dir/ - it is a symbolic link; nothing was $Verb through it$hint"
}

# Update reporting, the same three outcomes the CLI reports: files changed (refreshed, added,
# restored, adopted or removed), files already up to date, and files kept as they were.
$script:UpdateReport = $false
$script:UpdateChanged = 0
$script:UpdateUpToDate = 0
$script:UpdateKept = 0

# How many files Install-File has written in this run. An editor is reported installed only when
# this grew while its files were installed, as the CLI does (plan 053 I14).
$script:FilesWritten = 0

function Install-File {
    param([string]$BaseDir, [string]$Editor, [string]$SourcePath, [string]$DestinationPath)
    # The relative path is what the manifest records and uninstall resolves against BaseDir. A
    # destination outside BaseDir would record an entry that can never resolve, orphaning the file;
    # that is a bug in a call site, so refuse loudly, as install.sh and cli/qa-instinct.js do.
    $sep = [string][System.IO.Path]::DirectorySeparatorChar
    $fullBase = [System.IO.Path]::GetFullPath($BaseDir).TrimEnd('\', '/')
    $fullDest = [System.IO.Path]::GetFullPath($DestinationPath)
    if (-not $fullDest.StartsWith($fullBase + $sep, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "refusing to install $DestinationPath - it is not inside base $BaseDir, so it can never be recorded in the manifest."
    }
    $rel = $DestinationPath.Substring($BaseDir.Length).TrimStart('\', '/') -replace '\\', '/'

    # What update reports for this file: the hash recorded before, and the content before.
    $recordedBefore = $null; $beforeHash = $null
    if ($script:UpdateReport) {
        $recordedBefore = Get-ManifestEntry $BaseDir $Editor $rel
        if ((Test-Path -LiteralPath $DestinationPath -PathType Leaf) -and -not (Test-IsLink $DestinationPath) -and -not (Test-Unreadable $DestinationPath)) {
            $beforeHash = Get-Sha256 $DestinationPath
        }
    }

    $linked = Get-LinkedAncestor $BaseDir $rel
    if ($linked) {
        Write-LinkedDir $BaseDir $linked 'Skipped' 'written'
        if ($script:UpdateReport -and $recordedBefore) { $script:UpdateKept++ }
        return
    }

    $existingItem = Get-Item -LiteralPath $DestinationPath -Force -ErrorAction SilentlyContinue
    if ($existingItem -and $existingItem.PSIsContainer -and
        (-not $existingItem.LinkType -or (Test-Path -LiteralPath $DestinationPath -PathType Container))) {
        # A folder, or a link or junction to one, stands where the package's file goes (Cline
        # documents .clinerules\ as a folder). It is the user's: nothing is written into it,
        # backed up or recorded, and the rest installs, as install.sh's [ -d ] decides. A link to
        # a folder that is gone is a broken link, replaced below (plan 061 B2).
        Write-Info "Skipped $rel - it is a directory; nothing was written into it"
        if ($script:UpdateReport -and $recordedBefore) { $script:UpdateKept++ }
        return
    }
    if ($existingItem -and (Test-Path -LiteralPath $DestinationPath -PathType Leaf) -and (Test-Unreadable $DestinationPath)) {
        # Nothing proves it is the package's, and it cannot be backed up: left as it is, like a
        # read-only one (plan 053 I15).
        Write-Info "Skipped $rel - destination cannot be read (existing file left untouched)"
        if ($script:UpdateReport -and $recordedBefore) { $script:UpdateKept++ }
        return
    }
    if ($existingItem -and $existingItem.LinkType) {
        # DestinationPath is a symlink (or other reparse point): never write through it (that
        # would silently modify whatever file it points at, outside the install tree). Back up
        # the link target's content, then replace the link itself with the package's file.
        $linkTarget = $existingItem.Target
        if ($linkTarget -is [array]) { $linkTarget = $linkTarget[0] }

        $targetReadable = $true
        try { $null = Get-Content -LiteralPath $DestinationPath -TotalCount 1 -ErrorAction Stop }
        catch { $targetReadable = $false }

        if ($targetReadable) {
            $result = Backup-Destination $BaseDir $Editor $rel $DestinationPath $SourcePath
            if ($result -and $result.Action -eq 'Adopted') {
                Write-Info "$rel is a symlink to $linkTarget whose content matches an earlier release - updating (link target left untouched)"
            }
            elseif ($result -and $result.Action -eq 'Backup') {
                $targetBytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes("$linkTarget`n")
                if (-not (Write-ExclusiveFile "$($result.Path).link-target" $targetBytes)) {
                    Write-Info "Could not record the link target: $(Split-Path -Leaf $result.Path).link-target already exists"
                }
                Write-Info "$rel is a symlink to $linkTarget - its content was backed up to $(Split-Path -Leaf $result.Path) (link target left untouched)"
            }
        }
        else {
            Write-Info "$rel is a broken symlink to $linkTarget - replacing with the package file"
        }
        Remove-Item -LiteralPath $DestinationPath -Force
    }
    elseif (Test-Path -LiteralPath $DestinationPath) {
        if ($existingItem.IsReadOnly) {
            # A read-only destination is a deliberate signal not to overwrite it: skip this
            # file and keep installing the rest of the tree, rather than Copy-Item -Force
            # silently overwriting it.
            Write-Info "Skipped $rel - destination is read-only (existing file left untouched)"
            if ($script:UpdateReport) { $script:UpdateUpToDate++ }
            return
        }
        $result = Backup-Destination $BaseDir $Editor $rel $DestinationPath $SourcePath
        if ($result -and $result.Action -eq 'Adopted') {
            Write-Info "$rel already existed and matches an earlier release - updating to the current version"
        }
        elseif ($result -and $result.Action -eq 'Backup') {
            Write-Info "$rel already existed and differs - backed up to $(Split-Path -Leaf $result.Path)"
        }
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $DestinationPath) -Force | Out-Null
    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
    $script:FilesWritten++
    $afterHash = Get-Sha256 $DestinationPath
    Set-ManifestEntry $BaseDir $Editor $rel $afterHash
    if ($script:UpdateReport) {
        if ($recordedBefore -and $beforeHash -and ($beforeHash -eq $afterHash)) { $script:UpdateUpToDate++ }
        else {
            if (-not $recordedBefore) { Write-Success "Added $rel" }
            elseif (-not $beforeHash) { Write-Success "Restored $rel (was missing)" }
            else { Write-Success "Refreshed $rel" }
            $script:UpdateChanged++
        }
    }
    if ($env:QA_SKILLS_DEBUG) { Write-Info "recorded $rel in $(Get-ManifestPath $BaseDir)" }
}

# A manifest path must stay inside the base it was recorded under. The manifest sits at the
# project root and is committed into consuming repositories, so its contents are
# attacker-controllable: an entry such as "..\..\..\.ssh\config" would otherwise make
# uninstall delete a file outside the install tree. Install-File refuses to *record* such a
# path (it throws on a destination outside its base); this refuses to act on one.
function Test-SafeManifestRel {
    param([string]$Rel)
    if ([string]::IsNullOrWhiteSpace($Rel)) { return $false }
    if ($Rel -match '^[A-Za-z]:' -or $Rel.StartsWith('/') -or $Rel.StartsWith('\')) { return $false }
    foreach ($segment in ($Rel -split '[\\/]')) {
        if ($segment -eq '..' -or $segment -eq '') { return $false }
    }
    return $true
}

function Uninstall-Recorded {
    param([string]$BaseDir, [string]$Editor)
    $mf = Get-ManifestPath $BaseDir
    if (-not (Test-Path -LiteralPath $mf)) { return }
    $kept = @()
    foreach ($line in Get-ManifestLines $mf) {
        $parts = $line -split '\s+', 3
        if ($parts.Count -ne 3) { continue }
        if ($parts[1] -ne $Editor) { $kept += "$($parts[0])  $($parts[1])  $($parts[2])"; continue }
        if (-not (Test-SafeManifestRel $parts[2])) {
            Write-Host "  X Refusing $($parts[2]) - it points outside $BaseDir. The manifest may have been tampered with." -ForegroundColor Red
            $kept += "$($parts[0])  $($parts[1])  $($parts[2])"
            continue
        }
        $linked = Get-LinkedAncestor $BaseDir $parts[2]
        if ($linked) {
            # Kept, and still recorded: the file is not ours to delete through a link.
            Write-LinkedDir $BaseDir $linked 'Kept' 'deleted'
            $kept += "$($parts[0])  $($parts[1])  $($parts[2])"
            $global:UninstallKeptCount++
            continue
        }
        $relPath = $parts[2] -replace '/', [string][System.IO.Path]::DirectorySeparatorChar
        $file = Join-Path $BaseDir $relPath
        if (Test-Path -LiteralPath $file -PathType Container) {
            # A folder now stands at the recorded path: not the file this package installed. Kept,
            # and its entry dropped, as for any file kept because it changed.
            Write-Info "Kept $($parts[2]) - it is a directory"
            Write-OldLocationNote $BaseDir $Editor $parts[2]
            $global:UninstallKeptCount++
            continue
        }
        if (Test-Path -LiteralPath $file) {
            $fileItem = Get-Item -LiteralPath $file -Force
            if ($fileItem.IsReadOnly) {
                # Remove-Item -Force would delete a read-only file anyway; treat read-only the
                # same deliberate way on removal as on install and keep it.
                Write-Info "Kept $($parts[2]) - destination is read-only"
                $global:UninstallKeptCount++
            } elseif (Test-Unreadable $file) {
                Write-Info "Kept $($parts[2]) - destination cannot be read"
                $global:UninstallKeptCount++
            } elseif (Test-FileMatchesHash $file $parts[0]) {
                Remove-Item -LiteralPath $file -Force
                $global:UninstallRemovedCount++
                $script:UninstallRemovedRels += $parts[2]
            } else {
                Write-Info "Kept $($parts[2]) - changed since it was installed"
                Write-OldLocationNote $BaseDir $Editor $parts[2]
                $global:UninstallKeptCount++
            }
        }
    }
    if ($kept.Count -gt 0) { Set-ManifestLines $mf $kept }
    else { Remove-Item -LiteralPath $mf -Force }
}

function Remove-IfMatches {
    param([string]$BaseDir, [string]$SourcePath, [string]$DestinationPath)
    $linked = Get-LinkedAncestor $BaseDir ($DestinationPath.Substring($BaseDir.Length).TrimStart('\', '/') -replace '\\', '/')
    if ($linked) {
        Write-LinkedDir $BaseDir $linked 'Kept' 'deleted'
        if (Test-Path -LiteralPath $DestinationPath) { $global:UninstallKeptCount++ }
        return
    }
    if (-not (Test-Path -LiteralPath $DestinationPath)) { return }
    if (Test-Path -LiteralPath $DestinationPath -PathType Container) {
        Write-Info "Kept $DestinationPath - it is a directory"
        $global:UninstallKeptCount++
        return
    }
    if (Test-Unreadable $DestinationPath) {
        Write-Info "Kept $DestinationPath - destination cannot be read"
        $global:UninstallKeptCount++
        return
    }
    if ((Test-Path -LiteralPath $SourcePath) -and (Test-FileMatchesHash $DestinationPath (Get-Sha256 $SourcePath))) {
        Remove-Item -LiteralPath $DestinationPath -Force
        $global:UninstallRemovedCount++
        $script:UninstallRemovedRels += ($DestinationPath.Substring($BaseDir.Length).TrimStart('\', '/') -replace '\\', '/')
    } else {
        Write-Info "Kept $DestinationPath - not installed by this package, or changed since install"
        $global:UninstallKeptCount++
    }
}

# What a kept file at one of the locations plan 047 moved away from means for the editor, the same
# words as install.sh and cli/qa-instinct.js. The package never deletes it for the user:
# .clinerules\default-rules.md is not a path it recorded.
function Write-OldLocationNote {
    param([string]$BaseDir, [string]$Editor, [string]$Rel)
    switch -CaseSensitive ("${Editor}:$Rel") {
        'cline:.clinerules' {
            if (Test-Path -LiteralPath (Join-Path $BaseDir '.clinerules') -PathType Container) {
                Write-Host "    Cline moved the old rules to .clinerules/default-rules.md; delete that file if you no longer want them." -ForegroundColor Yellow
            }
        }
        'windsurf:.windsurfrules' {
            Write-Host "    Windsurf still loads .windsurfrules in every conversation; delete it if you no longer want it." -ForegroundColor Yellow
        }
        'antigravity:.gemini/antigravity/skills/qa/SKILL.md' {
            Write-Host "    The Antigravity IDE lists two qa skills while it stays; delete it if you no longer want it." -ForegroundColor Yellow
        }
    }
}

function Report-UninstallResult {
    param([string]$Label, [string]$Scope, [int]$Removed, [int]$Kept)
    if ($Kept -gt 0) {
        Write-Host "  ! Partially uninstalled ($Label - $Scope) - removed $Removed file(s), kept $Kept." -ForegroundColor Yellow
    } elseif ($Removed -eq 0) {
        Write-Host "  i Nothing to remove ($Label - $Scope) - not installed." -ForegroundColor Cyan
    } else {
        Write-Success "Uninstalled ($Label - $Scope)"
    }
}

# Every @(<package file>, <destination>) pair a non-claude editor's install writes for one scope
# (plan 047): each generated rule file of adapters\<editor>\rules\ into the rules folder, when the
# scope has one, and every file of adapters\skills\ below the skills folder, in byte order of
# their forward-slash paths, as install.sh and cli/qa-instinct.js list them. None when the scope has
# no skills folder. Each editor has its own folders, so uninstalling one never removes another's.
function Get-EditorFiles {
    param([string]$EditorName, [string]$BaseDir, [string]$Scope)
    $pairs = @()
    $entry = (Get-EditorMap)[$EditorName]
    if ($null -eq $entry) { return ,$pairs }
    $isGlobal = ($Scope -eq 'Global')
    $rulesRel = if ($isGlobal) { $entry.GlobalRules } else { $entry.ProjectRules }
    $skillsRel = if ($isGlobal) { $entry.GlobalSkills } else { $entry.ProjectSkills }
    if ((-not $skillsRel) -or ($skillsRel -eq '-')) { return ,$pairs }
    $adapters = Join-Path $PSScriptRoot 'adapters'
    $rulesSrc = Join-Path (Join-Path $adapters $EditorName) 'rules'
    if ($rulesRel -and ($rulesRel -ne '-') -and (Test-Path -LiteralPath $rulesSrc -PathType Container)) {
        $names = [string[]]@(Get-ChildItem -LiteralPath $rulesSrc -File -Force | Where-Object { -not $_.Name.StartsWith('.') } | ForEach-Object { $_.Name })
        [Array]::Sort($names, [System.StringComparer]::Ordinal)
        foreach ($name in $names) {
            $pairs += ,@((Join-Path $rulesSrc $name), (Join-Path (Join-Path $BaseDir ($rulesRel -replace '/', '\')) $name))
        }
    }
    $skillsSrc = Join-Path $adapters 'skills'
    if (Test-Path -LiteralPath $skillsSrc -PathType Container) {
        $rels = [string[]]@(Get-ChildItem -LiteralPath $skillsSrc -Recurse -File -Force |
            ForEach-Object { $_.FullName.Substring($skillsSrc.Length).TrimStart('\', '/') -replace '\\', '/' })
        [Array]::Sort($rels, [System.StringComparer]::Ordinal)
        foreach ($skillsOne in ($skillsRel -split ',')) {
            $skillsDest = Join-Path $BaseDir ($skillsOne -replace '/', '\')
            foreach ($rel in $rels) {
                $pairs += ,@((Join-Path $skillsSrc ($rel -replace '/', '\')), (Join-Path $skillsDest ($rel -replace '/', '\')))
            }
        }
    }
    return ,$pairs
}

function Install-ForEditor {
    <#
    .DESCRIPTION
        Installs the QA skill file for a specific editor at the given base directory.
    #>
    param(
        [string]$EditorName,
        [string]$SourcePath,
        [string]$BaseDir,
        [string]$Scope
    )

    $ScriptDir = Split-Path -Parent $SourcePath | Split-Path -Parent | Split-Path -Parent
    $writtenBefore = $script:FilesWritten
    $AdaptersDir = Join-Path $ScriptDir 'adapters'

    switch ($EditorName) {
        'claude' {
            $targetDir = Join-Path $BaseDir '.claude'
            $dest = Join-Path $targetDir 'commands\qa.md'
            if (Test-VersionConflict -TargetPath $dest -SourcePath $SourcePath) {
                $scriptRoot = Split-Path -Parent $SourcePath | Split-Path -Parent
                $folders = @('commands', 'rules', 'skills', 'agents', 'hooks')
                
                if (-not (Test-Path -LiteralPath $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }

                foreach ($folder in $folders) {
                    $srcFolder = Join-Path $scriptRoot $folder
                    $dstFolder = Join-Path $targetDir $folder
                    if (Test-Path -LiteralPath $srcFolder) {
                        # Copy file by file into the existing folder: overwrite the package's own
                        # files, never delete the project's. (Copy-Item -Recurse on a directory
                        # would nest it inside an existing destination directory of the same name.)
                        Get-ChildItem -LiteralPath $srcFolder -Recurse -File | ForEach-Object {
                            $rel  = $_.FullName.Substring($srcFolder.Length).TrimStart('\', '/')
                            Install-File $BaseDir 'claude' $_.FullName (Join-Path $dstFolder $rel)
                        }
                    }
                }
                
                # Every file skipped (linked folders, read-only files): nothing to report installed.
                if ($script:FilesWritten -gt $writtenBefore) {
                    Write-Success "Installed (Claude Code) - scaffolded rules, commands, skills, agents, and hooks:"
                    Write-FilePath $targetDir
                }

                # Register Git Hook. A hook that cannot be registered must not abort the install:
                # the files are already copied and the manifest is not yet saved.
                try {
                    Register-GitHook -Scope $Scope -BaseDir $BaseDir
                }
                catch {
                    Write-Info "Could not register the git hook: $($_.Exception.Message)"
                }
            }
        }
        default {
            # Every other editor: its generated rule files and the Agent Skills tree, installed in
            # the folders the shared mapping in .qa-skills-editor-map names (plan 047).
            $entry = (Get-EditorMap)[$EditorName]
            if ($null -eq $entry) { return }
            $isGlobal = ($Scope -eq 'Global')
            $rulesRel = if ($isGlobal) { $entry.GlobalRules } else { $entry.ProjectRules }
            $skillsRel = if ($isGlobal) { $entry.GlobalSkills } else { $entry.ProjectSkills }
            # An editor with no global skills folder is skipped on a global install, exactly as
            # install.sh and cli/qa-instinct.js do. Up to 2.7.x this fell back to the *project* path,
            # and a global install's base is the home directory, so it wrote e.g.
            # %USERPROFILE%\.clinerules. Uninstall-ForEditor cleans that debris up.
            if ($skillsRel -eq '-') {
                Write-Info "$($entry.Label) only supports project-level install - skipping global."
                return
            }
            $qaSkill = Join-Path $AdaptersDir 'skills\qa\SKILL.md'
            # The first skills folder stands for the install when asking about an existing one.
            $dest = Join-Path (Join-Path $BaseDir (($skillsRel -split ',')[0] -replace '/', '\')) 'qa\SKILL.md'
            if ((Check-AdapterExists $qaSkill) -and (Test-VersionConflict -TargetPath $dest -SourcePath $qaSkill)) {
                foreach ($pair in (Get-EditorFiles $EditorName $BaseDir $Scope)) {
                    Install-File $BaseDir $EditorName $pair[0] $pair[1]
                }
                $where = (($skillsRel -split ',') -join '/ and ') + '/'
                if ($rulesRel -ne '-') { $where = "$rulesRel/ and $where" }
                if ($script:FilesWritten -gt $writtenBefore) { Write-Success "Installed ($($entry.Label) - $Scope): $where" }
            }
        }
    }
}

# Every @(<package file>, <destination>) pair an install of one editor writes.
function Get-PackageFiles {
    param([string]$EditorName, [string]$BaseDir, [string]$Scope)
    $pairs = @()
    if ($EditorName -eq 'claude') {
        $pkgClaude = Join-Path $PSScriptRoot '.claude'
        foreach ($folder in @('commands', 'rules', 'skills', 'agents', 'hooks')) {
            $srcFolder = Join-Path $pkgClaude $folder
            if (-not (Test-Path -LiteralPath $srcFolder)) { continue }
            foreach ($f in (Get-ChildItem -LiteralPath $srcFolder -Recurse -File)) {
                $rel = $f.FullName.Substring($pkgClaude.Length).TrimStart('\', '/')
                $pairs += ,@($f.FullName, (Join-Path (Join-Path $BaseDir '.claude') $rel))
            }
        }
        return ,$pairs
    }
    return ,(Get-EditorFiles $EditorName $BaseDir $Scope)
}

# Update, the same in all three installers (plan 033 item 3). For an editor the manifest records:
# refresh its files and install the ones this release added (the install path), then remove each
# recorded file the package no longer ships if it is unchanged, keep and report it otherwise, and
# drop its entry either way. With no manifest at all, adopt only files whose hash a release
# shipped. An editor the manifest does not record is never installed.
function Update-ForEditor {
    param([string]$EditorName, [string]$SourcePath, [string]$BaseDir, [string]$Scope)
    $mf = Get-ManifestPath $BaseDir
    if (Test-Path -LiteralPath $mf) {
        $recorded = @(Get-ManifestBufferLines $mf | Where-Object { (($_ -split '\s+', 3)[1]) -eq $EditorName })
        if ($recorded.Count -eq 0) { return }
        $script:UpdateReport = $true
        try { Install-ForEditor -EditorName $EditorName -SourcePath $SourcePath -BaseDir $BaseDir -Scope $Scope }
        finally { $script:UpdateReport = $false }
        Remove-Unshipped $BaseDir $EditorName $Scope
    }
    else {
        Add-KnownFiles $BaseDir $EditorName $Scope
    }
}

function Remove-Unshipped {
    param([string]$BaseDir, [string]$Editor, [string]$Scope)
    $mf = Get-ManifestPath $BaseDir
    $kept = @()
    # For a non-claude editor, "still shipped" is "a destination this install writes" (plan 047):
    # every other recorded path, the old merged adapters and .bem-te-vi/ included, is not.
    $shipped = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    if ($Editor -ne 'claude') {
        foreach ($pair in (Get-EditorFiles $Editor $BaseDir $Scope)) {
            [void]$shipped.Add(($pair[1].Substring($BaseDir.Length).TrimStart('\', '/') -replace '\\', '/'))
        }
    }
    foreach ($line in @(Get-ManifestBufferLines $mf)) {
        $parts = $line -split '\s+', 3
        if ($parts.Count -ne 3) { continue }
        if ($parts[1] -ne $Editor) { $kept += $line; continue }
        if (-not (Test-SafeManifestRel $parts[2])) {
            Write-Host "  X Refusing $($parts[2]) - it points outside $BaseDir. The manifest may have been tampered with." -ForegroundColor Red
            $kept += $line; continue
        }
        if ($Editor -eq 'claude') {
            if (Test-Path -LiteralPath (Join-Path $PSScriptRoot ($parts[2] -replace '/', '\')) -PathType Leaf) { $kept += $line; continue }
        }
        elseif ($shipped.Contains($parts[2])) { $kept += $line; continue }
        $linked = Get-LinkedAncestor $BaseDir $parts[2]
        if ($linked) {
            # Kept, and still recorded: the file is not ours to delete through a link.
            Write-LinkedDir $BaseDir $linked 'Kept' 'deleted'
            $kept += $line; $script:UpdateKept++; continue
        }
        $file = Join-Path $BaseDir ($parts[2] -replace '/', '\')
        if (Test-Path -LiteralPath $file -PathType Container) {
            # Never hashed, entered or deleted (plan 047): Cline turns its .clinerules file into a
            # folder. Kept and forgotten, like any changed file the package stopped shipping.
            Write-Info "Kept $($parts[2]) - it is a directory now, not the file that was installed"
            Write-OldLocationNote $BaseDir $Editor $parts[2]
            $script:UpdateKept++
            continue
        }
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
        if ((Get-Item -LiteralPath $file -Force).IsReadOnly) {
            Write-Info "Kept $($parts[2]) - destination is read-only"
            $script:UpdateKept++
        }
        elseif (Test-Unreadable $file) {
            Write-Info "Kept $($parts[2]) - destination cannot be read"
            $script:UpdateKept++
        }
        elseif (Test-FileMatchesHash $file $parts[0]) {
            Remove-Item -LiteralPath $file -Force
            Write-Info "Removed $($parts[2]) (no longer shipped)"
            $script:UpdateChanged++
            # Its folders go while they are empty, up to the base (plan 047); none is a link, as
            # Get-LinkedAncestor found none above.
            if ($Editor -ne 'claude') { Remove-EmptyAncestors (Split-Path -Parent $file) $BaseDir }
        }
        else {
            Write-Info "Kept $($parts[2]) - changed since it was installed"
            Write-OldLocationNote $BaseDir $Editor $parts[2]
            $script:UpdateKept++
        }
    }
    $script:ManifestBuffer[$mf] = $kept
}

# An install made before manifests existed: only a file identical to the package's current one,
# or whose hash a release shipped, is the package's, so only such a file is refreshed. Nothing
# is created.
function Add-KnownFiles {
    param([string]$BaseDir, [string]$Editor, [string]$Scope)
    foreach ($pair in (Get-PackageFiles $Editor $BaseDir $Scope)) {
        $dest = $pair[1]
        $rel = $dest.Substring($BaseDir.Length).TrimStart('\', '/') -replace '\\', '/'
        $linked = Get-LinkedAncestor $BaseDir $rel
        if ($linked) {
            if (Test-Path -LiteralPath $dest) { Write-LinkedDir $BaseDir $linked 'Skipped' 'written'; $script:UpdateKept++ }
            continue
        }
        if (-not (Test-Path -LiteralPath $dest -PathType Leaf)) { continue }
        # Not provably the package's: left alone, as install.sh and the CLI do (plan 053 I15).
        if (Test-Unreadable $dest) { continue }
        $srcHash = Get-Sha256 $pair[0]
        $destHash = Get-Sha256 $dest
        $destHashNoCR = Get-Sha256WithoutCR $dest
        $ours = ($destHash -eq $srcHash) -or ($destHashNoCR -eq $srcHash) -or (Test-KnownHash $destHash) -or (Test-KnownHash $destHashNoCR)
        if (-not $ours) { continue }
        Install-File $BaseDir $Editor $pair[0] $dest
        Write-Success "Adopted $rel"
        $script:UpdateChanged++
    }
}

function Invoke-GitIntegration {
    <#
    .DESCRIPTION
        Offers to stage, commit, and optionally push the installed files.
    #>
    param(
        [string]$BaseDir
    )

    # A .git folder, or a .git file as in a worktree or a submodule.
    if (-not (Test-Path -LiteralPath (Join-Path $BaseDir '.git'))) {
        return
    }

    # Filter to only files that are within the current repo working tree. Both sides are
    # normalised to forward slashes first: git prints C:/repo while Resolve-Path prints C:\repo.
    $repoRoot = (Invoke-GitQuiet @('rev-parse', '--show-toplevel')).Out
    if (-not $repoRoot) { return }
    $repoRootFull = [System.IO.Path]::GetFullPath($repoRoot).Replace('\', '/').TrimEnd('/') + '/'

    # Commit only what the installer recorded, the list install.sh commits: every path in the
    # project manifest that is still a file, plus the manifest itself. The manifest can be edited
    # by anyone, so each path is checked as uninstall checks it before it reaches git add; and a
    # path the run skipped (a folder of the user's, a read-only file) is never recorded at all.
    $manifest = Get-ManifestPath $BaseDir
    $recorded = @()
    foreach ($line in Get-ManifestLines $manifest) {
        $parts = $line -split '\s+', 3
        if (($parts.Count -ne 3) -or -not (Test-SafeManifestRel $parts[2])) { continue }
        $recorded += Join-Path $BaseDir ($parts[2] -replace '/', [string][System.IO.Path]::DirectorySeparatorChar)
    }
    $recorded += $manifest

    $relativeFiles = @()
    foreach ($f in $recorded) {
        if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { continue }
        $resolved = (Resolve-Path -LiteralPath $f -ErrorAction SilentlyContinue).Path
        if (-not $resolved) { continue }
        $resolvedFull = [System.IO.Path]::GetFullPath($resolved).Replace('\', '/')
        if ($resolvedFull.StartsWith($repoRootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relativeFiles += $resolvedFull.Substring($repoRootFull.Length)
        }
    }

    if ($relativeFiles.Count -eq 0) {
        return
    }

    Write-Host ""
    $commit = Read-YesNo -Prompt "Add to git and commit?" -Default 'n'
    if ($commit -ne 'y') { return }

    try {
        # Commit only the files the installer wrote: `git commit -- <paths>` leaves whatever
        # else the user has staged or edited out of the commit.
        git add -- $relativeFiles
        if ($LASTEXITCODE -ne 0) { throw "git add failed with exit status $LASTEXITCODE" }
        git commit -m "Add/update QA skill for AI-assisted editors (ISTQB CTFL v4.0)" -- $relativeFiles
        if ($LASTEXITCODE -ne 0) { throw "git commit failed with exit status $LASTEXITCODE" }
        Write-Success "Committed to git"

        # Only the current branch's upstream, never a guessed remote.
        $push = Read-YesNo -Prompt "Push to remote?" -Default 'n'
        if ($push -eq 'y') {
            git push
            if ($LASTEXITCODE -ne 0) { throw "git push failed with exit status $LASTEXITCODE (does this branch have an upstream?)" }
            Write-Success "Pushed"
        }
    }
    catch {
        Write-Err "Git operation failed: $_"
    }
}

# Lists what the package ships, read from its own .claude\ at run time, so a new command, skill or
# agent shows up here with no edit. The same block in install.sh and cli/qa-instinct.js (plan 033 item 8).
# Rules are counted, not named. Names are sorted ordinally, as LC_ALL=C sort and JavaScript do.
function Write-ClaudeHint {
    $claudeSrc = Join-Path $PSScriptRoot '.claude'
    $sortOrdinal = {
        param([string[]]$Names)
        $list = [System.Collections.Generic.List[string]]::new()
        foreach ($n in $Names) { $list.Add($n) }
        $list.Sort([System.StringComparer]::Ordinal)
        return ,$list.ToArray()
    }
    $commands = & $sortOrdinal @(Get-ChildItem -LiteralPath (Join-Path $claudeSrc 'commands') -File -Filter 'qa-*.md' | ForEach-Object { '/' + ($_.Name -replace '\.md$', '') })
    $skills = & $sortOrdinal @(Get-ChildItem -LiteralPath (Join-Path $claudeSrc 'skills') -Directory | ForEach-Object { $_.Name })
    $agents = & $sortOrdinal @(Get-ChildItem -LiteralPath (Join-Path $claudeSrc 'agents') -File -Filter '*.md' | ForEach-Object { $_.Name -replace '\.md$', '' })
    $rules = @(Get-ChildItem -LiteralPath (Join-Path $claudeSrc 'rules') -File -Filter '*.md').Count
    Write-Host "  Claude Code : type /qa to start"
    Write-Host "              : commands : $($commands -join ' ')"
    Write-Host "              : skills   : $($skills -join ' ')"
    Write-Host "              : agents   : $($agents -join ' ')"
    Write-Host "              : rules    : $rules files in .claude/rules/ (always loaded)"
}

# ─── Main ────────────────────────────────────────────────────────────────────

function Main {
    Write-Header

    # Resolve script directory
    $ScriptDir = $PSScriptRoot
    $QASkillFile = Join-Path $ScriptDir '.claude\commands\qa.md'

    # ── Pre-flight checks ─────────────────────────────────────────────────

    # 1. Check qa.md exists in package
    if (-not (Test-Path -LiteralPath $QASkillFile)) {
        Write-Err "qa.md not found at $QASkillFile"
        Write-Host "Please ensure you're running this script from the QA package directory." -ForegroundColor Red
        exit 1
    }
    Write-Success "Source qa.md found"

    # 2. Check Claude Code is installed
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claudeCmd) {
        Write-Info "Warning: 'claude' command not found in PATH."
        Write-Host "  The skill file will be installed, but Claude Code may not be set up yet."
        Write-Host "  Install Claude Code from: https://docs.anthropic.com/claude-code" -ForegroundColor Cyan

        if (-not $NonInteractive) {
            $cont = Read-YesNo -Prompt "Continue anyway?" -Default 'n'
            if ($cont -ne 'y') {
                Write-Host "Installation cancelled."
                exit 0
            }
        }
        else {
            Write-Info "Non-interactive mode: continuing without Claude Code."
        }
    }
    else {
        Write-Success "'claude' command found"
    }

    # ── Operation mode selection ──────────────────────────────────────────

    $global:OPERATION = 'install'
    if ($Update) {
        $global:OPERATION = 'update'
    }
    elseif ($Uninstall) {
        $global:OPERATION = 'uninstall'
    }
    elseif ($NonInteractive) {
        $global:OPERATION = 'install'
    }
    else {
        Write-Host "QA Instinct - Lifecycle Manager" -ForegroundColor Yellow
        Write-Host "  1. Install (Fresh deployment of QA Instinct)  [DEFAULT]"
        Write-Host "  2. Update (Pull latest versions of all rules and commands)"
        Write-Host "  3. Uninstall / Remove (Purge all copied files & clean up git hooks)"
        Write-Host ""

        $choice = Read-UserChoice -Prompt "Choose action (1/2/3)" -ValidChoices @('1','2','3') -Default '1'
        switch ($choice) {
            '1' { $global:OPERATION = 'install' }
            '2' { $global:OPERATION = 'update' }
            '3' { $global:OPERATION = 'uninstall' }
        }
        Write-Host ""
    }

    # Cumulative uninstall reporting: how many recorded/matched files were actually removed vs.
    # kept (changed since install, or read-only). The final summary is derived from these
    # instead of assuming success.
    $global:UninstallRemovedCount = 0
    $global:UninstallKeptCount = 0

    # ── Target selection ──────────────────────────────────────────────────

    if (-not $Target) {
        if ($NonInteractive) {
            $Target = 'project'
        }
        else {
            if ($global:OPERATION -eq 'uninstall') {
                Write-Host "Uninstallation Target:" -ForegroundColor Yellow
            }
            else {
                Write-Host "Installation Target:" -ForegroundColor Yellow
            }
            Write-Host "  1. Project-level (current project only)     [DEFAULT]"
            Write-Host "  2. Global (all projects)"
            Write-Host "  3. Both"
            Write-Host ""

            $choice = Read-UserChoice -Prompt "Choose option (1/2/3)" -ValidChoices @('1','2','3') -Default '1'
            switch ($choice) {
                '1' { $Target = 'project' }
                '2' { $Target = 'global'  }
                '3' { $Target = 'both'    }
            }
        }
    }

    # ── Editor selection ──────────────────────────────────────────────────

    if (-not $Script:EditorGiven -and $global:OPERATION -eq 'update') {
        # No editor named: every editor, with no menu, as the CLI's update. Update-ForEditor
        # skips an editor the manifest does not record, so only what is installed is refreshed
        # (plan 061 B1).
        $Editor = 'all'
    }
    elseif (-not $Script:EditorGiven) {
        # Editor was not explicitly passed; show menu unless non-interactive
        if (-not $NonInteractive) {
            Write-Host ""
            if ($global:OPERATION -eq 'uninstall') {
                Write-Host "Editor Target for Uninstallation:" -ForegroundColor Yellow
            }
            else {
                Write-Host "Editor Target:" -ForegroundColor Yellow
            }
            Write-Host "  1. Claude Code - CLI & VS Code extension      [DEFAULT]"
            Write-Host "  2. Cursor / Trae (.cursor/rules/, .cursor/skills/)"
            Write-Host "  3. Windsurf (.windsurf/rules/, .windsurf/skills/)"
            Write-Host "  4. GitHub Copilot (VS Code)"
            Write-Host "  5. Cline (VS Code)"
            Write-Host "  6. Antigravity (Google) (.agents/rules/, .agents/skills/)"
            Write-Host "  7. All editors"
            Write-Host ""

            $editorChoice = Read-UserChoice -Prompt "Choose editor (1-7)" -ValidChoices @('1','2','3','4','5','6','7') -Default '1'
            switch ($editorChoice) {
                '1' { $Editor = 'claude'       }
                '2' { $Editor = 'cursor'       }
                '3' { $Editor = 'windsurf'     }
                '4' { $Editor = 'copilot'      }
                '5' { $Editor = 'cline'        }
                '6' { $Editor = 'antigravity'  }
                '7' { $Editor = 'all'          }
            }
        }
        # else: keep default 'claude'
    }

    # Build list of editors to install/uninstall
    if ($Editor -eq 'all') {
        $editors = @('claude', 'cursor', 'windsurf', 'copilot', 'cline', 'antigravity')
    }
    else {
        $editors = @($Editor)
    }

    # ── Execution ─────────────────────────────────────────────────────────

    Write-Host ""

    # Helper to track installed files or perform lifecycle action
    function Install-ToDirectory {
        param(
            [string]$BaseDir,
            [string]$Scope
        )

        if ($global:OPERATION -eq 'uninstall') {
            Write-Info "Uninstalling from $Scope scope..."
            Write-FilePath $BaseDir
            foreach ($ed in $editors) {
                Uninstall-ForEditor -EditorName $ed -BaseDir $BaseDir -Scope $Scope
            }
            Write-Success "$Scope uninstallation complete"
        }
        else {
            Write-Info "Installing/Updating to $Scope scope..."
            Write-FilePath $BaseDir

            # The manifest is saved even when the run fails part-way, so every file installed before
            # the failure stays recorded and uninstall can still remove it.
            try {
                foreach ($ed in $editors) {
                    if ($global:OPERATION -eq 'update') { Update-ForEditor -EditorName $ed -SourcePath $QASkillFile -BaseDir $BaseDir -Scope $Scope }
                    else { Install-ForEditor -EditorName $ed -SourcePath $QASkillFile -BaseDir $BaseDir -Scope $Scope }
                }
            }
            finally {
                Save-ManifestBuffer -BaseDir $BaseDir
            }
            Write-Success "$Scope deployment complete"
        }
    }

    try {
        switch ($Target) {
            'project' {
                $projectDir = $PWD.Path
                Install-ToDirectory -BaseDir $projectDir -Scope 'Project'
                if ($global:OPERATION -ne 'uninstall') {
                    Invoke-GitIntegration -BaseDir $projectDir
                }
            }
            'global' {
                $globalDir = $env:USERPROFILE
                Install-ToDirectory -BaseDir $globalDir -Scope 'Global'
            }
            'both' {
                $projectDir = $PWD.Path
                $globalDir  = $env:USERPROFILE

                Install-ToDirectory -BaseDir $projectDir -Scope 'Project'
                Write-Host ""
                Install-ToDirectory -BaseDir $globalDir -Scope 'Global'
                if ($global:OPERATION -ne 'uninstall') {
                    Invoke-GitIntegration -BaseDir $projectDir
                }
            }
        }
    }
    catch {
        Write-Err "Operation failed: $_"
        exit 1
    }

    # ── Post-execution ────────────────────────────────────────────────────

    Write-Host ""
    Write-Host ([string][char]0x2550 * 54) -ForegroundColor Cyan
    Write-Host ""
    if ($global:OPERATION -eq 'uninstall') {
        if ($global:UninstallKeptCount -gt 0) {
            Write-Host "[!!] Uninstallation finished with some files kept." -ForegroundColor Yellow
            Write-Host "Removed $($global:UninstallRemovedCount) file(s); kept $($global:UninstallKeptCount) (see warnings above)."
        }
        elseif ($global:UninstallRemovedCount -eq 0) {
            Write-Host "[..] Nothing to uninstall." -ForegroundColor Cyan
            Write-Host "No QA Instinct files were found installed."
        }
        else {
            Write-Success "Uninstallation successful!"
            Write-Host "QA Instinct has been completely removed. Removed $($global:UninstallRemovedCount) file(s)."
        }
    }
    elseif ($global:OPERATION -eq 'update') {
        $updateTotal = $script:UpdateChanged + $script:UpdateUpToDate + $script:UpdateKept
        if ($updateTotal -eq 0) { Write-Host "[..] Nothing installed - run the installer without -Update first." -ForegroundColor Cyan }
        elseif ($script:UpdateKept -gt 0) { Write-Host "[!!] Update complete - $($script:UpdateKept) file(s) kept as-is (see above)." -ForegroundColor Yellow }
        elseif ($script:UpdateChanged -eq 0) { Write-Success "Everything is up to date." }
        else { Write-Success "Update complete." }
    }
    elseif ($script:FilesWritten -eq 0) {
        # Every destination was skipped (linked, a folder, unreadable or read-only): nothing to use.
        Write-Info "Nothing was installed: every destination was skipped (see above)."
    }
    else {
        Write-Success "Installation successful!"
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Green
        # A global install writes rules for Claude Code and Cline only; the other editors get skills.
        if ($Target -eq 'global') {
            $rulesHint = 'skills only (a global install writes no rules)'
            $copilotRulesHint = $rulesHint
        }
        else {
            $rulesHint = 'qa-instinct rules always on'
            $copilotRulesHint = 'rules in .github\copilot-instructions.md'
        }
        foreach ($ed in $editors) {
            switch ($ed) {
                'claude' { Write-ClaudeHint }
                'cursor'      { Write-Host "  Cursor/Trae : $rulesHint; every command, skill and agent is a skill (/qa-cases)" }
                'windsurf'    { Write-Host "  Windsurf    : $rulesHint; every command, skill and agent is a skill (@qa-cases)" }
                'copilot'     { Write-Host "  Copilot     : $copilotRulesHint; every command, skill and agent is a skill (/qa-cases)" }
                'cline'       { Write-Host "  Cline       : qa-instinct rules always on; every command, skill and agent is a skill (/qa-cases)" }
                'antigravity' {
                    Write-Host "  Antigravity : $rulesHint; every command, skill and agent is a skill (ask for qa-cases)"
                    # Antigravity's launcher in a plain WSL terminal opens a Windows window whose
                    # agent cannot read the folder; a WSL window works (plan 062).
                    if ($env:WSL_DISTRO_NAME) {
                        $wslFolder = if ($Target -eq 'global') { '<folder>' } else { (Get-Location).ProviderPath }
                        Write-Host "              : in WSL, open the folder in a WSL window: antigravity-ide --remote wsl+$($env:WSL_DISTRO_NAME) $wslFolder"
                    }
                }
            }
        }
        Write-Host ""
        Write-Host "Documentation:" -ForegroundColor Green
        Write-Host "  - Full guide  : $ScriptDir\README.md"
        Write-Host "  - Examples    : $ScriptDir\examples\README.md"
    }
    Write-Host ""
    Write-Host ([string][char]0x2550 * 54) -ForegroundColor Cyan
    Write-Host ""
}

# Whether -Editor was given. Read here, at script level: inside Main, $PSBoundParameters holds
# Main's own parameters, so the editor menu showed and replaced -Editor in an interactive run.
$Script:EditorGiven = $PSBoundParameters.ContainsKey('Editor')

# Run
Main

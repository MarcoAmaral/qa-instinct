# Requires -Version 5.1
#
# tests/conformance/run.ps1 - run every conformance case against every installer
# available on Windows: install.ps1 and cli/qa-instinct.js. (install.sh is covered by run.sh.)
# Each guarantee the installers share is written once, as a case under cases\, and is
# required of all of them. See plans/016.
#
# Usage: tests\conformance\run.ps1 [-Filter <case-name-substring>] [-Package <dir>]
#
# -Package runs the installers from another package tree - an older release, say - while
# the cases still come from this repository. That is how a case is proven to fail against
# a historical installer before it passes.
#
# -Cases reads the cases from another folder; tests\conformance\test-runner.ps1 uses it to feed the
# runner malformed cases.
#
# Kept ASCII-only on purpose: Windows PowerShell 5.1 reads a script without a BOM as ANSI.

param(
    [string]$Filter = '',
    [string]$Package = '',
    [string]$Cases = ''
)

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$repo = (Resolve-Path (Join-Path $here '..\..')).Path
$pkg = if ($Package) { (Resolve-Path $Package).Path } else { $repo }
# The CLI moved from bin\cli.js to cli\bem-te-vi.js after 4.0.1 (plan 051), and to
# cli\qa-instinct.js with the rename (plan 065); an older package tree still has it at an old path.
$cli = Join-Path $pkg 'cli\qa-instinct.js'
if (-not (Test-Path -LiteralPath $cli)) { $cli = Join-Path $pkg 'cli\bem-te-vi.js' }
if (-not (Test-Path -LiteralPath $cli)) { $cli = Join-Path $pkg 'bin\cli.js' }
$casesDir = if ($Cases) { (Resolve-Path -LiteralPath $Cases).Path } else { "$here\cases" }
$utf8 = New-Object System.Text.UTF8Encoding($false)
$emDash = [char]0x2014
# The project folder's name holds a space and wildcard characters, so every case also proves that
# an installer treats the paths it computes literally (plan 033 item 5).
$proj = 'project [1]'

$script:denyRead = New-Object System.Security.AccessControl.FileSystemAccessRule(
    [System.Security.Principal.WindowsIdentity]::GetCurrent().User,
    [System.Security.AccessControl.FileSystemRights]::ReadData,
    [System.Security.AccessControl.AccessControlType]::Deny)

function Get-Sha([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLower() }

# --- Reading a case file -------------------------------------------------------
# A case file is data the runner acts on, so it is checked in full before any line runs: a path
# that is absolute or climbs out of its scope's folder, a scope, editor or operation the runner
# does not know, and a line outside the grammar make the case malformed, and nothing of it runs.
# run.sh applies the same grammar, line for line (tests\conformance\test-runner.ps1 checks this).

$caseEditors = @('claude', 'cursor', 'windsurf', 'copilot', 'cline', 'antigravity')
# The manifest every installer writes, and the name a 4.x install wrote it under (plan 066).
$manifestName = '.qa-instinct-manifest'
$legacyManifestName = '.qa-skills-manifest'

# A relative path with forward slashes, no empty, '.' or '..' segment, no drive or backslash.
function Test-SafeRel([string]$Rel) {
    if ($Rel -eq '' -or $Rel.StartsWith('/') -or $Rel.Contains('\') -or $Rel -match '^[A-Za-z]:') { return $false }
    foreach ($seg in ($Rel -split '/')) { if ($seg -eq '' -or $seg -eq '.' -or $seg -eq '..') { return $false } }
    return $true
}
function Test-PathSpec([string]$Spec) {
    if ($Spec.StartsWith('project:')) { return (Test-SafeRel $Spec.Substring(8)) }
    if ($Spec.StartsWith('home:')) { return (Test-SafeRel $Spec.Substring(5)) }
    return $false
}
# A manifest entry is text the installers read, and a case may record one that climbs out of its
# scope (case 005 does, to prove the installers refuse it). The runner itself still reads and
# deletes at that path, so it must end inside the sandbox's project or home folder.
function Test-SandboxRel([string]$Rel) {
    if ($Rel -eq '' -or $Rel.StartsWith('/') -or $Rel.Contains('\') -or $Rel -match '^[A-Za-z]:') { return $false }
    $depth = 1; $top = ''
    foreach ($seg in ($Rel -split '/')) {
        if ($seg -eq '' -or $seg -eq '.') { return $false }
        if ($seg -eq '..') { $depth--; if ($depth -lt 0) { return $false }; continue }
        if ($depth -eq 0) { $top = $seg }
        $depth++
    }
    return ($depth -ge 2) -and (($top -eq '') -or ($top -ceq $proj) -or ($top -ceq 'home'))
}
function Get-Words([string]$Val) { return @($Val -split '\s+') }

function Test-Directive([string]$Key, [string]$Val) {
    $hasPair = $Val.Contains(' = ')
    $left = ($Val -split ' = ', 2)[0].Trim()
    $right = if ($hasPair) { ($Val -split ' = ', 2)[1] } else { '' }
    switch -CaseSensitive ($Key) {
        'name' { return $true }
        { $_ -in 'skip', 'expect-output', 'expect-no-output' } { return ($Val -ne '') }
        { $_ -in 'seed', 'expect-content', 'expect-backup-content' } { return ($hasPair -and (Test-PathSpec $left)) }
        { $_ -in 'seed-fixture', 'seed-package', 'expect-same-as-package', 'expect-tree-as-package' } { return ($hasPair -and (Test-PathSpec $left) -and (Test-SafeRel $right.Trim())) }
        'expect-backup-link-target' { return ($hasPair -and (Test-PathSpec $left) -and (Test-PathSpec $right.Trim())) }
        'seed-symlink' {
            if (-not $Val.Contains(' -> ')) { return $false }
            $parts = $Val -split ' -> ', 2
            return ((Test-PathSpec $parts[0].Trim()) -and (Test-PathSpec $parts[1].Trim()))
        }
        { $_ -in 'seed-manifest', 'drop-manifest', 'expect-manifest', 'expect-no-manifest' } {
            # The path is the rest of the line, so it may hold a space (plan 053 I11).
            $w = @($Val -split '\s+', 3)
            return (($w.Count -eq 3) -and ($w[0] -cin 'project', 'home') -and ($w[1] -cin $caseEditors) -and (Test-SandboxRel $w[2]))
        }
        'legacy-manifest' {
            if ($Val.Contains(' -> ')) {
                $parts = $Val -split ' -> ', 2
                return (($parts[0].Trim() -cin 'project', 'home') -and (Test-PathSpec $parts[1].Trim()))
            }
            return ($Val -cin 'project', 'home')
        }
        { $_ -in 'seed-dir', 'seed-readonly', 'seed-unreadable', 'seed-crlf', 'expect-file', 'expect-absent', 'expect-backup', 'expect-no-backup' } { return (Test-PathSpec $Val) }
        { $_ -in 'run', 'run-unknown-option' } {
            # The editor may be left out: the run then names none (plan 061 B1).
            $w = Get-Words $Val
            return ((($w.Count -eq 2) -or (($w.Count -eq 3) -and ($w[2] -cin ($caseEditors + 'all')))) -and ($w[0] -cin 'install', 'uninstall', 'update') -and ($w[1] -cin 'project', 'global'))
        }
        'expect-exit' { return ($Val -cmatch '^[0-9]+$') }
        'expect-exit-nonzero' { return ($Val -eq '') }
        'expect-output-lists-package' {
            $w = Get-Words $Val
            if ($w.Count -ne 2 -or -not (Test-SafeRel $w[0])) { return $false }
            $pattern = $w[1].TrimEnd('/')
            return (($pattern -ne '') -and -not $pattern.Contains('/') -and -not $pattern.Contains('..'))
        }
    }
    return $false
}

# Returns one "key|value" per directive line, or throws "malformed case: ...". The file is split
# on LF only, as bash reads it; a leading BOM and the whitespace around a line, a CR included,
# are not part of it.
function Read-Case([string]$Path) {
    $text = [System.IO.File]::ReadAllText($Path, $utf8).TrimStart([char]0xFEFF)
    $steps = New-Object System.Collections.Generic.List[string]
    $num = 0
    foreach ($raw in ($text -split "`n")) {
        $num++
        $line = $raw.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { continue }
        if ($line -cnotmatch '^([a-z][a-z-]*):(.*)$') { throw "malformed case: line $num is not '<directive>: <value>'" }
        $key = $Matches[1]; $val = $Matches[2].Trim()
        if (-not (Test-Directive $key $val)) {
            throw "malformed case: line $num ($key) - unknown directive, or a scope, editor, operation or path the runner does not accept"
        }
        $steps.Add("$key|$val")
    }
    return ,$steps
}

function Resolve-CasePath([string]$Spec) {
    if (-not (Test-PathSpec $Spec)) { throw "conformance: refusing path '$Spec'" }
    if ($Spec -like 'project:*') { return Join-Path (Join-Path $script:sb $proj) ($Spec.Substring(8) -replace '/', '\') }
    if ($Spec -like 'home:*')    { return Join-Path "$script:sb\home" ($Spec.Substring(5) -replace '/', '\') }
    throw "conformance: path '$Spec' needs a project: or home: prefix"
}
function Get-ScopeRoot([string]$Scope) {
    if ($Scope -ceq 'project') { return (Join-Path $script:sb $proj) }
    if ($Scope -ceq 'home') { return "$script:sb\home" }
    throw "conformance: unknown scope '$Scope'"
}

function Write-Text([string]$Path, [string]$Text) {
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, "$Text`n", $utf8)
}
function Read-Text([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return ([System.IO.File]::ReadAllText($Path, $utf8)).TrimEnd("`r", "`n")
}

# An empty editor passes no editor option at all. -Bogus appends one option the installer does
# not know, in its own syntax.
function Invoke-Action([string]$Installer, [string]$Op, [string]$Scope, [string]$Editor, [switch]$Bogus) {
    Push-Location -LiteralPath (Join-Path $script:sb $proj)
    # Under 'Stop', Windows PowerShell 5.1 turns an installer's stderr, merged by 2>&1, into a
    # terminating error, so a refusal the case expects would abort the run instead of being checked.
    $savedPreference = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        if ($Installer -eq 'install.ps1') {
            $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "$pkg\install.ps1",
                   '-Target', $Scope, '-NonInteractive', '-NoHooks')
            if ($Editor) { $a += @('-Editor', $Editor) }
            if ($Op -eq 'uninstall') { $a += '-Uninstall' }
            if ($Op -eq 'update') { $a += '-Update' }
            if ($Bogus) { $a += '-BogusOption' }
            $out = & powershell.exe @a 2>&1 | Out-String
        } else {
            $a = @($cli, $(if ($Op -eq 'install') { 'init' } else { $Op }))
            if ($Scope -eq 'global') { $a += '--global' }
            if ($Editor) { $a += @('--editor', $Editor) }
            if ($Bogus) { $a += '--bogus-option' }
            $out = & node @a 2>&1 | Out-String
        }
        $script:lastExit = $LASTEXITCODE
        Add-Content -LiteralPath $script:log -Value $out -Encoding UTF8
    } finally { $ErrorActionPreference = $savedPreference; Pop-Location }
}

function Invoke-Case([string]$Dir, [string]$Installer) {
    try { $steps = Read-Case "$Dir\case.conf" }
    catch { return [pscustomobject]@{ NotRun = $null; Failures = @($_.Exception.Message) } }
    $script:sb = Join-Path $env:TEMP ('qa-conformance-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $script:sb $proj), "$script:sb\home" -Force | Out-Null
    $script:log = "$script:sb\output.log"; Set-Content -LiteralPath $script:log -Value '' -Encoding UTF8
    $script:lastExit = 0
    $failures = New-Object System.Collections.Generic.List[string]
    $notRun = $null
    $expects = New-Object System.Collections.Generic.List[string]
    $unreadable = New-Object System.Collections.Generic.List[string]
    $savedProfile = $env:USERPROFILE; $savedHome = $env:HOME
    $env:USERPROFILE = "$script:sb\home"; $env:HOME = "$script:sb\home"

    try {
        foreach ($step in $steps) {
            $i = $step.IndexOf('|'); $key = $step.Substring(0, $i); $val = $step.Substring($i + 1)
            $left = ($val -split ' = ', 2)[0].Trim(); $right = if ($val.Contains(' = ')) { ($val -split ' = ', 2)[1] } else { '' }
            switch ($key) {
                'name' { } 'skip' { }
                'seed'         { Write-Text (Resolve-CasePath $left) $right }
                'seed-fixture' { $t = Resolve-CasePath $left; New-Item -ItemType Directory -Path (Split-Path -Parent $t) -Force | Out-Null; Copy-Item -LiteralPath (Join-Path $Dir ($right.Trim() -replace '/', '\')) -Destination $t -Force }
                'seed-package' { $t = Resolve-CasePath $left; New-Item -ItemType Directory -Path (Split-Path -Parent $t) -Force | Out-Null; Copy-Item -LiteralPath (Join-Path $pkg ($right.Trim() -replace '/', '\')) -Destination $t -Force }
                'seed-manifest' {
                    $p = $val -split '\s+', 3; $root = Get-ScopeRoot $p[0]
                    $file = [System.IO.Path]::GetFullPath((Join-Path $root ($p[2] -replace '/', '\')))
                    [System.IO.File]::AppendAllText("$root\$manifestName", "$(Get-Sha $file)  $($p[1])  $($p[2])`n", $utf8)
                }
                'drop-manifest' {
                    # Removes an installed file and its manifest line, as if the install predated the file.
                    $p = $val -split '\s+', 3; $root = Get-ScopeRoot $p[0]
                    Remove-Item -LiteralPath (Join-Path $root ($p[2] -replace '/', '\')) -Force -ErrorAction SilentlyContinue
                    $pattern = '^[0-9a-f]{64}  ' + [regex]::Escape($p[1]) + '  ' + [regex]::Escape($p[2]) + '$'
                    $rest = @([System.IO.File]::ReadAllLines("$root\$manifestName", $utf8) | Where-Object { $_ -cnotmatch $pattern })
                    [System.IO.File]::WriteAllText("$root\$manifestName", (($rest | ForEach-Object { "$_`n" }) -join ''), $utf8)
                }
                'legacy-manifest' {
                    # Renames the scope's manifest to the name a 4.x install wrote it under. With
                    # "-> <path>", the manifest moves to that path and the old name becomes a symlink to it.
                    $parts = $val -split ' -> ', 2; $root = Get-ScopeRoot $parts[0].Trim()
                    if (-not (Test-Path -LiteralPath "$root\$manifestName")) { $failures.Add("no manifest to rename in $($parts[0].Trim())") }
                    elseif ($parts.Count -eq 1) { Move-Item -LiteralPath "$root\$manifestName" -Destination "$root\$legacyManifestName" }
                    else {
                        $t = Resolve-CasePath $parts[1].Trim()
                        New-Item -ItemType Directory -Path (Split-Path -Parent $t) -Force | Out-Null
                        Move-Item -LiteralPath "$root\$manifestName" -Destination $t
                        try { New-Item -ItemType SymbolicLink -Path "$root\$legacyManifestName" -Target $t -ErrorAction Stop | Out-Null }
                        catch {
                            if ($_.FullyQualifiedErrorId -notlike 'NewItemSymbolicLinkElevationRequired*') {
                                throw "conformance: cannot create symlink '$legacyManifestName': $($_.Exception.Message)"
                            }
                            $notRun = 'creating a symlink needs Developer Mode or an elevated shell'; break
                        }
                    }
                }
                'seed-dir'     { New-Item -ItemType Directory -Path (Resolve-CasePath $val) -Force | Out-Null }
                'seed-readonly' { Set-ItemProperty -LiteralPath (Resolve-CasePath $val) -Name IsReadOnly -Value $true }
                'seed-unreadable' {
                    # What chmod a-r does on Linux and macOS: the current user may no longer read the
                    # file's data. Taken back before the sandbox is removed.
                    $item = Get-Item -LiteralPath (Resolve-CasePath $val) -Force
                    $acl = $item.GetAccessControl('Access')
                    $acl.AddAccessRule($script:denyRead); $item.SetAccessControl($acl)
                    $unreadable.Add($item.FullName)
                }
                'seed-crlf' {
                    # Every LF gets a CR before it, an existing CRLF stays as it is, and a last
                    # line with no newline stays without one.
                    $t = Resolve-CasePath $val
                    $bytes = [System.IO.File]::ReadAllBytes($t)
                    $crlf = New-Object System.Collections.Generic.List[byte]
                    for ($k = 0; $k -lt $bytes.Length; $k++) {
                        if ($bytes[$k] -eq 10 -and ($k -eq 0 -or $bytes[$k - 1] -ne 13)) { $crlf.Add([byte]13) }
                        $crlf.Add($bytes[$k])
                    }
                    [System.IO.File]::WriteAllBytes($t, $crlf.ToArray())
                }
                'seed-symlink' {
                    $parts = $val -split ' -> ', 2
                    $linkPath = Resolve-CasePath $parts[0].Trim(); $linkTarget = Resolve-CasePath $parts[1].Trim()
                    # Windows PowerShell 5.1 refuses a link to a missing target (PathNotFound, raised
                    # before the privilege check), so a missing target exists as a folder only while
                    # the link is made: the case gets a dangling folder link, as on Linux and macOS.
                    $madeTarget = -not (Test-Path -LiteralPath $linkTarget)
                    if ($madeTarget) { New-Item -ItemType Directory -Path $linkTarget -Force | Out-Null }
                    try { New-Item -ItemType SymbolicLink -Path $linkPath -Target $linkTarget -ErrorAction Stop | Out-Null }
                    catch {
                        if ($_.FullyQualifiedErrorId -notlike 'NewItemSymbolicLinkElevationRequired*') {
                            throw "conformance: cannot create symlink '$($parts[0].Trim())': $($_.Exception.Message)"
                        }
                        $notRun = 'creating a symlink needs Developer Mode or an elevated shell'; break
                    }
                    finally { if ($madeTarget) { Remove-Item -LiteralPath $linkTarget -Force } }
                }
                'run' { $p = $val -split '\s+'; Invoke-Action $Installer $p[0] $p[1] $p[2] }
                'run-unknown-option' { $p = $val -split '\s+'; Invoke-Action $Installer $p[0] $p[1] $p[2] -Bogus }
                default { if ($key -like 'expect-*') { $expects.Add("$key|$val") } else { $failures.Add("unknown directive '$key'") } }
            }
            if ($notRun) { break }
        }

        if (-not $notRun) {
            $output = [System.IO.File]::ReadAllText($script:log)
            foreach ($e in $expects) {
                $key = $e.Substring(0, $e.IndexOf('|')); $val = $e.Substring($e.IndexOf('|') + 1)
                $left = ($val -split ' = ', 2)[0].Trim(); $right = if ($val.Contains(' = ')) { ($val -split ' = ', 2)[1] } else { '' }
                switch ($key) {
                    'expect-exit'    { if ("$script:lastExit" -ne $val) { $failures.Add("exit $script:lastExit, expected $val") } }
                    'expect-exit-nonzero' { if ("$script:lastExit" -eq '0') { $failures.Add("exit 0, expected a failure") } }
                    'expect-file'    { if (-not (Test-Path -LiteralPath (Resolve-CasePath $val))) { $failures.Add("missing $val") } }
                    'expect-absent'  { if (Test-Path -LiteralPath (Resolve-CasePath $val)) { $failures.Add("should not exist: $val") } }
                    'expect-content' { $got = Read-Text (Resolve-CasePath $left); if ($got -cne $right) { $failures.Add("$left holds '$got', expected '$right'") } }
                    'expect-same-as-package' {
                        $t = Resolve-CasePath $left
                        if (-not (Test-Path -LiteralPath $t) -or (Get-Sha $t) -ne (Get-Sha (Join-Path $pkg ($right -replace '/', '\')))) { $failures.Add("$left differs from the package's $right") }
                    }
                    'expect-tree-as-package' {
                        # Every file below that folder of the package is installed below the path,
                        # byte for byte. A package folder with no file in it proves nothing.
                        $t = Resolve-CasePath $left
                        $src = Join-Path $pkg ($right.Trim() -replace '/', '\')
                        $files = @(if (Test-Path -LiteralPath $src -PathType Container) { Get-ChildItem -LiteralPath $src -Recurse -File -Force })
                        if ($files.Count -eq 0) { $failures.Add("the package has no file under $($right.Trim())") }
                        foreach ($f in $files) {
                            $rel = $f.FullName.Substring($src.Length).TrimStart('\')
                            $d = Join-Path $t $rel
                            if (-not (Test-Path -LiteralPath $d -PathType Leaf) -or (Get-Sha $d) -ne (Get-Sha $f.FullName)) {
                                $failures.Add("$left/$($rel -replace '\\', '/') differs from the package's $($right.Trim())/$($rel -replace '\\', '/')")
                            }
                        }
                    }
                    { $_ -in 'expect-backup', 'expect-no-backup', 'expect-backup-content', 'expect-backup-link-target' } {
                        # A symlinked destination's backup has a <backup>.link-target file beside it, recording
                        # where the link pointed; it matches the same pattern but is not a backup itself.
                        $t = Resolve-CasePath $left
                        $backups = @(Get-ChildItem -LiteralPath (Split-Path -Parent $t) -Force -ErrorAction SilentlyContinue |
                                     Where-Object { $_.Name -like ((Split-Path -Leaf $t) + '.qa-instinct-backup-*') -and $_.Name -notlike '*.link-target' })
                        if ($key -eq 'expect-backup' -and $backups.Count -lt 1) { $failures.Add("no backup of $val") }
                        if ($key -eq 'expect-no-backup' -and $backups.Count -gt 0) { $failures.Add("unexpected backup of $val") }
                        if ($key -eq 'expect-backup-content') {
                            $got = if ($backups.Count) { Read-Text $backups[-1].FullName } else { '' }
                            if ($got -cne $right) { $failures.Add("backup of $left holds '$got', expected '$right'") }
                        }
                        if ($key -eq 'expect-backup-link-target') {
                            $want = Resolve-CasePath $right.Trim()
                            $got = if ($backups.Count) { Read-Text "$($backups[-1].FullName).link-target" } else { $null }
                            if ($got -cne $want) { $failures.Add("backup of $left records link target '$got', expected '$want'") }
                        }
                    }
                    { $_ -in 'expect-manifest', 'expect-no-manifest' } {
                        $p = $val -split '\s+', 3; $mf = "$(Get-ScopeRoot $p[0])\$manifestName"
                        $pattern = '^[0-9a-f]{64}  ' + [regex]::Escape($p[1]) + '  ' + [regex]::Escape($p[2]) + '$'
                        $found = $false
                        if (Test-Path -LiteralPath $mf) {
                            foreach ($m in [System.IO.File]::ReadAllLines($mf, $utf8)) {
                                if ($m.TrimStart([char]0xFEFF).TrimEnd("`r") -cmatch $pattern) { $found = $true }
                            }
                        }
                        if ($key -eq 'expect-manifest' -and -not $found) { $failures.Add("manifest lacks: $val") }
                        if ($key -eq 'expect-no-manifest' -and $found) { $failures.Add("manifest should not record: $val") }
                    }
                    'expect-output'    { if (-not $output.Contains($val)) { $failures.Add("output lacks '$val'") } }
                    'expect-output-lists-package' {
                        # Every match of the pattern in that folder of the package under test is
                        # named in the output: without .md, and with a leading / for a command.
                        $p = $val -split '\s+'; $folder = Join-Path $pkg ($p[0] -replace '/', '\')
                        $listed = if ($p[1].EndsWith('/')) { @(Get-ChildItem -LiteralPath $folder -Directory | Where-Object { $_.Name -like $p[1].TrimEnd('/') }) }
                                     else { @(Get-ChildItem -LiteralPath $folder -File | Where-Object { $_.Name -like $p[1] }) }
                        foreach ($m in $listed) {
                            $text = $m.Name -replace '\.md$', ''
                            if ((Split-Path -Leaf $folder) -eq 'commands') { $text = "/$text" }
                            if (-not $output.Contains($text)) { $failures.Add("output does not list $text") }
                        }
                    }
                    'expect-no-output' { if ($output.Contains($val)) { $failures.Add("output contains '$val'") } }
                    default { $failures.Add("unknown expectation '$key'") }
                }
            }
        }
        if ($failures.Count -gt 0) {
            $tail = @(Get-Content -LiteralPath $script:log -Tail 6 -Encoding UTF8) | ForEach-Object { "        $_" }
            $failures.Add("output (last 6 lines):`n" + ($tail -join "`n"))
        }
    } finally {
        $env:USERPROFILE = $savedProfile; $env:HOME = $savedHome
        foreach ($u in $unreadable) {
            try { $item = Get-Item -LiteralPath $u -Force; $acl = $item.GetAccessControl('Access'); [void]$acl.RemoveAccessRule($script:denyRead); $item.SetAccessControl($acl) } catch { }
        }
        Get-ChildItem -LiteralPath $script:sb -Recurse -Force -ErrorAction SilentlyContinue |
            ForEach-Object { if (-not $_.PSIsContainer) { $_.IsReadOnly = $false } }
        Remove-Item -LiteralPath $script:sb -Recurse -Force -ErrorAction SilentlyContinue
    }
    return [pscustomobject]@{ NotRun = $notRun; Failures = $failures }
}

$installers = @('install.ps1', 'cli')
$total = 0; $failed = 0; $skipped = 0; $notRunCount = 0
Write-Host "Conformance: installers from $pkg"
foreach ($dir in (Get-ChildItem -LiteralPath $casesDir -Directory | Sort-Object Name)) {
    if ($Filter -and $dir.Name -notlike "*$Filter*") { continue }
    # The same reading as Read-Case: split on LF, no BOM, no CR.
    $conf = @(([System.IO.File]::ReadAllText("$($dir.FullName)\case.conf", $utf8).TrimStart([char]0xFEFF) -split "`n") | ForEach-Object { $_.TrimEnd("`r") })
    $name = ($conf | Where-Object { $_ -like 'name:*' } | Select-Object -First 1) -replace '^name:\s*', ''
    Write-Host "  $($dir.Name) - $name"
    foreach ($inst in $installers) {
        $skip = $conf | Where-Object { $_ -match ('^skip:\s*' + [regex]::Escape($inst) + '\s*' + $emDash) } | Select-Object -First 1
        if ($skip) {
            Write-Host ("    {0,-11} SKIP  {1}" -f $inst, ($skip -replace ('^skip:\s*' + [regex]::Escape($inst) + '\s*' + $emDash + '\s*'), ''))
            $skipped++; continue
        }
        $r = Invoke-Case $dir.FullName $inst
        if ($r.NotRun) {
            Write-Host ("    {0,-11} NOT RUN  {1}" -f $inst, $r.NotRun) -ForegroundColor Yellow
            $notRunCount++; continue
        }
        $total++
        if ($r.Failures.Count -eq 0) {
            Write-Host ("    {0,-11} pass" -f $inst)
        } else {
            Write-Host ("    {0,-11} FAIL" -f $inst) -ForegroundColor Red
            foreach ($f in $r.Failures) { Write-Host "      x $f" }
            $failed++
        }
    }
}
Write-Host ("Conformance: {0}/{1} passed, {2} failed, {3} skipped, {4} not run" -f ($total - $failed), $total, $failed, $skipped, $notRunCount)
if ($failed -gt 0) { exit 1 }
exit 0

# Requires -Version 5.1
#
# tests/conformance/test-runner.ps1 - tests the conformance runner itself, with the same checks as
# tests/conformance/test-runner.sh. A malformed case file (a path that climbs out of the sandbox or
# is absolute, a scope or editor the runner does not know, a line it cannot parse) must fail the
# case before anything is written, read or deleted, and a well-formed one must parse the same way
# in run.ps1 and run.sh. The cases are written at run time, outside cases\, so the real suite never
# runs them.
#
# Kept ASCII-only on purpose: Windows PowerShell 5.1 reads a script without a BOM as ANSI.

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$work = Join-Path $env:TEMP ('qa-runner-selftest-' + [guid]::NewGuid().ToString('N'))
$script:failures = 0
$script:n = 0
$savedTemp = $env:TEMP

# Runs one case through run.ps1 with the sandbox under $t\tmp, so a path that climbs two folders
# out of the project lands in $t\tmp, beside the canary. The body is written byte for byte.
function Invoke-One([string]$Name, [string]$Body) {
    $script:n++
    $script:t = Join-Path $work "t$($script:n)"
    $caseDir = Join-Path $script:t "cases\001-$Name"
    New-Item -ItemType Directory -Path (Join-Path $script:t 'tmp'), $caseDir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $script:t 'tmp\canary'), "CANARY`n")
    [System.IO.File]::WriteAllText((Join-Path $caseDir 'fixture.txt'), "FIXTURE TEXT`n")
    $bytes = New-Object System.Collections.Generic.List[byte]
    foreach ($ch in $Body.ToCharArray()) { $bytes.Add([byte][int]$ch) }
    [System.IO.File]::WriteAllBytes((Join-Path $caseDir 'case.conf'), $bytes.ToArray())
    $env:TEMP = Join-Path $script:t 'tmp'
    try {
        $script:out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$here\run.ps1" -Cases (Join-Path $script:t 'cases') 2>&1 | Out-String
        $script:status = $LASTEXITCODE
    } finally { $env:TEMP = $savedTemp }
}
function Add-Problem([string]$Message) { Write-Host "  x $Message"; $script:failures++ }

function Test-Rejected([string]$Name, [string]$Body, [string]$MustNotExist = '') {
    Invoke-One $Name $Body
    if ($script:status -eq 0) { Add-Problem "${Name}: the runner accepted a malformed case" }
    if (-not $script:out.Contains('malformed case')) { Add-Problem "${Name}: the runner did not report a malformed case" }
    $canary = Join-Path $script:t 'tmp\canary'
    # A canary the runner made unreadable cannot be read back: that is a change too.
    $canaryText = $null
    try { $canaryText = [System.IO.File]::ReadAllText($canary) } catch { $canaryText = $null }
    if ($canaryText -ne "CANARY`n") { Add-Problem "${Name}: the runner changed, deleted or locked a file outside its sandbox" }
    # A chmod leaves the content alone, so the attributes are part of "unchanged" too.
    if (Test-Path -LiteralPath $canary) { if ((Get-Item -LiteralPath $canary).IsReadOnly) { Add-Problem "${Name}: the runner changed the mode of a file outside its sandbox" } }
    if ($MustNotExist -and (Test-Path -LiteralPath (Join-Path $script:t "tmp\$MustNotExist"))) { Add-Problem "${Name}: the runner wrote $MustNotExist outside its sandbox" }
}
function Test-Accepted([string]$Name, [string]$Body) {
    Invoke-One $Name $Body
    if ($script:status -ne 0) { Add-Problem "${Name}: the runner rejected a well-formed case"; Write-Host $script:out }
}

$lf = "`n"; $cr = "`r"; $bom = [string][char]0xEF + [char]0xBB + [char]0xBF

Write-Host "Conformance runner self-test (PowerShell)"

# Paths: every path stays inside its scope's folder.
Test-Rejected 'seed-climbs-out' "name: x${lf}seed: project:../../escaped.txt = X${lf}" 'escaped.txt'
Test-Rejected 'drop-climbs-out' "name: x${lf}drop-manifest: project claude ../../canary${lf}"
Test-Rejected 'absolute-path' "name: x${lf}seed: home:/abs.txt = X${lf}"
Test-Rejected 'drive-path' "name: x${lf}seed: home:C:/abs.txt = X${lf}"
Test-Rejected 'backslash-path' "name: x${lf}seed: home:..\..\escaped.txt = X${lf}" 'escaped.txt'
Test-Rejected 'symlink-target-climbs-out' "name: x${lf}seed-symlink: project:link -> home:../../canary${lf}"
Test-Rejected 'package-path-climbs-out' "name: x${lf}seed-package: home:copy.txt = ../outside.txt${lf}"
Test-Rejected 'fixture-path-climbs-out' "name: x${lf}seed-fixture: home:copy.txt = ../../canary${lf}"
Test-Rejected 'manifest-path-absolute' "name: x${lf}seed-manifest: project claude /etc/hostname${lf}"
Test-Rejected 'manifest-entry-at-sandbox-root' "name: x${lf}seed-manifest: project claude ../output.log${lf}"
Test-Rejected 'legacy-manifest-bad-scope' "name: x${lf}legacy-manifest: global${lf}"
Test-Rejected 'legacy-manifest-link-climbs-out' "name: x${lf}legacy-manifest: project -> home:../../canary${lf}"
Test-Rejected 'expect-path-climbs-out' "name: x${lf}expect-absent: home:../../canary${lf}"
Test-Rejected 'readonly-climbs-out' "name: x${lf}seed-readonly: home:../../canary${lf}"
Test-Rejected 'unreadable-climbs-out' "name: x${lf}seed-unreadable: home:../../canary${lf}"
Test-Rejected 'crlf-climbs-out' "name: x${lf}seed-crlf: home:../../canary${lf}"
Test-Rejected 'dir-climbs-out' "name: x${lf}seed-dir: home:../../canary${lf}"
Test-Rejected 'expect-content-climbs-out' "name: x${lf}expect-content: home:../../canary = CANARY${lf}"
Test-Rejected 'backup-link-target-climbs-out' "name: x${lf}expect-backup-link-target: project:a.md = home:../../canary${lf}"
Test-Rejected 'package-listing-climbs-out' "name: x${lf}expect-output-lists-package: ../.. *${lf}"
Test-Rejected 'package-tree-climbs-out' "name: x${lf}expect-tree-as-package: project:t = ../..${lf}"

# Scopes and editors: only the runner's own; a typo never falls back to some other folder.
Test-Rejected 'drop-unknown-scope' "name: x${lf}drop-manifest: projct claude canary${lf}"
Test-Rejected 'run-unknown-scope' "name: x${lf}run: install projct claude${lf}"
Test-Rejected 'run-unknown-operation' "name: x${lf}run: instal project claude${lf}"
Test-Rejected 'run-extra-word' "name: x${lf}run: install project claude now${lf}"
Test-Rejected 'run-without-scope' "name: x${lf}run: update${lf}"
Test-Rejected 'manifest-unknown-editor' "name: x${lf}expect-manifest: project claud .claude/x.md${lf}"
Test-Rejected 'path-unknown-scope' "name: x${lf}expect-file: projct:.claude${lf}"

# Lines: one grammar, and anything outside it is an error.
Test-Rejected 'no-colon' "name: x${lf}this line has no colon${lf}"
Test-Rejected 'unknown-directive' "name: x${lf}seed-everything: project:x.txt = y${lf}"
Test-Rejected 'unspaced-equals' "name: x${lf}seed: project:a.txt=X${lf}"
Test-Rejected 'unspaced-arrow' "name: x${lf}seed-symlink: project:a->home:b${lf}"
Test-Rejected 'exit-not-a-number' "name: x${lf}expect-exit: zero${lf}"
Test-Rejected 'exit-nonzero-takes-no-value' "name: x${lf}expect-exit-nonzero: 1${lf}"
Test-Rejected 'skip-without-reason' "name: x${lf}skip:${lf}"
# A lone CR does not end a line in either runner, so this is one line with an unknown directive.
Test-Rejected 'lone-cr' "expect-everything: x${cr}name: y${lf}"

# Well-formed cases, every setup directive and every expectation that needs no installer run.
Test-Accepted 'bom' "${bom}name: a case file saved with a BOM${lf}expect-absent: project:nothing-here${lf}"
Test-Accepted 'crlf' "name: a case file saved with CRLF${cr}${lf}# a comment${cr}${lf}${cr}${lf}expect-absent: project:nothing-here${cr}${lf}"
Test-Accepted 'manifest-entry-in-the-other-scope' "name: x${lf}seed: home:v.txt = V${lf}seed-manifest: project claude ../home/v.txt${lf}expect-manifest: project claude ../home/v.txt${lf}"
# A path in a manifest line is plain text: a dot matches a dot, not any character.
Test-Accepted 'manifest-lookup-is-literal' ("name: expect-manifest and drop-manifest compare a path as text${lf}seed: project:a.md = A${lf}seed: project:aXmd = B${lf}seed-manifest: project claude aXmd${lf}expect-no-manifest: project claude a.md${lf}seed-manifest: project claude a.md${lf}drop-manifest: project claude a.md${lf}expect-manifest: project claude aXmd${lf}expect-no-manifest: project claude a.md${lf}")
# A manifest path is the rest of the line, so it may hold a space (plan 053 I11).
Test-Accepted 'manifest-path-with-a-space' ("name: a manifest path may hold a space${lf}seed: project:my notes/a  b.md = A${lf}seed: project:my notes/c d.md = C${lf}" +
    "seed-manifest: project cursor my notes/a  b.md${lf}seed-manifest: project cursor my notes/c d.md${lf}drop-manifest: project cursor my notes/c d.md${lf}" +
    "expect-manifest: project cursor my notes/a  b.md${lf}expect-no-manifest: project cursor my notes/a b.md${lf}expect-no-manifest: project cursor my notes/c d.md${lf}" +
    "expect-file: project:my notes/a  b.md${lf}expect-absent: project:my notes/c d.md${lf}")
Test-Rejected 'manifest-path-with-a-space-climbs-out' "name: x${lf}drop-manifest: project claude ../../canary x${lf}"
Test-Accepted 'package-tree' ("name: a copy of a package folder matches it file for file${lf}seed-package: home:t/check-test-evidence.sh = .claude/hooks/check-test-evidence.sh${lf}" +
    "seed-package: home:t/validate-tc-format.sh = .claude/hooks/validate-tc-format.sh${lf}expect-tree-as-package: home:t = .claude/hooks${lf}")
# The editor of a run line may be left out: the installer then gets no editor option (plan 061 B1).
Test-Accepted 'legacy-manifest' "name: legacy-manifest renames the manifest to its 4.x name${lf}seed: project:a.md = A${lf}seed-manifest: project claude a.md${lf}legacy-manifest: project${lf}expect-file: project:.qa-skills-manifest${lf}expect-absent: project:.qa-instinct-manifest${lf}"
Test-Accepted 'run-without-editor' "name: a run line may name no editor${lf}run: uninstall project${lf}expect-exit: 0${lf}"
Test-Accepted 'every-directive' (@(
        'name: every directive', 'seed: project:a/b.txt = HELLO', 'seed-fixture: project:fx.txt = fixture.txt',
        'expect-content: project:fx.txt = FIXTURE TEXT', 'seed: project:crlf.txt = LINE', 'seed-crlf: project:crlf.txt',
        'seed-readonly: project:a/b.txt', 'seed: project:locked.txt = LOCKED', 'seed-unreadable: project:locked.txt',
        'seed-package: home:pkg.md = .claude/rules/security-qa.md',
        'seed-manifest: home claude pkg.md', 'seed: project:gone.txt = BYE', 'seed-manifest: project claude gone.txt',
        'drop-manifest: project claude gone.txt', 'seed-dir: project:empty/folder', 'expect-file: project:empty/folder',
        'expect-exit: 0', 'expect-absent: project:gone.txt',
        'expect-content: project:a/b.txt = HELLO', 'expect-same-as-package: home:pkg.md = .claude/rules/security-qa.md',
        'expect-manifest: home claude pkg.md', 'expect-no-manifest: project claude gone.txt',
        'expect-no-backup: project:a/b.txt', 'expect-no-output: anything at all') -join $lf)

Get-ChildItem -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue |
    ForEach-Object { if (-not $_.PSIsContainer) { $_.IsReadOnly = $false } }
Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
if ($script:failures -eq 0) { Write-Host "Conformance runner self-test: $($script:n) checks passed"; exit 0 }
Write-Host "Conformance runner self-test: $($script:failures) problem(s)"
exit 1

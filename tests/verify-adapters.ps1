# verify-adapters.ps1 - Assert that generate-adapters.ps1 actually produced usable adapters.
#
# PowerShell counterpart to tests/verify-adapters.sh. CI used to "verify" adapters/ with a
# git-status check against a gitignored directory, so a broken compiler could ship silently.
# tests/verify-adapters.sh closed that hole for the bash compiler; this closes it for the
# PowerShell one, which the Windows job never checked.
#
# Since plan 047 the adapters are each editor's always-on rule files plus one Agent Skills tree.
# Every always-on file must stay within 85 percent of its editor's documented limit; the same
# checks, and the same counts, as tests/verify-adapters.sh. Kept ASCII-only on purpose.

$ErrorActionPreference = 'Stop'

$RepoDir   = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$OutDir    = Join-Path $RepoDir 'adapters'
$ClaudeDir = Join-Path $RepoDir '.claude'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$script:Failed = $false
function Write-Failure {
    param([string]$Message)
    Write-Host "X $Message" -ForegroundColor Red
    $script:Failed = $true
}

function Get-Out([string]$Rel) { Join-Path $OutDir ($Rel -replace '/', '\') }
function Get-RelOut([string]$Path) { $Path.Substring($OutDir.Length + 1) -replace '\\', '/' }

# Bytes, characters (bytes less the UTF-8 continuation bytes, as verify-adapters.sh counts them)
# and lines (newline bytes) of a file.
function Get-Measure {
    param([string]$Path, [string]$Measure)
    return (Get-ByteCount ([System.IO.File]::ReadAllBytes($Path)) $Measure)
}
function Get-ByteCount {
    param([byte[]]$Bytes, [string]$Measure)
    if ($Measure -eq 'bytes') { return $Bytes.Length }
    $n = 0
    foreach ($x in $Bytes) {
        if ($Measure -eq 'chars') { if (($x -band 0xC0) -ne 0x80) { $n++ } }
        elseif ($x -eq 10) { $n++ }
    }
    return $n
}

# A source file without its leading YAML frontmatter, ending with a newline, as the generator
# writes it.
function Get-Body {
    param([string]$Path)
    $content = [System.IO.File]::ReadAllText($Path, $Utf8NoBom) -replace '(?s)\A---\r?\n.*?\r?\n---\r?\n', ''
    if ($content -ne '' -and -not $content.EndsWith("`n")) { $content += "`n" }
    return $content
}

$Rules = @(Get-ChildItem -LiteralPath (Join-Path $ClaudeDir 'rules') -File | Where-Object { $_.Extension -ceq '.md' } |
    ForEach-Object { $_.Name.Substring(0, $_.Name.Length - 3) })

# Every file the installers install, by editor. Keep in step with .qa-instinct-editor-map.
$Expected = @('copilot/rules/copilot-instructions.md', 'universal/AGENTS.md', 'universal/CLAUDE.md')
foreach ($key in @('cursor', 'windsurf', 'cline', 'antigravity')) {
    $ext = if ($key -eq 'cursor') { 'mdc' } else { 'md' }
    $Expected += "$key/rules/qa-instinct.$ext"
    foreach ($rule in $Rules) { $Expected += "$key/rules/qa-instinct-$rule.$ext" }
}

# Skills: one per command, agent and skill, and qa-rules.
$Skills = @()
foreach ($folder in @('commands', 'agents')) {
    $Skills += @(Get-ChildItem -LiteralPath (Join-Path $ClaudeDir $folder) -File | Where-Object { $_.Extension -ceq '.md' } |
        ForEach-Object { $_.Name.Substring(0, $_.Name.Length - 3) })
}
$Skills += @(Get-ChildItem -LiteralPath (Join-Path $ClaudeDir 'skills') -Directory |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } | ForEach-Object { $_.Name })
$Skills += 'qa-rules'

Write-Host "Verifying generated adapters in $OutDir"

# Encoding: the sources are UTF-8 without a BOM, and so must every generated file be. Probe with
# the dispatcher's first non-ASCII line, which its skill must carry intact, read from the source
# so this script stays ASCII-only.
$probeSource = [System.IO.File]::ReadAllText((Join-Path $ClaudeDir 'commands\qa.md'), $Utf8NoBom)
$Probe = ($probeSource -split "`n" | Where-Object { $_ -match '[^\x00-\x7F]' } | Select-Object -First 1)
if ($Probe) { $Probe = $Probe.TrimEnd([char]13) }
$allFiles = @(Get-ChildItem -LiteralPath $OutDir -Recurse -File -Force -ErrorAction SilentlyContinue)
foreach ($f in $allFiles) {
    $b = [System.IO.File]::ReadAllBytes($f.FullName)
    if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) { Write-Failure "$(Get-RelOut $f.FullName) starts with a UTF-8 BOM" }
    # The merged file of plan 043 and before is gone; no section of it may come back.
    if (Select-String -LiteralPath $f.FullName -Pattern '^<!-- source: ' -CaseSensitive -Quiet) {
        Write-Failure "$(Get-RelOut $f.FullName) carries a merged-file section marker (<!-- source: ...)"
    }
}
$qaSkill = Get-Out 'skills/qa/SKILL.md'
if ($Probe -and -not ((Test-Path -LiteralPath $qaSkill) -and [System.IO.File]::ReadAllText($qaSkill, $Utf8NoBom).Contains($Probe))) {
    Write-Failure "skills/qa/SKILL.md does not contain the dispatcher's non-ASCII text intact (encoding garbled)"
}

# --- The rule files -----------------------------------------------------------
foreach ($rel in $Expected) {
    if (-not (Test-Path -LiteralPath (Get-Out $rel) -PathType Leaf)) { Write-Failure "missing: $rel" }
}
foreach ($key in @('cursor', 'windsurf', 'cline', 'antigravity')) {
    $rulesDir = Get-Out "$key/rules"
    if (-not (Test-Path -LiteralPath $rulesDir)) { continue }
    foreach ($f in @(Get-ChildItem -LiteralPath $rulesDir -File)) {
        $lines = [System.IO.File]::ReadAllText($f.FullName, $Utf8NoBom) -split "`n"
        $rel = Get-RelOut $f.FullName
        switch ($key) {
            'cursor' {
                if ($lines[0] -cne '---') { Write-Failure "$rel is missing its MDC frontmatter" }
                if (-not ($lines -ccontains 'alwaysApply: true')) { Write-Failure "$rel is not alwaysApply: true" }
                if (-not ($lines | Where-Object { $_.StartsWith('description: ', [System.StringComparison]::Ordinal) })) { Write-Failure "$rel has no description" }
            }
            { $_ -in 'windsurf', 'antigravity' } {
                if ($lines.Count -lt 2 -or $lines[1] -cne 'trigger: always_on') { Write-Failure "$rel is not trigger: always_on" }
            }
            'cline' {
                if ($lines[0] -ceq '---') { Write-Failure "$rel must have no frontmatter (always active)" }
            }
        }
    }
    $guidelines = @(Get-ChildItem -LiteralPath $rulesDir -File -Filter 'qa-instinct-testing-guidelines.*')
    if ($guidelines.Count -eq 0 -or -not (Select-String -LiteralPath $guidelines[0].FullName -Pattern 'ISTQB' -SimpleMatch -Quiet)) {
        Write-Failure "$key rules lack the testing guidelines"
    }
}
foreach ($rel in @('copilot/rules/copilot-instructions.md', 'universal/AGENTS.md', 'universal/CLAUDE.md')) {
    $file = Get-Out $rel
    if (-not (Test-Path -LiteralPath $file)) { continue }
    $lines = [System.IO.File]::ReadAllText($file, $Utf8NoBom) -split "`n"
    foreach ($rule in $Rules) {
        if (-not ($lines -ccontains "<!-- qa-instinct-$rule -->")) { Write-Failure "$rel has no section for the $rule rule" }
    }
    if ($lines[0] -ceq '---') { Write-Failure "$rel must not carry IDE frontmatter" }
}
foreach ($u in @('AGENTS', 'CLAUDE')) {
    $file = Get-Out "universal/$u.md"
    if ((Test-Path -LiteralPath $file) -and -not ((Get-Content -LiteralPath $file -TotalCount 1) -match '^<!-- QA Instinct')) {
        Write-Failure "universal/$u.md is missing its header comment"
    }
}

# --- The skills tree ------------------------------------------------------------
foreach ($name in $Skills) {
    $file = Get-Out "skills/$name/SKILL.md"
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Write-Failure "missing skill: skills/$name/SKILL.md"; continue }
    # The Agent Skills format: name equal to the folder, lowercase words joined by hyphens, at
    # most 64 characters; a description of 1 to 1,024 characters; at most 500 lines.
    $lines = [System.IO.File]::ReadAllText($file, $Utf8NoBom) -split "`n"
    $gotName = @($lines | Where-Object { $_.StartsWith('name: ', [System.StringComparison]::Ordinal) } | Select-Object -First 1)
    if ($gotName.Count -eq 0 -or $gotName[0].Substring(6) -cne $name) { Write-Failure "skills/$name/SKILL.md does not name itself '$name'" }
    if ($name -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { Write-Failure "skill name '$name' is not lowercase words joined by hyphens" }
    if ($name.Length -gt 64) { Write-Failure "skill name '$name' is longer than 64 characters" }
    $desc = @($lines | Where-Object { $_.StartsWith('description: ', [System.StringComparison]::Ordinal) } | Select-Object -First 1)
    $descChars = 0
    if ($desc.Count -gt 0) {
        $d = $desc[0].Substring(13)
        if ($d.StartsWith('"')) { $d = $d.Substring(1) }
        if ($d.EndsWith('"')) { $d = $d.Substring(0, $d.Length - 1) }
        $descChars = Get-ByteCount $Utf8NoBom.GetBytes($d) 'chars'
    }
    if ($descChars -lt 1 -or $descChars -gt 1024) { Write-Failure "skills/$name has a description of $descChars characters (1 to 1,024)" }
    $n = Get-Measure $file 'lines'
    if ($n -gt 500) { Write-Failure "skills/$name/SKILL.md has $n lines (at most 500)" }
    # Every skill names its author under metadata, whatever it was generated from (plan 060).
    $close = [Array]::IndexOf($lines, '---', 1)
    if ($close -lt 2 -or -not ($lines[1..($close - 1)] -ccontains '  author: Marco Amaral')) {
        Write-Failure "skills/$name/SKILL.md has no 'author: Marco Amaral' under metadata"
    }
}
$actualSkills = @(Get-ChildItem -LiteralPath (Get-Out 'skills') -Directory -ErrorAction SilentlyContinue).Count
if ($actualSkills -ne $Skills.Count) { Write-Failure "expected $($Skills.Count) skill folders, found $actualSkills" }

# qa-reference keeps its references as they are; qa-rules holds each rule without frontmatter.
$refs = @(Get-ChildItem -LiteralPath (Join-Path $ClaudeDir 'skills\qa-reference\references') -File | Where-Object { $_.Extension -ceq '.md' })
foreach ($src in $refs) {
    $copy = Get-Out "skills/qa-reference/references/$($src.Name)"
    if (-not (Test-Path -LiteralPath $copy) -or (Get-FileHash -LiteralPath $copy).Hash -ne (Get-FileHash -LiteralPath $src.FullName).Hash) {
        Write-Failure "skills/qa-reference/references/$($src.Name) differs from its source"
    }
}
if (@(Get-ChildItem -LiteralPath (Get-Out 'skills/qa-reference/references') -File -ErrorAction SilentlyContinue).Count -ne $refs.Count) {
    Write-Failure "skills/qa-reference/references does not hold exactly the $($refs.Count) references"
}
foreach ($rule in $Rules) {
    $copy = Get-Out "skills/qa-rules/references/$rule.md"
    if (-not (Test-Path -LiteralPath $copy) -or [System.IO.File]::ReadAllText($copy, $Utf8NoBom) -cne (Get-Body (Join-Path $ClaudeDir "rules\$rule.md"))) {
        Write-Failure "skills/qa-rules/references/$rule.md is not the $rule rule without its frontmatter"
    }
}
if (@(Get-ChildItem -LiteralPath (Get-Out 'skills/qa-rules/references') -File -ErrorAction SilentlyContinue).Count -ne $Rules.Count) {
    Write-Failure "skills/qa-rules/references does not hold exactly the $($Rules.Count) rules"
}

# Nothing unexpected, so a new file cannot be added without being covered here.
$skillFiles = @(Get-ChildItem -LiteralPath (Get-Out 'skills') -Recurse -File -Force -ErrorAction SilentlyContinue).Count
$expectedCount = $Expected.Count + $skillFiles
if ($allFiles.Count -ne $expectedCount) { Write-Failure "expected $expectedCount adapter files, found $($allFiles.Count)" }

# --- Always-on size budgets: 85 percent of each editor's documented limit (plan 047) ----------
# The limits and why each budget is what it is: see tests/verify-adapters.sh.
Write-Host "Always-on size per editor (largest file / all files; budget):"
function Test-Budget {
    param([string]$Key, [string]$Measure, [int]$PerFile, [int]$Total, [string]$Label)
    $max = 0; $maxName = ''; $sum = 0; $count = 0
    foreach ($f in @(Get-ChildItem -LiteralPath (Get-Out "$Key/rules") -File)) {
        $n = Get-Measure $f.FullName $Measure
        $sum += $n; $count++
        if ($n -gt $max) { $max = $n; $maxName = $f.Name }
        if ($PerFile -gt 0 -and $n -gt $PerFile) { Write-Failure "$Key/rules/$($f.Name) is $n $Measure, over the budget of $PerFile" }
    }
    if ($Total -gt 0 -and $sum -gt $Total) { Write-Failure "$Key rules total $sum $Measure, over the budget of $Total" }
    Write-Host ('  {0,-12} {1,2} files, largest {2} {3} ({4}), all {5} {3}; {6}' -f $Key, $count, $max, $Measure, $maxName, $sum, $Label)
}
Test-Budget 'windsurf'    'chars' 10200 0     'budget 10,200 chars per file'
Test-Budget 'cursor'      'lines' 425   0     'budget 425 lines per file'
Test-Budget 'copilot'     'lines' 850   0     'budget 850 lines'
Test-Budget 'antigravity' 'bytes' 20400 0     'budget 20,400 bytes per file'
Test-Budget 'antigravity' 'chars' 0     68000 'budget 68,000 chars in all'
Test-Budget 'cline'       'chars' 0     0     'no limit stated'
$agents = Get-Out 'universal/AGENTS.md'
$n = Get-Measure $agents 'bytes'
if ($n -gt 27852) { Write-Failure "universal/AGENTS.md is $n bytes, over the budget of 27,852" }
Write-Host ('  {0,-12} {1,2} files, {2} bytes, {3} lines; budget 27,852 bytes' -f 'universal', 1, $n, (Get-Measure $agents 'lines'))

# --- The generator refuses a broken source tree (plan 054) ----------------------
# A command or an agent with no id, and a skill name two sources share, on planted trees.
Write-Host 'Generator refusals (tests/fixtures/generator-errors.txt):'
& (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'test-generator-errors.ps1')
if ($LASTEXITCODE -ne 0) { Write-Failure 'generate-adapters.ps1 does not refuse a broken source tree as tests/fixtures/generator-errors.txt says' }

if ($script:Failed) {
    Write-Host "Adapter verification failed." -ForegroundColor Red
    exit 1
}

Write-Host "All $($allFiles.Count) adapter files generated correctly ($($Skills.Count) skills, every editor within budget)." -ForegroundColor Green
exit 0

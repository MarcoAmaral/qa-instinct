# generate-adapters.ps1 - Generate every non-Claude editor's files from the modular .claude/ sources
# (plan 047): each editor's always-on rule files, one Agent Skills tree all of them share, and the
# universal AGENTS.md and CLAUDE.md. Byte for byte what generate-adapters.sh writes.

[CmdletBinding()]
param(
    [switch]$Clean,
    [switch]$NoColor
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ClaudeDir = Join-Path $ScriptDir '.claude'
$OutDir    = Join-Path $ScriptDir 'adapters'

# --- Helpers ------------------------------------------------------------------
function Write-Info    { param([string]$Msg)
    if ($NoColor) { Write-Host "[INFO]  $Msg" }
    else          { Write-Host "[INFO]  $Msg" -ForegroundColor Yellow }
}
function Write-Ok      { param([string]$Msg)
    if ($NoColor) { Write-Host "[OK]    $Msg" }
    else          { Write-Host "[OK]    $Msg" -ForegroundColor Green }
}
function Write-Err     { param([string]$Msg)
    if ($NoColor) { Write-Host "[ERR]   $Msg" }
    else          { Write-Host "[ERR]   $Msg" -ForegroundColor Red }
}

# --- Validate source ----------------------------------------------------------
$MainSource = Join-Path $ClaudeDir 'commands/qa.md'
if (-not (Test-Path $MainSource)) {
    Write-Err "Source file not found: $MainSource"
    exit 1
}

# The sources are UTF-8 without a BOM. Windows PowerShell 5.1 reads such a file as the ANSI code
# page unless told otherwise, and its -Encoding UTF8 writes a BOM; both corrupted the adapters
# (every emoji and accented letter became mojibake). Read and write UTF-8 explicitly, no BOM, and
# build every text with LF line endings, as bash writes it.
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
# The script itself is read as ANSI by Windows PowerShell 5.1 too, so text it writes uses no
# literal non-ASCII characters; the em dash is built from its code point.
$EmDash = [char]0x2014
$Bt = [char]0x60   # a backtick, which is PowerShell's escape character inside double quotes

function Read-Utf8 { param([string]$Path) [System.IO.File]::ReadAllText($Path, $Utf8NoBom) }

function Write-Utf8 {
    param([string]$Path, [string]$Content)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

# A source file without its leading YAML frontmatter, ending with a newline, as generate-adapters.sh's
# awk prints it. An unclosed frontmatter block does not match and the file is returned unchanged.
function Get-Body {
    param([string]$Path)
    $content = (Read-Utf8 $Path) -replace '(?s)\A---\r?\n.*?\r?\n---\r?\n', ''
    if ($content -ne '' -and -not $content.EndsWith("`n")) { $content += "`n" }
    return $content
}

# One top-level line of a file's frontmatter, as written, for the key given; '' when absent.
function Get-FrontmatterLine {
    param([string]$Path, [string]$Key)
    $lines = (Read-Utf8 $Path) -split "`n"
    if ($lines.Count -eq 0 -or $lines[0].TrimEnd([char]13) -cne '---') { return '' }
    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].TrimEnd([char]13)
        if ($line -ceq '---') { return '' }
        if ($line.StartsWith("${Key}: ", [System.StringComparison]::Ordinal)) { return $line }
    }
    return ''
}

# Names in ordinal (byte) order, matching generate-adapters.sh's C-locale globs. Sort-Object is
# culture-aware and ignores hyphens.
function Get-Ordinal {
    param([string[]]$Names)
    $sorted = [string[]]@($Names)
    [Array]::Sort($sorted, [System.StringComparer]::Ordinal)
    return ,$sorted
}

# --- Validate the skill names -------------------------------------------------
# Every command and agent becomes the skill its id names, every skill folder keeps its own name,
# and qa-rules is generated. A command or an agent with no id would become adapters/skills//SKILL.md,
# and two sources with one name would write the same folder, the later silently replacing the
# earlier. Both are refused before anything is written or removed, in a fixed order and with the
# same words as generate-adapters.sh (tests/fixtures/generator-errors.txt).
$script:SkillOwners = New-Object System.Collections.ArrayList   # @(name, source) per name claimed
$script:Problems = 0

function Add-SkillName {
    param([string]$Name, [string]$Source)
    foreach ($owner in $script:SkillOwners) {
        if ($owner[0] -ceq $Name) {
            Write-Err "Skill name '$Name' is used by both $($owner[1]) and $Source; one would overwrite the other in adapters/skills/$Name"
            $script:Problems++
            return
        }
    }
    [void]$script:SkillOwners.Add(@($Name, $Source))
}

foreach ($folder in @('commands', 'agents')) {
    $dir = Join-Path $ClaudeDir $folder
    if (-not (Test-Path -LiteralPath $dir)) { continue }
    foreach ($name in (Get-Ordinal @(Get-ChildItem -LiteralPath $dir -File | Where-Object { $_.Extension -ceq '.md' } | ForEach-Object { $_.Name }))) {
        $line = Get-FrontmatterLine (Join-Path $dir $name) 'id'
        $id = if ($line.Length -gt 4) { $line.Substring(4) } else { '' }
        if ($id -eq '') {
            Write-Err ".claude/$folder/$name has no id in its frontmatter; a command or an agent needs one to name its skill"
            $script:Problems++
            continue
        }
        Add-SkillName $id ".claude/$folder/$name"
    }
}
foreach ($name in (Get-Ordinal @(Get-ChildItem -LiteralPath (Join-Path $ClaudeDir 'skills') -Directory | ForEach-Object { $_.Name }))) {
    if (Test-Path -LiteralPath (Join-Path (Join-Path (Join-Path $ClaudeDir 'skills') $name) 'SKILL.md')) {
        Add-SkillName $name ".claude/skills/$name/"
    }
}
Add-SkillName 'qa-rules' 'the generated qa-rules skill'
if ($script:Problems -gt 0) {
    Write-Err 'Nothing was written to adapters/.'
    exit 1
}

# --- Clean --------------------------------------------------------------------
if ($Clean -and (Test-Path $OutDir)) {
    Write-Info "Removing $OutDir"
    Remove-Item -Recurse -Force $OutDir
}

Write-Info "Source: .claude/{commands,agents,skills,rules}"
Write-Info "Output: $OutDir"

# The rule names, in byte order of their file names: every .claude/rules/<rule>.md.
$RuleFiles = Get-Ordinal @(Get-ChildItem -LiteralPath (Join-Path $ClaudeDir 'rules') -File |
    Where-Object { $_.Extension -ceq '.md' } | ForEach-Object { $_.Name })
$Rules = @($RuleFiles | ForEach-Object { $_.Substring(0, $_.Length - 3) })

function Get-RuleBody { param([string]$Rule) Get-Body (Join-Path (Join-Path $ClaudeDir 'rules') "$Rule.md") }

# --- The Agent Skills tree ----------------------------------------------------
# One folder per command, agent and skill, named by its id, the same for every editor (plan 047).
# A command or an agent becomes a skill: its name, its description line as written, its id and
# the package's author under metadata (as every skill source carries them), then its text
# without the frontmatter (an agent's model and tools are Claude Code fields and are dropped). The skills are copied as they are, references included. qa-rules
# holds every rule as a reference, so an install with no rule files still reaches them.
$SkillsOut = Join-Path $OutDir 'skills'
if (-not (Test-Path -LiteralPath $SkillsOut)) { New-Item -ItemType Directory -Path $SkillsOut -Force | Out-Null }

foreach ($folder in @('commands', 'agents')) {
    $dir = Join-Path $ClaudeDir $folder
    if (-not (Test-Path -LiteralPath $dir)) { continue }
    foreach ($file in @(Get-ChildItem -LiteralPath $dir -File | Where-Object { $_.Extension -ceq '.md' })) {
        $id = (Get-FrontmatterLine $file.FullName 'id').Substring(4)
        $text = "---`nname: $id`n" + (Get-FrontmatterLine $file.FullName 'description') + "`nmetadata:`n  id: $id`n  author: Marco Amaral`n---`n" + (Get-Body $file.FullName)
        Write-Utf8 (Join-Path (Join-Path $SkillsOut $id) 'SKILL.md') $text
    }
}

foreach ($skill in @(Get-ChildItem -LiteralPath (Join-Path $ClaudeDir 'skills') -Directory)) {
    if (-not (Test-Path -LiteralPath (Join-Path $skill.FullName 'SKILL.md'))) { continue }
    foreach ($f in @(Get-ChildItem -LiteralPath $skill.FullName -Recurse -File -Force)) {
        $rel = $f.FullName.Substring($skill.FullName.Length).TrimStart('\', '/')
        $dest = Join-Path (Join-Path $SkillsOut $skill.Name) $rel
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        [System.IO.File]::WriteAllBytes($dest, [System.IO.File]::ReadAllBytes($f.FullName))
    }
}

$qaRules = New-Object System.Text.StringBuilder
[void]$qaRules.Append("---`nname: qa-rules`n")
[void]$qaRules.Append("description: `"QA Instinct's QA rules, one file each: testing guidelines, code style, security, accessibility, evidence, tools, context discovery, commits and linting. Read the rule a pointer names (the <rule> rule) when this editor has not loaded the rule files, as in a global install.`"`n")
[void]$qaRules.Append("metadata:`n  id: qa-rules`n  author: Marco Amaral`n---`n# QA Instinct rules`n`n")
[void]$qaRules.Append("Each rule of the package is a file in this skill's ${Bt}references${Bt} folder. A project install`n")
[void]$qaRules.Append("also puts every rule in the editor's own rules folder, always on, as ${Bt}qa-instinct-<rule>${Bt}; a`n")
[void]$qaRules.Append("global install has no rules folder, so read the rule a pointer names from here.`n`n")
[void]$qaRules.Append("| Rule | File |`n| --- | --- |`n")
foreach ($rule in $Rules) { [void]$qaRules.Append("| ${Bt}$rule${Bt} | ${Bt}references/$rule.md${Bt} |`n") }
Write-Utf8 (Join-Path $SkillsOut 'qa-rules\SKILL.md') $qaRules.ToString()
foreach ($rule in $Rules) {
    Write-Utf8 (Join-Path $SkillsOut "qa-rules\references\$rule.md") (Get-RuleBody $rule)
}

# The skill names, in byte order, for the index.
$SkillNames = Get-Ordinal @(Get-ChildItem -LiteralPath $SkillsOut -Directory | ForEach-Object { $_.Name })

# --- The index and the rule files --------------------------------------------
# The index (qa-instinct) is the one rule the package adds: it says the package is installed, how
# this editor invokes a skill, and how a pointer in the package's text resolves. $Key is the editor
# key; copilot and universal hold the rules in the same file, under a marker line each.
function Get-IndexBody {
    param([string]$Key)
    $invoke = switch ($Key) {
        'cursor'      { "type ${Bt}/qa-cases${Bt} in Agent chat" }
        'windsurf'    { "type ${Bt}@qa-cases${Bt}" }
        'copilot'     { "type ${Bt}/qa-cases${Bt} in chat" }
        'cline'       { "type ${Bt}/qa-cases${Bt}" }
        'antigravity' { 'ask for it by name, for example "use the qa-cases skill"' }
        default       { "ask for it by name; an editor that lists skills as slash commands also takes ${Bt}/qa-cases${Bt}" }
    }
    if ($Key -eq 'copilot' -or $Key -eq 'universal') {
        $rulesAre = "Its rules follow in this file, each under a ${Bt}<!-- qa-instinct-<rule> -->${Bt} line, and are always on."
        $rulePointer = "the section under ${Bt}<!-- qa-instinct-<rule> -->${Bt} in this file"
    }
    else {
        $rulesAre = "Its rules are the rule files named ${Bt}qa-instinct-<rule>${Bt}, always on."
        $rulePointer = "the rule file ${Bt}qa-instinct-<rule>${Bt}"
    }
    $list = ($SkillNames | ForEach-Object { "$Bt$_$Bt" }) -join ', '
    $lines = @(
        '# QA Instinct',
        '',
        'QA Instinct, Senior QA Engineer guidance based on ISTQB CTFL v4.0, is installed here.',
        $rulesAre,
        'Everything else is an Agent Skill of the same name, loaded when its description matches the',
        "task, or when you $invoke.",
        '',
        "Skills: $list.",
        '',
        "How a pointer in the package's text resolves:",
        '',
        "- a command such as ${Bt}/qa-cases${Bt} is the skill ${Bt}qa-cases${Bt};",
        "- an agent such as ${Bt}qa-groomer${Bt} is the skill ${Bt}qa-groomer${Bt}: where the text dispatches it, read",
        '  that skill and do its stage yourself;',
        "- `"the ${Bt}qa-reference${Bt} skill's ${Bt}references/<file>.md${Bt}`" is that file in the ${Bt}references${Bt}",
        "  folder of the ${Bt}qa-reference${Bt} skill, never a path under the project root;",
        "- `"the ${Bt}<rule>${Bt} rule`" is $rulePointer, and the same text is",
        "  ${Bt}references/<rule>.md${Bt} in the ${Bt}qa-rules${Bt} skill;",
        "- a script such as ${Bt}check-test-evidence.sh${Bt} is not installed for this editor: apply its checks",
        '  by reading the files, and say that it was not run.'
    )
    return (($lines -join "`n") + "`n")
}

# The editor's frontmatter for one rule file.
function Get-RuleFront {
    param([string]$Key, [string]$Name)
    switch ($Key) {
        'cursor' {
            $description = if ($Name -eq 'qa-instinct') { 'QA Instinct: how its rules and skills are installed in this editor' }
                           else { 'QA Instinct rule: ' + $Name.Substring('qa-instinct-'.Length) }
            return "---`ndescription: `"$description`"`nalwaysApply: true`n---`n"
        }
        { $_ -in 'windsurf', 'antigravity' } { return "---`ntrigger: always_on`n---`n" }
    }
    return ''
}

# The index, then every rule under its marker line.
function Get-RulesInOneFile {
    param([string]$Key)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append((Get-IndexBody $Key))
    foreach ($rule in $Rules) { [void]$sb.Append("`n<!-- qa-instinct-$rule -->`n").Append((Get-RuleBody $rule)) }
    return $sb.ToString()
}

foreach ($key in @('cursor', 'windsurf', 'cline', 'antigravity')) {
    $ext = if ($key -eq 'cursor') { 'mdc' } else { 'md' }
    $rulesOut = Join-Path (Join-Path $OutDir $key) 'rules'
    Write-Utf8 (Join-Path $rulesOut "qa-instinct.$ext") ((Get-RuleFront $key 'qa-instinct') + (Get-IndexBody $key))
    foreach ($rule in $Rules) {
        Write-Utf8 (Join-Path $rulesOut "qa-instinct-$rule.$ext") ((Get-RuleFront $key "qa-instinct-$rule") + (Get-RuleBody $rule))
    }
}

Write-Utf8 (Join-Path $OutDir 'copilot\rules\copilot-instructions.md') (Get-RulesInOneFile 'copilot')

# --- Universal ----------------------------------------------------------------
# AGENTS.md and CLAUDE.md, copied by hand: the header, the index and the rules, no IDE
# frontmatter. The skills are adapters/skills/, copied by hand beside them.
$UniversalHeader = (@(
    "<!-- QA Instinct $EmDash Senior QA Engineer (ISTQB CTFL v4.0)",
    '     Universal adapter: no IDE-specific frontmatter. The rules are below; every command, skill',
    "     and agent is an Agent Skill in the package's adapters/skills/ folder.",
    '     Compatible with: Claude Code (CLAUDE.md / --agents-file), Codex, Devin,',
    '     GitHub Copilot (paste into instructions), and any agent that reads markdown.',
    '     Install globally (copy only if you have no such file; otherwise merge it by hand):',
    '       cp adapters/universal/CLAUDE.md ~/.claude/CLAUDE.md        # Claude Code global',
    '       cp adapters/universal/AGENTS.md ~/AGENTS.md                # Codex / Devin / others',
    '       cp adapters/universal/AGENTS.md <project-root>/AGENTS.md   # Project-level universal',
    '     Then copy the folders in adapters/skills/ to the folder your agent reads skills from.',
    '-->',
    '',
    ''
) -join "`n")
foreach ($u in @('AGENTS', 'CLAUDE')) {
    Write-Utf8 (Join-Path $OutDir "universal\$u.md") ($UniversalHeader + (Get-RulesInOneFile 'universal'))
}

# --- Summary ------------------------------------------------------------------
Write-Host ''
$header = '{0,-50} {1,8}' -f 'FILE', 'SIZE'
if ($NoColor) { Write-Host $header }
else          { Write-Host $header -ForegroundColor Yellow }
Write-Host ('-' * 60)
$all = @(Get-ChildItem -LiteralPath $OutDir -Recurse -File -Force)
$rels = Get-Ordinal @($all | ForEach-Object { $_.FullName.Substring($OutDir.Length + 1) -replace '\\', '/' })
foreach ($rel in $rels) {
    if ($rel.StartsWith('skills/')) { continue }
    Write-Host ('{0,-50} {1,6} B' -f $rel, (Get-Item -LiteralPath (Join-Path $OutDir $rel)).Length)
}
$skillFiles = @(Get-ChildItem -LiteralPath $SkillsOut -Recurse -File -Force).Count
Write-Host ('{0,-50} {1,6} files' -f "skills/ ($($SkillNames.Count) skills)", $skillFiles)

Write-Host ''
Write-Ok "All adapters generated ($($all.Count) files)"

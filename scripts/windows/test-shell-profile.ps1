# Requires PowerShell 7, chezmoi, and g++.exe or clang++.exe on PATH.
# Tests rendered compiler functions without loading machine-specific profile setup.
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$profileSource = Join-Path $repoRoot 'chezmoi/Documents/PowerShell/profile.ps1.tmpl'
$rendered = & chezmoi --source $repoRoot execute-template --file $profileSource
if ($LASTEXITCODE -ne 0) { throw 'Profile template rendering failed' }
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput(
    ($rendered -join "`n"), [ref]$tokens, [ref]$parseErrors
)
if ($parseErrors) { throw ($parseErrors | Out-String) }

$compilers = @('g++', 'clang++') | Where-Object {
    Get-Command "$_.exe" -CommandType Application -ErrorAction SilentlyContinue
}
if (-not $compilers) { throw 'Install g++.exe or clang++.exe before running this test' }

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir | Out-Null
try {
    $source = @(
        '#ifndef PROFILE_ARGUMENT'
        '#error Missing compiler argument'
        '#endif'
        'static_assert(PROFILE_ARGUMENT == 17, "Incorrect argument");'
        'int main() { return 0; }'
    )
    $sourcePath = Join-Path $tempDir 'source with spaces.cpp'
    Set-Content -LiteralPath $sourcePath -Value $source -Encoding utf8

    foreach ($compiler in $compilers) {
        $definition = $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq $compiler
        }, $true)
        if (-not $definition) { throw "Missing $compiler function" }
        . ([scriptblock]::Create($definition.Extent.Text))

        $source | & $compiler -DPROFILE_ARGUMENT=17 -x c++ -fsyntax-only -
        if ($LASTEXITCODE -ne 0) { throw "$compiler lost valid pipeline input or arguments" }

        # Empty input compiles successfully: rejecting invalid input proves stdin
        # reached the compiler rather than being discarded by the function.
        'int main( {' | & $compiler -x c++ -fsyntax-only - 2>$null
        if ($LASTEXITCODE -eq 0) { throw "$compiler discarded invalid pipeline input" }

        & $compiler -DPROFILE_ARGUMENT=17 -fsyntax-only $sourcePath
        if ($LASTEXITCODE -ne 0) { throw "$compiler broke ordinary file compilation" }
        Write-Output "$compiler`: pipeline input, failure status, arguments, and file compilation OK"
    }
} finally {
    Remove-Item -LiteralPath $tempDir -Recurse -Force
}

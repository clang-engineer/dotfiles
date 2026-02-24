$input = $input | ConvertFrom-Json

# 현재 작업 디렉토리
$cwd = $input.cwd

# Git 브랜치
$branch = try { git -C $cwd --no-optional-locks rev-parse --abbrev-ref HEAD 2>$null } catch { '' }

# 컨텍스트 사용량
$used = $input.context_window.used_percentage
$totalIn = $input.context_window.total_input_tokens
$totalOut = $input.context_window.total_output_tokens

# 기본 표시: cwd + branch
$parts = "cwd: $cwd"
if ($branch) { $parts += " | branch: $branch" }

# 컨텍스트 사용량 추가 (데이터가 있을 때만)
if ($used) {
    $ctxInfo = "ctx: ${used}%"
    if ($totalIn -and $totalOut) {
        $ctxInfo += " (in: $totalIn / out: $totalOut)"
    }
    $parts += " | $ctxInfo"
}

Write-Output $parts

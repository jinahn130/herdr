. (Join-Path $PSScriptRoot "Herdr.Common.ps1")

try {
    $paneId = Get-HerdrActivePaneId
    $agentJson = Invoke-HerdrJson -Arguments @("agent", "get", $paneId)
    $agent = $agentJson.result.agent
    $agentKind = [string]$agent.agent
    $session = Get-HerdrPropertyValue -Object $agent -Name "agent_session"
    $sessionId = [string](Get-HerdrPropertyValue -Object $session -Name "value")

    if ([string]::IsNullOrWhiteSpace($sessionId)) {
        throw "This agent does not have a registered prompt history yet."
    }

    if ($agentKind -eq "codex") {
        $historyPath = Join-Path $HOME ".codex\history.jsonl"
    } elseif ($agentKind -in @("claude", "claude-code")) {
        $historyPath = Join-Path $HOME ".claude\history.jsonl"
    } else {
        throw "Prompt history is available for Codex and Claude agents."
    }

    if (-not (Test-Path -LiteralPath $historyPath)) {
        throw "No prompt history file was found for this agent."
    }

    $prompts = @()
    foreach ($line in Get-Content -LiteralPath $historyPath -Encoding UTF8) {
        try {
            $entry = $line | ConvertFrom-Json
        } catch {
            continue
        }

        if ($agentKind -eq "codex") {
            if ([string]$entry.session_id -ne $sessionId -or [string]::IsNullOrWhiteSpace([string]$entry.text)) {
                continue
            }
            $prompts += [pscustomobject]@{ Timestamp = $entry.ts; Text = [string]$entry.text; Milliseconds = $false }
        } else {
            if ([string]$entry.sessionId -ne $sessionId -or [string]::IsNullOrWhiteSpace([string]$entry.display)) {
                continue
            }
            $prompts += [pscustomobject]@{ Timestamp = $entry.timestamp; Text = [string]$entry.display; Milliseconds = $true }
        }
    }

    Write-Host "PROMPT HISTORY - NEWEST FIRST" -ForegroundColor Cyan
    Write-Host ("Agent: {0}" -f ([string]$agent.name)) -ForegroundColor DarkGray
    Write-Host

    $recent = @($prompts | Select-Object -Last 10)
    [array]::Reverse($recent)
    if ($recent.Count -eq 0) {
        Write-Host "No sent prompts were found for this session."
    } else {
        for ($index = 0; $index -lt $recent.Count; $index++) {
            $prompt = $recent[$index]
            $timestamp = ""
            try {
                $epoch = [int64]$prompt.Timestamp
                if ($prompt.Milliseconds) {
                    $timestamp = [DateTimeOffset]::FromUnixTimeMilliseconds($epoch).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss")
                } else {
                    $timestamp = [DateTimeOffset]::FromUnixTimeSeconds($epoch).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss")
                }
            } catch {
                $timestamp = "unknown time"
            }
            Write-Host ("[{0}] {1}" -f ($index + 1), $timestamp) -ForegroundColor Yellow
            Write-Host $prompt.Text
            Write-Host
        }
    }

    Wait-HerdrPopup
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Wait-HerdrPopup
    exit 1
}

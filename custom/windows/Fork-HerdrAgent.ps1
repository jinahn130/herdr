param(
    [ValidateSet("right", "down", "tab")]
    [string]$Placement = "right"
)

. (Join-Path $PSScriptRoot "Herdr.Common.ps1")

try {
    $paneId = Get-HerdrActivePaneId
    $agentJson = Invoke-HerdrJson -Arguments @("agent", "get", $paneId)
    $agent = $agentJson.result.agent
    $agentKind = [string]$agent.agent
    $session = Get-HerdrPropertyValue -Object $agent -Name "agent_session"
    $sessionKind = [string](Get-HerdrPropertyValue -Object $session -Name "kind")
    $sessionId = [string](Get-HerdrPropertyValue -Object $session -Name "value")

    if ($agentKind -notin @("codex", "claude", "claude-code")) {
        throw "Alt+F can fork a focused Codex or Claude agent."
    }
    if ($sessionKind -ne "id" -or [string]::IsNullOrWhiteSpace($sessionId)) {
        throw "This agent does not have a resumable session yet. Send its first prompt, then retry."
    }

    if ($Placement -eq "tab") {
        if ([string]::IsNullOrWhiteSpace($env:HERDR_ACTIVE_WORKSPACE_ID)) {
            throw "Herdr could not identify the active workspace."
        }
        $cwd = if ([string]::IsNullOrWhiteSpace($env:HERDR_ACTIVE_PANE_CWD)) {
            $PWD.Path
        } else {
            $env:HERDR_ACTIVE_PANE_CWD
        }
        $created = Invoke-HerdrJson -Arguments @(
            "tab", "create", "--workspace", $env:HERDR_ACTIVE_WORKSPACE_ID,
            "--cwd", $cwd, "--label", "fork", "--focus"
        )
        $newPaneId = [string]$created.result.root_pane.pane_id
    } else {
        $created = Invoke-HerdrJson -Arguments @(
            "pane", "split", $paneId, "--direction", $Placement, "--focus"
        )
        $newPaneId = [string]$created.result.pane.pane_id
    }

    if ([string]::IsNullOrWhiteSpace($newPaneId)) {
        throw "Herdr did not return the new pane ID."
    }

    Start-Sleep -Seconds 1
    $nameKind = if ($agentKind -eq "codex") { "codex" } else { "claude" }
    $name = "{0}-fork-{1}" -f $nameKind, (Get-Date -Format "HHmmss")

    if ($agentKind -eq "codex") {
        $start = Invoke-HerdrRaw -Arguments @(
            "agent", "start", $name, "--kind", "codex", "--pane", $newPaneId,
            "--timeout", "60000", "--", "--no-alt-screen",
            "--dangerously-bypass-approvals-and-sandbox", "fork", $sessionId
        )
    } else {
        $start = Invoke-HerdrRaw -Arguments @(
            "agent", "start", $name, "--kind", "claude", "--pane", $newPaneId,
            "--timeout", "60000", "--", "--dangerously-skip-permissions",
            "--resume", $sessionId, "--fork-session"
        )
    }

    if ($start.ExitCode -ne 0) {
        throw $start.Output
    }
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Wait-HerdrPopup
    exit 1
}

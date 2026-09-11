. (Join-Path $PSScriptRoot "Herdr.Common.ps1")

try {
    $paneId = Get-HerdrActivePaneId
    $workspaceId = $env:HERDR_ACTIVE_WORKSPACE_ID
    $tabId = $env:HERDR_ACTIVE_TAB_ID

    if ([string]::IsNullOrWhiteSpace($workspaceId) -or [string]::IsNullOrWhiteSpace($tabId)) {
        $paneJson = Invoke-HerdrJson -Arguments @("pane", "get", $paneId)
        $workspaceId = [string]$paneJson.result.pane.workspace_id
        $tabId = [string]$paneJson.result.pane.tab_id
    }
    if ([string]::IsNullOrWhiteSpace($workspaceId) -or [string]::IsNullOrWhiteSpace($tabId)) {
        throw "Herdr could not identify the focused tab."
    }

    $agentJson = $null
    try {
        $agentJson = Invoke-HerdrJson -Arguments @("agent", "get", $paneId)
    } catch {
        $agentJson = $null
    }

    $tabsJson = Invoke-HerdrJson -Arguments @("tab", "list", "--workspace", $workspaceId)
    $tabs = @($tabsJson.result.tabs)
    $shownCount = [Math]::Min($tabs.Count, 9)

    Write-Host "MOVE THIS PANE TO A TAB" -ForegroundColor Cyan
    Write-Host
    for ($index = 0; $index -lt $shownCount; $index++) {
        $marker = if ([string]$tabs[$index].tab_id -eq $tabId) { "*" } else { " " }
        Write-Host ("  {0}  {1,-24} {2}" -f ($index + 1), [string]$tabs[$index].label, $marker)
    }
    if ($tabs.Count -gt 9) {
        Write-Host "  Only the first 9 tabs are shown."
    }
    Write-Host "  N  Create a new named tab"
    Write-Host
    Write-Host -NoNewline "Choose (Esc cancels): "
    $key = [Console]::ReadKey($true)
    Write-Host $key.KeyChar

    if ($key.Key -eq [ConsoleKey]::Escape) {
        exit 0
    }

    if ($key.KeyChar -eq "n" -or $key.KeyChar -eq "N") {
        $defaultLabel = "moved"
        if ($null -ne $agentJson -and -not [string]::IsNullOrWhiteSpace([string]$agentJson.result.agent.name)) {
            $defaultLabel = [string]$agentJson.result.agent.name
        }
        $newLabel = Read-HerdrEditableValue -Prompt "New tab name: " -InitialValue $defaultLabel
        if ($null -eq $newLabel -or [string]::IsNullOrWhiteSpace($newLabel)) {
            exit 0
        }
        $moveJson = Invoke-HerdrJson -Arguments @(
            "pane", "move", $paneId, "--new-tab", "--workspace", $workspaceId,
            "--label", $newLabel, "--focus"
        )
    } elseif ($key.KeyChar -match "^[1-9]$") {
        $selectedIndex = [int]::Parse([string]$key.KeyChar) - 1
        if ($selectedIndex -ge $tabs.Count) {
            throw "That tab does not exist."
        }
        $selectedTabId = [string]$tabs[$selectedIndex].tab_id
        if ($selectedTabId -eq $tabId) {
            exit 0
        }
        $moveJson = Invoke-HerdrJson -Arguments @(
            "pane", "move", $paneId, "--tab", $selectedTabId,
            "--split", "right", "--focus"
        )
    } else {
        throw "Press a displayed number, N, or Esc."
    }

    if ($null -ne $agentJson) {
        $session = Get-HerdrPropertyValue -Object $agentJson.result.agent -Name "agent_session"
        $agentKind = [string]$agentJson.result.agent.agent
        $movedPaneId = [string]$moveJson.result.move_result.pane.pane_id
        if ([string]::IsNullOrWhiteSpace($movedPaneId)) {
            $movedPaneId = $paneId
        }
        $sessionKind = [string](Get-HerdrPropertyValue -Object $session -Name "kind")
        $sessionValue = [string](Get-HerdrPropertyValue -Object $session -Name "value")
        if ($sessionKind -eq "id" -and -not [string]::IsNullOrWhiteSpace($sessionValue)) {
            $sessionSource = [string](Get-HerdrPropertyValue -Object $session -Name "source")
            $source = if ([string]::IsNullOrWhiteSpace($sessionSource)) {
                "herdr:$agentKind"
            } else {
                $sessionSource
            }
            $report = Invoke-HerdrRaw -Arguments @(
                "pane", "report-agent-session", $movedPaneId,
                "--source", $source, "--agent", $agentKind,
                "--agent-session-id", $sessionValue
            )
            if ($report.ExitCode -ne 0) {
                throw $report.Output
            }
        }
    }
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Wait-HerdrPopup
    exit 1
}

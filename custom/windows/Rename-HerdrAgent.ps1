. (Join-Path $PSScriptRoot "Herdr.Common.ps1")

try {
    $paneId = Get-HerdrActivePaneId
    $agentJson = Invoke-HerdrJson -Arguments @("agent", "get", $paneId)
    $currentName = [string]$agentJson.result.agent.name
    $newName = Read-HerdrEditableValue -Prompt "Agent name: " -InitialValue $currentName

    if ($null -eq $newName -or $newName -eq $currentName) {
        exit 0
    }
    if ($newName -ne "" -and $newName -notmatch "^[a-z][a-z0-9_-]{0,31}$") {
        throw "Use 1-32 lowercase letters, numbers, _ or -; start with a letter."
    }

    $renameArgs = if ($newName -eq "") {
        @("agent", "rename", $paneId, "--clear")
    } else {
        @("agent", "rename", $paneId, $newName)
    }

    $rename = Invoke-HerdrRaw -Arguments $renameArgs
    if ($rename.ExitCode -ne 0) {
        for ($attempt = 0; $attempt -lt 70; $attempt++) {
            Start-Sleep -Seconds 1
            try {
                $agentJson = Invoke-HerdrJson -Arguments @("agent", "get", $paneId)
            } catch {
                # A newly forked agent can briefly be absent while Herdr registers
                # its replacement process. Keep waiting for the same pane.
                continue
            }

            $launchPending = Get-HerdrPropertyValue -Object $agentJson.result.agent -Name "launch_pending"
            if ($null -ne $launchPending -and [bool]$launchPending) {
                continue
            }

            $rename = Invoke-HerdrRaw -Arguments $renameArgs
            if ($rename.ExitCode -eq 0) {
                break
            }
        }
    }

    if ($rename.ExitCode -ne 0) {
        throw $rename.Output
    }
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Wait-HerdrPopup
    exit 1
}

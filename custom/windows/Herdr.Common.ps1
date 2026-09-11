Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HerdrExecutable {
    if (-not [string]::IsNullOrWhiteSpace($env:HERDR_BIN_PATH)) {
        return $env:HERDR_BIN_PATH
    }
    return "herdr"
}

function Invoke-HerdrRaw {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $herdr = Get-HerdrExecutable
    $output = (& $herdr @Arguments 2>&1 | Out-String).TrimEnd()
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = $output
    }
}

function Invoke-HerdrJson {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $result = Invoke-HerdrRaw -Arguments $Arguments
    if ($result.ExitCode -ne 0) {
        throw $result.Output
    }
    if ([string]::IsNullOrWhiteSpace($result.Output)) {
        throw "Herdr returned no JSON output."
    }
    return $result.Output | ConvertFrom-Json
}

function Get-HerdrActivePaneId {
    if ([string]::IsNullOrWhiteSpace($env:HERDR_ACTIVE_PANE_ID)) {
        throw "Focus a Herdr pane first."
    }
    return $env:HERDR_ACTIVE_PANE_ID
}

function Get-HerdrPropertyValue {
    param(
        [AllowNull()][object]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }
    return $property.Value
}

function Read-HerdrEditableValue {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [AllowEmptyString()][string]$InitialValue = ""
    )

    Write-Host -NoNewline $Prompt
    Write-Host -NoNewline $InitialValue
    $value = $InitialValue

    while ($true) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Escape) {
            Write-Host
            return $null
        }
        if ($key.Key -eq [ConsoleKey]::Enter) {
            Write-Host
            return $value
        }
        if ($key.Key -eq [ConsoleKey]::Backspace) {
            if ($value.Length -gt 0) {
                $value = $value.Substring(0, $value.Length - 1)
                Write-Host -NoNewline "`b `b"
            }
            continue
        }
        if (-not [char]::IsControl($key.KeyChar)) {
            $value += $key.KeyChar
            Write-Host -NoNewline $key.KeyChar
        }
    }
}

function Wait-HerdrPopup {
    param([string]$Message = "Press Enter or Esc to close...")

    Write-Host
    Write-Host -NoNewline $Message
    while ($true) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Enter -or $key.Key -eq [ConsoleKey]::Escape) {
            Write-Host
            return
        }
    }
}

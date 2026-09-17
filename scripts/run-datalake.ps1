$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

$cleanupRequired = $false
$cleanupFailed = $false
$originalControlCMode = [Console]::TreatControlCAsInput

try {
    $cleanupRequired = $true
    & docker compose up -d --remove-orphans
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose failed to start (exit code $LASTEXITCODE)."
    }

    Write-Host ''
    Write-Host '[YiDataLake] Services are running:'
    Write-Host '  Jupyter:       http://localhost:8888'
    Write-Host '  MinIO Console: http://localhost:9001'
    Write-Host '  Iceberg REST:  http://localhost:8181'
    Write-Host ''
    Write-Host '[YiDataLake] Press Ctrl+C once to shut down all project containers.'

    # Reading Ctrl+C as a key avoids cmd.exe's "Terminate batch job" prompt.
    [Console]::TreatControlCAsInput = $true
    while ($true) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            $isControlC =
                $key.Key -eq [ConsoleKey]::C -and
                ($key.Modifiers -band [ConsoleModifiers]::Control)

            if ($isControlC) {
                break
            }
        }

        Start-Sleep -Milliseconds 100
    }
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    $cleanupFailed = $true
}
finally {
    [Console]::TreatControlCAsInput = $originalControlCMode

    if ($cleanupRequired) {
        Write-Host ''
        Write-Host '[YiDataLake] Closing all project containers and networks...'
        & docker compose down --remove-orphans
        if ($LASTEXITCODE -ne 0) {
            Write-Host '[ERROR] Cleanup failed. Run: docker compose down --remove-orphans' -ForegroundColor Red
            $cleanupFailed = $true
        }
        else {
            Write-Host '[YiDataLake] All project containers are closed. Data volumes were preserved.'
        }
    }
}

if ($cleanupFailed) {
    exit 1
}

exit 0

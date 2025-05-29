<#
.SYNOPSIS
    Retrieves meaningful logon/logoff/shutdown/sleep events with CSV export to local Documents folder.

.DESCRIPTION
    Gathers specific Event IDs from System and Security logs and saves the results to a timestamped CSV file
    in the *actual* C:\Users\<UserName>\Documents path (avoiding OneDrive redirection).
    
.NOTES
    Requires Administrator privileges to access the Security log.
#>

param (
    [int]$daysBack = 30
)

# =========================
# Define Time Range
# =========================
$startTime = (Get-Date).AddDays(-$daysBack)
$now = Get-Date
Write-Host "`n[INFO] Searching logs from $startTime to $now..." -ForegroundColor Cyan

# =========================
# Friendly Event ID Mapping (Only Lock/Unlock Events)
# =========================
$friendlyEventMap = @{
    4800 = "Workstation locked"
    4801 = "Workstation unlocked"
    4802 = "Screen saver invoked"
    4803 = "Screen saver dismissed"
}

$eventIds = $friendlyEventMap.Keys
$logNames = @("Security")
$allEvents = @()

# =========================
# Fetch Events
# =========================
foreach ($log in $logNames) {
    foreach ($eventId in $eventIds) {
        try {
            Write-Host "[INFO] Reading Event ID $eventId from '$log' log..." -ForegroundColor DarkCyan

            $events = Get-WinEvent -FilterHashtable @{
                LogName = $log
                Id = $eventId
                StartTime = $startTime
            } -ErrorAction Stop

            $allEvents += $events
        }
        catch {
            Write-Host "[WARNING] Failed to get Event ID $eventId from '$log'. $_" -ForegroundColor Yellow
        }
    }
}

# =========================
# Display Summary
# =========================
if ($allEvents.Count -eq 0) {
    Write-Host "[WARNING] No relevant events found in the specified time range." -ForegroundColor Yellow
    return
}

Write-Host "[SUCCESS] Found $($allEvents.Count) events matching criteria." -ForegroundColor Green

# =========================
# Process for CSV Export
# =========================
$processedEvents = $allEvents |
    Sort-Object TimeCreated |
    Select-Object `
        TimeCreated,
        Id,
        ProviderName,
        @{ Name = "Action"; Expression = {
            if ($friendlyEventMap.ContainsKey($_.Id)) {
                $friendlyEventMap[$_.Id]
            } else {
                "Other"
            }
        }},
        @{ Name = "Details"; Expression = {
            ($_.Message -split "`n")[0]
        }}

# =========================
# Export to CSV - Local Documents
# =========================
try {
    $timestamp = $now.ToString("yyyy-MM-dd_HHmmss")
    $userProfile = $env:USERPROFILE
    $localDocPath = Join-Path $userProfile "Documents"
    $reportFolder = Join-Path $localDocPath "LogonReports"
    $csvPath = Join-Path $reportFolder "EventLog_Report_$timestamp.csv"

    if (-not (Test-Path $reportFolder)) {
        New-Item -Path $reportFolder -ItemType Directory -Force | Out-Null
    }

    $processedEvents | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

    Write-Host "`n[SUCCESS] Exported results to: $csvPath" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Failed to export CSV report: $($_.Exception.Message)" -ForegroundColor Red
}

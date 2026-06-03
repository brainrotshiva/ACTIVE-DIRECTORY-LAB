# event-monitor.ps1
# Monitor key Windows Security Event IDs in real time
# Run on Domain Controller as Administrator

$watchEvents = @(4625, 4768, 4769, 4672, 4624, 4776, 7045)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AD Security Event Monitor" -ForegroundColor Cyan
Write-Host "  Watching Event IDs: $($watchEvents -join ', ')" -ForegroundColor Cyan
Write-Host "  Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

$eventDescriptions = @{
    4625 = "Failed Logon (Brute Force?)"
    4768 = "Kerberos TGT Request (AS-REP Roast?)"
    4769 = "Kerberos Service Ticket (Kerberoast?)"
    4672 = "Special Privileges Assigned (Priv Esc?)"
    4624 = "Successful Logon"
    4776 = "NTLM Authentication (Pass the Hash?)"
    7045 = "New Service Installed (Persistence?)"
}

while ($true) {
    foreach ($id in $watchEvents) {
        $events = Get-WinEvent -FilterHashtable @{
            LogName   = 'Security'
            Id        = $id
            StartTime = (Get-Date).AddSeconds(-10)
        } -ErrorAction SilentlyContinue

        foreach ($event in $events) {
            $color = if ($id -in @(4625,4768,4769,4776,7045)) { "Red" } else { "Yellow" }
            Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] " -NoNewline -ForegroundColor Gray
            Write-Host "Event $id — $($eventDescriptions[$id])" -ForegroundColor $color
            Write-Host "  $($event.Message.Split("`n")[0])" -ForegroundColor DarkGray
        }
    }
    Start-Sleep -Seconds 10
}

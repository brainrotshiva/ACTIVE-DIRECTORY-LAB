# hardening.ps1
# Active Directory hardening script
# Run on Domain Controller as Administrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Active Directory Hardening Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Disable LLMNR
Write-Host "`n[*] Disabling LLMNR..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" `
  -Name "EnableMulticast" -Value 0 -Type DWord -Force
Write-Host "[+] LLMNR disabled" -ForegroundColor Green

# 2. Disable NBT-NS (run on each machine via GPO ideally)
Write-Host "`n[*] Disabling NBT-NS..." -ForegroundColor Yellow
$adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
foreach ($adapter in $adapters) {
    $adapter.SetTcpipNetbios(2)
}
Write-Host "[+] NBT-NS disabled" -ForegroundColor Green

# 3. Enable SMB Signing
Write-Host "`n[*] Enabling SMB Signing..." -ForegroundColor Yellow
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force
Set-SmbClientConfiguration -RequireSecuritySignature $true -Force
Write-Host "[+] SMB Signing enabled" -ForegroundColor Green

# 4. Enable Audit Policies
Write-Host "`n[*] Configuring Audit Policies..." -ForegroundColor Yellow
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Account Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Authentication Service" /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable /failure:enable
Write-Host "[+] Audit policies configured" -ForegroundColor Green

# 5. Disable NTLM v1
Write-Host "`n[*] Disabling NTLMv1..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
  -Name "LmCompatibilityLevel" -Value 5 -Type DWord -Force
Write-Host "[+] NTLMv1 disabled" -ForegroundColor Green

# 6. Enable Protected Users group for privileged accounts
Write-Host "`n[*] Adding Domain Admins to Protected Users..." -ForegroundColor Yellow
$domainAdmins = Get-ADGroupMember "Domain Admins"
foreach ($admin in $domainAdmins) {
    Add-ADGroupMember -Identity "Protected Users" -Members $admin.SamAccountName -ErrorAction SilentlyContinue
    Write-Host "  [+] Added $($admin.SamAccountName) to Protected Users" -ForegroundColor Green
}

Write-Host "`n[+] Hardening complete!" -ForegroundColor Cyan
Write-Host "[!] Reboot recommended to apply all changes." -ForegroundColor Yellow

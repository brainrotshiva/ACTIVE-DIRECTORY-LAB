# create-users.ps1
# Bulk create Active Directory users for lab testing
# Run on Domain Controller as Administrator

$domain = "DC=brainrotshiva,DC=local"
$password = ConvertTo-SecureString "Password123!" -AsPlainText -Force

$users = @(
    @{Name="Alice Johnson"; Sam="ajohnson"; OU="IT"},
    @{Name="Bob Smith";     Sam="bsmith";   OU="IT"},
    @{Name="Carol White";   Sam="cwhite";   OU="HR"},
    @{Name="Dave Brown";    Sam="dbrown";   OU="HR"},
    @{Name="Eve Davis";     Sam="edavis";   OU="Finance"},
    @{Name="Frank Miller";  Sam="fmiller";  OU="Finance"}
)

foreach ($user in $users) {
    $first = $user.Name.Split(" ")[0]
    $last  = $user.Name.Split(" ")[1]
    New-ADUser `
        -Name $user.Name `
        -GivenName $first `
        -Surname $last `
        -SamAccountName $user.Sam `
        -UserPrincipalName "$($user.Sam)@brainrotshiva.local" `
        -Path "OU=$($user.OU),$domain" `
        -AccountPassword $password `
        -Enabled $true
    Write-Host "[+] Created user: $($user.Name)" -ForegroundColor Green
}

Write-Host "`n[*] All users created successfully!" -ForegroundColor Cyan

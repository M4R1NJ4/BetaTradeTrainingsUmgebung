$ErrorActionPreference = "Continue"

$CSVPath = "C:\Scripts\BetaTrade_Mitarbeiterliste_net07-in.csv"
###ersetzen durch manuelle abfrage
###pfad soll bereits übergeben werden
###schrittweise Ausgabe
###rückmeldeung eingelsene Datei -> summe der Nutzer
##dry run option -> rückmeldung vor löschen und überschreiben
###rückgabe der Liste nach Ausführen

Write-Host "Script starting..."
Write-Host "CSV path: $CSVPath"

$Domain = "net07.beta"
$DomainDN = "DC=net07,DC=beta"
$Password = ConvertTo-SecureString -String "BetaTrade2025!" -AsPlainText -Force

if (-not (Test-Path $CSVPath)) {
    Write-Host "ERROR: CSV file not found!"
    exit
}

$Users = @()
try {
    $Users = Import-Csv -Path $CSVPath
    Write-Host "CSV imported: $($Users.Count) users found"
}
catch {
    Write-Host "ERROR reading CSV: $_"
    exit
}

$OUs = @{
    "Corporate-HR"       = "OU=HR,OU=Corporate,$DomainDN"
    "Corporate-Finance"  = "OU=Finance,OU=Corporate,$DomainDN"
    "IT-Security"        = "OU=Security,OU=IT,$DomainDN"
    "IT-Support"         = "OU=Support,OU=IT,$DomainDN"
    "Marketing-Digital"  = "OU=Digital,OU=Marketing,$DomainDN"
    "Marketing-Events"   = "OU=Events,OU=Marketing,$DomainDN"
}

Write-Host ""
Write-Host "Creating users..."
Write-Host ""

$count = 0

foreach ($user in $Users) {
    $username = $user.Benutzername.Trim()
    $firstname = $user.Vorname.Trim()
    $lastname = $user.Nachname.Trim()
    $email = $user.Email.Trim()
    $dept = $user.Abteilung.Trim()
    $position = $user.Position.Trim()
    $phone = $user.Telefon.Trim()
    
    # UPN = username@net05.beta (NOT email!)
    $upn = "$username@$Domain"
    $displayname = "$firstname $lastname"
    $oupath = $OUs[$dept]
    
    try {
        $exists = Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction SilentlyContinue
        
        if ($exists) {
            Write-Host "[SKIP] $username already exists"
        }
        else {
            # FIXED: Correct syntax without "=" signs
            New-ADUser -SamAccountName $username `
                      -UserPrincipalName $upn `
                      -Name "$firstname $lastname" `
                      -GivenName $firstname `
                      -Surname $lastname `
                      -DisplayName $displayname `
                      -EmailAddress $email `
                      -Path $oupath `
                      -AccountPassword $Password `
                      -Enabled $true `
                      -PasswordNotRequired $false `
                      -Department $dept `
                      -Title $position `
                      -OfficePhone $phone `
                      -ErrorAction Stop
            
            Write-Host "[OK] $username created in $dept"
            $count++
        }
    }
    catch {
        Write-Host "[ERROR] $username - $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "=================================="
Write-Host "COMPLETED"
Write-Host "Created: $count users"
Write-Host "=================================="

# Pfad zur CSV-Datei
$csvPath = "C:\Pfad\zu\BetaTrade_Mitarbeiterliste.csv"

# Standard-Passwort für neue Benutzer
$defaultPassword = ConvertTo-SecureString "Welcome123!" -AsPlainText -Force

# CSV importieren
$users = Import-Csv -Path $csvPath

# Funktion zur Zuordnung von Abteilung zu OU
function Get-OU {
    param ([string]$Abteilung)

    if ($Abteilung -like "Corporate*") {
        return "OU=Corporate,DC=betatrade,DC=beta"
    } elseif ($Abteilung -like "IT*") {
        return "OU=IT,DC=betatrade,DC=beta"
    } elseif ($Abteilung -like "Marketing*") {
        return "OU=Marketing,DC=betatrade,DC=beta"
    } else {
        return "OU=Users,DC=betatrade,DC=beta"
    }
}

# Benutzeranlage
foreach ($user in $users) {
    # Telefonnummer bereinigen
    $phone = ($user.Telefon -replace '[^0-9+]', '')

    # OU bestimmen
    $ou = Get-OU $user.Abteilung

    # Prüfen, ob Benutzer bereits existiert
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($user.Benutzername)'" -ErrorAction SilentlyContinue)) {

        # Benutzer erstellen
        New-ADUser `
            -GivenName $user.Vorname `
            -Surname $user.Nachname `
            -SamAccountName $user.Benutzername `
            -UserPrincipalName $user.Email `
            -EmailAddress $user.Email `
            -Title $user.Position `
            -Department $user.Abteilung `
            -OfficePhone $phone `
            -AccountPassword $defaultPassword `
            -Path $ou `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        Write-Host "Benutzer $($user.Benutzername) wurde in $ou angelegt."
    } else {
        Write-Host "Benutzer $($user.Benutzername) existiert bereits."
    }
}

# ===========================================================
# BetaTrade Benutzeranlage aus CSV-Datei
# Ausführbar unter Benutzer: net07\student
# Ort: C:\Users\student\Downloads
# ===========================================================

# Pfade
$DownloadPath = "C:\Users\student\Downloads"
$csvPath = Join-Path $DownloadPath "BetaTrade_Mitarbeiterliste_net07.csv"

# Standard-Passwort für neue Benutzer
$defaultPassword = ConvertTo-SecureString "Welcome123!" -AsPlainText -Force

# Prüfen, ob die CSV existiert
if (-not (Test-Path $csvPath)) {
    Write-Error "CSV-Datei wurde nicht gefunden unter: $csvPath"
    exit
}

# Active Directory Modul prüfen und laden
if (-not (Get-Module ActiveDirectory -ListAvailable)) {
    Write-Error "Das ActiveDirectory-Modul ist nicht installiert. Bitte RSAT installieren."
    exit
}
Import-Module ActiveDirectory

# CSV importieren
$users = Import-Csv -Path $csvPath

# OU-Zuordnung
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

# Logdatei im Downloads-Ordner
$logFile = Join-Path $DownloadPath "Create-BetaTradeUsers.log"
"--- Benutzeranlage gestartet: $(Get-Date) ---" | Out-File -FilePath $logFile -Encoding utf8

# Benutzer anlegen
foreach ($user in $users) {

    # Telefonnummer bereinigen
    $phone = ($user.Telefon -replace '[^0-9+]', '')

    # OU bestimmen
    $ou = Get-OU $user.Abteilung

    # Prüfen, ob Benutzer existiert
    $existingUser = Get-ADUser -Filter "SamAccountName -eq '$($user.Benutzername)'" -ErrorAction SilentlyContinue

    if (-not $existingUser) {
        try {
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

            $msg = "Benutzer $($user.Benutzername) wurde erfolgreich in $ou angelegt."
            Write-Host $msg -ForegroundColor Green
            $msg | Out-File -FilePath $logFile -Append -Encoding utf8
        }
        catch {
            $msg = "Fehler beim Anlegen von $($user.Benutzername): $_"
            Write-Host $msg -ForegroundColor Red
            $msg | Out-File -FilePath $logFile -Append -Encoding utf8
        }
    } else {
        $msg = "Benutzer $($user.Benutzername) existiert bereits."
        Write-Host $msg -ForegroundColor Yellow
        $msg | Out-File -FilePath $logFile -Append -Encoding utf8
    }
}

"--- Benutzeranlage abgeschlossen: $(Get-Date) ---" | Out-File -FilePath $logFile -Append -Encoding utf8
Write-Host "`nAlle Ergebnisse wurden in $logFile protokolliert." -ForegroundColor Cyan



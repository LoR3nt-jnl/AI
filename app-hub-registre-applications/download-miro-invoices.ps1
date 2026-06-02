param(
    [string]$FromDate,
    [string]$DownloadsPath = [Environment]::GetFolderPath("UserProfile") + "\Downloads",
    [string]$OutputRoot = (Join-Path $PSScriptRoot "miro-invoices"),
    [string]$BillingUrl = "https://miro.com/app/settings/company/3458764558232434701/billing?billingPage=billing_history",
    [string]$EmailTo,
    [switch]$SkipGmail,
    [switch]$OpenHelp
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Read-DateFromUser {
    param([string]$Value)

    while ($true) {
        $raw = $Value
        if ([string]::IsNullOrWhiteSpace($raw)) {
            $raw = Read-Host "Depuis quelle date faut-il recuperer les factures ? (format AAAA-MM-JJ, exemple 2025-12-01)"
        }

        $parsed = [datetime]::MinValue
        if ([datetime]::TryParseExact(
            $raw.Trim(),
            "yyyy-MM-dd",
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::None,
            [ref]$parsed
        )) {
            if ($parsed.Date -gt (Get-Date).Date) {
                Write-Warning "La date ne peut pas etre dans le futur."
                $Value = $null
                continue
            }
            return $parsed.Date
        }

        Write-Warning "Date non reconnue. Utilisez le format AAAA-MM-JJ, par exemple 2025-12-01."
        $Value = $null
    }
}

function Get-MonthLabels {
    param([datetime]$Since)

    $cursor = Get-Date -Year $Since.Year -Month $Since.Month -Day 1 -Hour 0 -Minute 0 -Second 0
    $current = Get-Date
    $end = Get-Date -Year $current.Year -Month $current.Month -Day 1 -Hour 0 -Minute 0 -Second 0
    $labels = @()

    while ($cursor -le $end) {
        $labels += $cursor.ToString("yyyy-MM")
        $cursor = $cursor.AddMonths(1)
    }

    return $labels
}

function Get-InvoiceCandidates {
    param(
        [string]$Path,
        [datetime]$Since
    )

    $patterns = @(
        "Invoice-*.pdf",
        "invoice-*.pdf",
        "*invoice*.pdf",
        "*facture*.pdf",
        "*receipt*.pdf"
    )

    $seen = @{}
    foreach ($pattern in $patterns) {
        Get-ChildItem -Path $Path -File -Filter $pattern -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -ge $Since } |
            ForEach-Object {
                if (-not $seen.ContainsKey($_.FullName)) {
                    $seen[$_.FullName] = $_
                }
            }
    }

    return $seen.Values | Sort-Object LastWriteTime, Name
}

function Copy-WithUniqueName {
    param(
        [System.IO.FileInfo]$File,
        [string]$DestinationDirectory
    )

    $targetPath = Join-Path $DestinationDirectory $File.Name
    if (-not (Test-Path -LiteralPath $targetPath)) {
        Copy-Item -LiteralPath $File.FullName -Destination $targetPath
        return $targetPath
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    $extension = [System.IO.Path]::GetExtension($File.Name)
    $counter = 1

    do {
        $candidate = Join-Path $DestinationDirectory ("{0}-{1}{2}" -f $baseName, $counter, $extension)
        $counter++
    } while (Test-Path -LiteralPath $candidate)

    Copy-Item -LiteralPath $File.FullName -Destination $candidate
    return $candidate
}

function Start-GmailDraft {
    param(
        [object[]]$Files,
        [string]$Recipient,
        [datetime]$SinceDate
    )

    if (-not $Files -or $Files.Count -eq 0) {
        return $false
    }

    while ([string]::IsNullOrWhiteSpace($Recipient)) {
        $Recipient = Read-Host "A quelle adresse email faut-il envoyer les factures ?"
    }

    $subject = "Factures Miro depuis le " + $SinceDate.ToString("yyyy-MM-dd")
    $body = @"
Bonjour,

Vous trouverez ci-joint les factures Miro recuperees depuis le $($SinceDate.ToString("yyyy-MM-dd")).

Fichiers joints :
$((($Files | ForEach-Object { "- " + $_.Name }) -join [Environment]::NewLine))
"@

    $requestPath = Join-Path $outputDirectory "gmail-draft-request.json"
    $request = [PSCustomObject]@{
        to = $Recipient
        subject = $subject
        body = $body
        attachment_files = @($Files | ForEach-Object { $_.SavedAs })
    }
    $request | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $requestPath -Encoding UTF8

    $composeUrl = "https://mail.google.com/mail/?view=cm&fs=1&to={0}&su={1}&body={2}" -f (
        [uri]::EscapeDataString($Recipient),
        [uri]::EscapeDataString($subject),
        [uri]::EscapeDataString($body)
    )

    Start-Process $composeUrl
    Start-Process explorer.exe "`"$outputDirectory`""

    Write-Host "Gmail a ete ouvert avec le destinataire, le sujet et le message pre-remplis." -ForegroundColor Green
    Write-Host "Ajoutez les PDF du dossier ouvert en pieces jointes, puis envoyez depuis Gmail."
    Write-Host "Demande Gmail sauvegardee pour Codex : $requestPath"
    return $true
}

if (-not (Test-Path -LiteralPath $DownloadsPath)) {
    throw "Le dossier Telechargements est introuvable : $DownloadsPath"
}

$fromDateValue = Read-DateFromUser -Value $FromDate
$targetLabel = "depuis-" + $fromDateValue.ToString("yyyy-MM-dd")
$outputDirectory = Join-Path $OutputRoot $targetLabel
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$monthLabels = @(Get-MonthLabels -Since $fromDateValue)
$startTime = Get-Date

Write-Step "Preparation"
Write-Host "Date de depart : $($fromDateValue.ToString("yyyy-MM-dd"))"
Write-Host "Telechargements : $DownloadsPath"
Write-Host "Dossier de sortie : $outputDirectory"
Write-Host ""
Write-Host "Factures a telecharger dans Miro :"
foreach ($label in $monthLabels) {
    Write-Host " - $label"
}
Write-Host "Si Miro affiche plusieurs factures dans un meme mois, telechargez toutes celles datees depuis le $($fromDateValue.ToString("yyyy-MM-dd"))."

Write-Step "Ouverture de Miro"
Start-Process $BillingUrl
if ($OpenHelp) {
    Start-Process "https://help.miro.com/hc/en-us/articles/360017730313-How-to-find-and-download-an-invoice"
}

Write-Host "Une fenetre Miro va s'ouvrir sur la page de facturation."
Write-Host "URL utilisee : $BillingUrl"
Write-Host "Telechargez les factures listees ci-dessus, puis revenez ici."
Read-Host "Appuyez sur Entree une fois les telechargements termines"

$candidates = Get-InvoiceCandidates -Path $DownloadsPath -Since $startTime

Write-Step "Analyse des fichiers telecharges"
if (-not $candidates -or $candidates.Count -eq 0) {
    Write-Warning "Aucun PDF de type facture telecharge depuis le lancement du script."
    Write-Host "Si les factures etaient deja presentes avant, relancez le script puis telechargez-les de nouveau depuis Miro."
    exit 1
}

$copiedFiles = @()
foreach ($file in $candidates) {
    $copiedPath = Copy-WithUniqueName -File $file -DestinationDirectory $outputDirectory
    $copiedFiles += [PSCustomObject]@{
        Name = $file.Name
        Source = $file.FullName
        SavedAs = $copiedPath
        LastWriteTime = $file.LastWriteTime
        SizeKB = [math]::Round($file.Length / 1KB, 1)
    }
}

Write-Step "Termine"
$copiedFiles | Sort-Object LastWriteTime | Format-Table Name, LastWriteTime, SizeKB, SavedAs -AutoSize
Write-Host ""
Write-Host ("{0} fichier(s) copie(s) dans {1}" -f $copiedFiles.Count, $outputDirectory) -ForegroundColor Green

if (-not $SkipGmail) {
    Write-Step "Gmail"
    $sendAnswer = Read-Host "Preparer un email Gmail pour ces factures maintenant ? (O/n)"
    if ([string]::IsNullOrWhiteSpace($sendAnswer) -or $sendAnswer.Trim().ToLowerInvariant() -in @("o", "oui", "y", "yes")) {
        [void](Start-GmailDraft -Files $copiedFiles -Recipient $EmailTo -SinceDate $fromDateValue)
    }
    else {
        Write-Host "Gmail ignore. Les fichiers restent disponibles dans le dossier de sortie."
    }
}

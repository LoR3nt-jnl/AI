param(
    [string]$RegistryPath = (Join-Path $PSScriptRoot "apps-registry.json")
)

$ErrorActionPreference = "Stop"

function Read-JsonArray {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    $parsed = $raw | ConvertFrom-Json
    if ($null -eq $parsed) {
        return @()
    }
    if ($parsed -is [array]) {
        foreach ($item in $parsed) {
            if ($item -is [array]) {
                foreach ($child in $item) { $child }
            } else {
                $item
            }
        }
        return
    }
    if ($parsed.PSObject.Properties["value"] -and $parsed.PSObject.Properties["Count"]) {
        foreach ($item in @($parsed.value)) { $item }
        return
    }
    return $parsed
}

function New-Slug {
    param([string]$Value)

    $slug = $Value.ToLowerInvariant() -replace "[^a-z0-9]+", "-"
    $slug = $slug.Trim("-")
    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "app"
    }
    return $slug
}

function Get-LabelValue {
    param($Labels, [string[]]$Names)

    if ($null -eq $Labels) {
        return ""
    }

    foreach ($name in $Names) {
        if ($Labels.PSObject.Properties[$name]) {
            return [string]$Labels.$name
        }
    }

    return ""
}

Write-Host ""
Write-Host "Synchronisation Google Cloud vers le registre d'applications" -ForegroundColor Cyan
Write-Host "Cette operation utilise votre session Google Cloud locale avec gcloud." -ForegroundColor Gray
Write-Host ""

$gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
if (-not $gcloud) {
    Write-Host "Google Cloud CLI n'est pas installe sur cette machine." -ForegroundColor Yellow
    Write-Host "Installez-le puis relancez la synchronisation depuis le registre." -ForegroundColor Yellow
    Start-Process "https://cloud.google.com/sdk/docs/install"
    return
}

$account = (& gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null | Select-Object -First 1)
if ([string]::IsNullOrWhiteSpace($account)) {
    Write-Host "Connexion Google requise. Une fenetre navigateur va s'ouvrir." -ForegroundColor Yellow
    & gcloud auth login --brief --quiet
    $account = (& gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null | Select-Object -First 1)
}

if ([string]::IsNullOrWhiteSpace($account)) {
    throw "Aucun compte Google Cloud actif apres authentification."
}

Write-Host "Compte Google actif : $account" -ForegroundColor Green

$projectsJson = (& gcloud projects list --format=json --quiet) -join "`n"
$projects = @($projectsJson | ConvertFrom-Json)
if ($projects.Count -eq 1 -and $projects[0] -is [array]) {
    $projects = @($projects[0])
}
if ($projects.Count -eq 0) {
    Write-Host "Aucun projet Google Cloud visible pour ce compte." -ForegroundColor Yellow
    return
}

Write-Host ""
Write-Host "Projets disponibles :" -ForegroundColor Cyan
for ($i = 0; $i -lt $projects.Count; $i++) {
    Write-Host ("[{0}] {1}" -f ($i + 1), $projects[$i].projectId)
}

$selection = Read-Host "Numero du projet a synchroniser, ou entree pour tous"
$selectedProjects = @()
if ([string]::IsNullOrWhiteSpace($selection)) {
    $selectedProjects = $projects
} else {
    $index = [int]$selection - 1
    if ($index -lt 0 -or $index -ge $projects.Count) {
        throw "Selection invalide."
    }
    $selectedProjects = @($projects[$index])
}

$registry = @(Read-JsonArray -Path $RegistryPath | Where-Object {
    -not [string]::IsNullOrWhiteSpace([string]$_.id) -and
    -not [string]::IsNullOrWhiteSpace([string]$_.name)
})
$imported = @()

foreach ($project in $selectedProjects) {
    $projectId = [string]$project.projectId
    Write-Host ""
    Write-Host "Lecture des services Cloud Run dans $projectId..." -ForegroundColor Cyan

    $servicesJson = (& gcloud run services list --project $projectId --format=json --quiet 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        if ($servicesJson -match "run.googleapis.com") {
            Write-Host "Cloud Run Admin API n'est pas activee pour ce projet. Projet ignore." -ForegroundColor Yellow
            Write-Host "Activation possible ici : https://console.developers.google.com/apis/api/run.googleapis.com/overview?project=$projectId" -ForegroundColor Gray
        } else {
            Write-Host "Impossible de lire Cloud Run pour ce projet. Projet ignore." -ForegroundColor Yellow
            Write-Host $servicesJson -ForegroundColor DarkGray
        }
        continue
    }

    if ([string]::IsNullOrWhiteSpace($servicesJson)) {
        continue
    }

    $services = @($servicesJson | ConvertFrom-Json)
    if ($services.Count -eq 1 -and $services[0] -is [array]) {
        $services = @($services[0])
    }
    foreach ($service in $services) {
        $labels = $service.metadata.labels
        $originLabel = Get-LabelValue -Labels $labels -Names @("origin", "source", "created_with")
        $author = Get-LabelValue -Labels $labels -Names @("author", "owner")
        $appName = Get-LabelValue -Labels $labels -Names @("app", "application")

        $origin = if ($originLabel -in @("gai-studio", "ai-studio", "google-ai-studio")) {
            "gai-studio"
        } elseif ($originLabel -eq "codex") {
            "codex"
        } else {
            "google-cloud"
        }

        if ([string]::IsNullOrWhiteSpace($author)) {
            $author = "Moi"
        }

        $serviceName = [string]$service.metadata.name
        $region = [string]$service.metadata.labels."cloud.googleapis.com/location"
        if ([string]::IsNullOrWhiteSpace($region)) {
            $region = [string]$service.location
        }

        $name = if ([string]::IsNullOrWhiteSpace($appName)) { $serviceName } else { $appName }
        $url = [string]$service.status.url
        $tags = @("Google Cloud")
        if ($origin -eq "gai-studio") {
            $tags = @("GAI Studio", "Google Cloud")
        } elseif ($origin -eq "codex") {
            $tags = @("Codex", "Google Cloud")
        }

        $entryId = "gcloud-$projectId-$(New-Slug -Value $serviceName)"
        $existingEntry = $registry | Where-Object { $_.id -eq $entryId } | Select-Object -First 1
        $isFavorite = if ($existingEntry -and $existingEntry.PSObject.Properties["isFavorite"]) { [bool]$existingEntry.isFavorite } else { $false }

        $entry = [PSCustomObject]@{
            id            = $entryId
            name          = $name
            description   = "Service Cloud Run recense depuis Google Cloud."
            category      = "Applications IA"
            origin        = $origin
            author        = $author
            tags          = $tags
            isFavorite    = $isFavorite
            accessUrl     = $url
            googleProject = $projectId
            cloudService  = if ([string]::IsNullOrWhiteSpace($region)) { "cloud-run/$serviceName" } else { "cloud-run/$region/$serviceName" }
            scriptPath    = ""
            arguments     = ""
            accent        = if ($origin -eq "gai-studio") { "#1E6B52" } else { "#286AA6" }
            status        = "Pret"
        }

        $registry = @($registry | Where-Object { $_.id -ne $entry.id })
        $registry += $entry
        $imported += $entry
    }
}

$registry |
    Sort-Object category, name |
    ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $RegistryPath -Encoding UTF8

Write-Host ""
Write-Host "$($imported.Count) application(s) synchronisee(s)." -ForegroundColor Green
Write-Host "Cliquez sur Actualiser dans le registre pour voir les nouvelles applications." -ForegroundColor Green
Write-Host ""
Write-Host "Astuce : pour identifier explicitement une app AI Studio deployee sur Cloud Run, ajoutez le label origin=gai-studio sur son service Cloud Run." -ForegroundColor Gray

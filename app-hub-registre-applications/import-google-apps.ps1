param(
    [Parameter(Mandatory = $true)][string]$ManifestPath,
    [string]$RegistryPath = (Join-Path $PSScriptRoot "apps-registry.json")
)

$ErrorActionPreference = "Stop"

function New-Slug {
    param([string]$Value)
    $slug = $Value.ToLowerInvariant() -replace "[^a-z0-9]+", "-"
    $slug = $slug.Trim("-")
    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "app"
    }
    return $slug
}

function Read-JsonArray {
    param([string]$Path)

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

if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "Manifeste introuvable : $ManifestPath"
}

if (-not (Test-Path -LiteralPath $RegistryPath)) {
    "[]" | Set-Content -LiteralPath $RegistryPath -Encoding UTF8
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$items = if ($manifest.apps) { @($manifest.apps) } else { @($manifest) }
$registry = @(Read-JsonArray -Path $RegistryPath | Where-Object {
    -not [string]::IsNullOrWhiteSpace([string]$_.id) -and
    -not [string]::IsNullOrWhiteSpace([string]$_.name)
})

foreach ($item in $items) {
    $origin = if ($item.origin) { [string]$item.origin } elseif ($item.labels.origin) { [string]$item.labels.origin } else { "gai-studio" }
    $name = if ($item.name) { [string]$item.name } elseif ($item.displayName) { [string]$item.displayName } else { [string]$item.serviceName }
    $url = if ($item.accessUrl) { [string]$item.accessUrl } elseif ($item.url) { [string]$item.url } else { "" }
    $project = if ($item.googleProject) { [string]$item.googleProject } elseif ($item.projectId) { [string]$item.projectId } else { "" }
    $service = if ($item.cloudService) { [string]$item.cloudService } elseif ($item.serviceName) { [string]$item.serviceName } else { "" }
    $author = if ($item.author) { [string]$item.author } elseif ($item.labels.author) { [string]$item.labels.author } else { "Moi" }
    $tags = @("GAI Studio")

    if ($origin -eq "codex") {
        $tags = @("Codex")
    } elseif ($origin -eq "google-cloud") {
        $tags = @("Google Cloud")
    }

    if ($item.tags) {
        $tags += @($item.tags)
    }

    $entry = [PSCustomObject]@{
        id            = if ($item.id) { [string]$item.id } else { New-Slug -Value $name }
        name          = $name
        description   = if ($item.description) { [string]$item.description } else { "Application recensee depuis Google AI Studio ou Google Cloud." }
        category      = if ($item.category) { [string]$item.category } else { "Applications IA" }
        origin        = $origin
        author        = $author
        tags          = @($tags | Select-Object -Unique)
        isFavorite    = if ($item.isFavorite) { [bool]$item.isFavorite } else { $false }
        accessUrl     = $url
        googleProject = $project
        cloudService  = $service
        scriptPath    = ""
        arguments     = ""
        accent        = if ($item.accent) { [string]$item.accent } else { "#1E6B52" }
        status        = if ($item.status) { [string]$item.status } else { "Pret" }
    }

    $registry = @($registry | Where-Object { $_.id -ne $entry.id })
    $registry += $entry
}

$registry |
    Sort-Object category, name |
    ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $RegistryPath -Encoding UTF8

Write-Host "Applications importees dans $RegistryPath" -ForegroundColor Green

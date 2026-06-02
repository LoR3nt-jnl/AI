param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$ScriptPath = "",
    [string]$Description = "Application ajoutee au registre.",
    [string]$Category = "Outils",
    [ValidateSet("codex", "gai-studio", "google-cloud", "other")]
    [string]$Origin = "codex",
    [string]$Author = "Moi",
    [string[]]$Tags = @(),
    [bool]$IsFavorite = $false,
    [string]$AccessUrl = "",
    [string]$GoogleProject = "",
    [string]$CloudService = "",
    [string]$Arguments = "",
    [string]$Status = "Pret",
    [string]$Accent = "#5E8B7E",
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

function Read-Registry {
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

if (-not (Test-Path -LiteralPath $RegistryPath)) {
    "[]" | Set-Content -LiteralPath $RegistryPath -Encoding UTF8
}

$resolvedScriptPath = ""
if (-not [string]::IsNullOrWhiteSpace($ScriptPath)) {
    $resolvedScriptPath = if ([System.IO.Path]::IsPathRooted($ScriptPath)) {
        $ScriptPath
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $ScriptPath))
    }
}

$registry = @(Read-Registry -Path $RegistryPath | Where-Object {
    -not [string]::IsNullOrWhiteSpace([string]$_.id) -and
    -not [string]::IsNullOrWhiteSpace([string]$_.name)
})

$entry = [PSCustomObject]@{
    id          = New-Slug -Value $Name
    name        = $Name
    description = $Description
    category      = $Category
    origin        = $Origin
    author        = $Author
    tags          = $Tags
    isFavorite    = $IsFavorite
    accessUrl     = $AccessUrl
    googleProject = $GoogleProject
    cloudService  = $CloudService
    scriptPath    = $resolvedScriptPath
    arguments     = $Arguments
    accent        = $Accent
    status        = $Status
}

$existing = $registry | Where-Object { $_.id -eq $entry.id }
if ($existing) {
    $registry = @($registry | Where-Object { $_.id -ne $entry.id })
}

$registry += $entry
$registry |
    Sort-Object category, name |
    ConvertTo-Json -Depth 5 |
    Set-Content -LiteralPath $RegistryPath -Encoding UTF8

Write-Host "Application enregistree dans $RegistryPath" -ForegroundColor Green

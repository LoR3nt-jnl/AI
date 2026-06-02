Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$script:AppReference = "APP-HUB-REGISTRE-2026-04-24"
$script:LastUpdated = "2026-06-02 09:20"
$script:RegistryPath = Join-Path $PSScriptRoot "apps-registry.json"
$script:NoticePath = Join-Path $PSScriptRoot "README-app-hub.md"
$script:SyncScriptPath = Join-Path $PSScriptRoot "sync-google-cloud-apps.ps1"
$script:apps = @()
$script:showFavoritesOnly = $false

function New-Brush {
    param([string]$Color)
    return [Windows.Media.BrushConverter]::new().ConvertFromString($Color)
}

function New-TextBlock {
    param(
        [string]$Text,
        [int]$Size = 13,
        [string]$Color = "#26362f",
        [string]$Weight = "Normal",
        [int]$Bottom = 0
    )
    $tb = [Windows.Controls.TextBlock]::new()
    $tb.Text = $Text
    $tb.FontSize = $Size
    $tb.Foreground = New-Brush $Color
    $tb.FontWeight = $Weight
    $tb.TextWrapping = "Wrap"
    $tb.Margin = [Windows.Thickness]::new(0, 0, 0, $Bottom)
    return $tb
}

function New-Button {
    param(
        [string]$Text,
        [string]$Color = "#efe7d8",
        [string]$Foreground = "#14251d",
        [int]$Width = 120
    )
    $button = [Windows.Controls.Button]::new()
    $button.Content = $Text
    $button.Width = $Width
    $button.Height = 38
    $button.Margin = [Windows.Thickness]::new(0, 0, 10, 0)
    $button.Background = New-Brush $Color
    $button.Foreground = New-Brush $Foreground
    $button.BorderBrush = New-Brush $Color
    $button.FontWeight = "SemiBold"
    return $button
}

function Get-ValidApps {
    param([object[]]$Items)
    return @($Items | Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_.id) -and
        -not [string]::IsNullOrWhiteSpace([string]$_.name)
    })
}

function Read-AppRegistry {
    if (-not (Test-Path -LiteralPath $script:RegistryPath)) {
        "[]" | Set-Content -LiteralPath $script:RegistryPath -Encoding UTF8
    }

    $raw = Get-Content -LiteralPath $script:RegistryPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    $parsed = $raw | ConvertFrom-Json
    if ($null -eq $parsed) {
        return @()
    }

    if ($parsed -is [array]) {
        return Get-ValidApps -Items $parsed
    }

    if ($parsed.PSObject.Properties["value"] -and $parsed.PSObject.Properties["Count"]) {
        return Get-ValidApps -Items @($parsed.value)
    }

    return Get-ValidApps -Items @($parsed)
}

function Save-AppRegistry {
    param([object[]]$Items)
    $valid = Get-ValidApps -Items $Items
    if ($valid.Count -eq 0 -and $Items.Count -gt 0) {
        throw "Sauvegarde refusee : le registre ne contient aucune application valide."
    }
    $valid | Sort-Object category, name | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $script:RegistryPath -Encoding UTF8
}

function Load-Apps {
    $script:apps = @(Read-AppRegistry)
}

function Set-AppFavorite {
    param([string]$Id, [bool]$Favorite)
    $registry = @(Read-AppRegistry)
    foreach ($app in $registry) {
        if ([string]$app.id -eq $Id) {
            if (-not $app.PSObject.Properties["isFavorite"]) {
                $app | Add-Member -NotePropertyName isFavorite -NotePropertyValue $false
            }
            $app.isFavorite = $Favorite
        }
    }
    Save-AppRegistry -Items $registry
    Load-Apps
    Render-Apps
}

function Get-OriginLabel {
    param($App)
    switch ([string]$App.origin) {
        "codex" { return "Codex" }
        "gai-studio" { return "GAI Studio" }
        "google-cloud" { return "Google Cloud" }
        default { return "Autre" }
    }
}

function Get-AppText {
    param($App)
    $lines = @(
        "Reference : $($App.id)",
        "Nom : $($App.name)",
        "Origine : $(Get-OriginLabel -App $App)",
        "Auteur : $($App.author)",
        "Categorie : $($App.category)",
        "URL : $($App.accessUrl)",
        "Projet Google : $($App.googleProject)",
        "Service Cloud : $($App.cloudService)",
        "Script : $($App.scriptPath)"
    )
    return ($lines -join [Environment]::NewLine)
}

function Start-AppEntry {
    param($App)
    if (-not [string]::IsNullOrWhiteSpace([string]$App.accessUrl)) {
        Start-Process ([string]$App.accessUrl)
        return
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$App.scriptPath)) {
        $path = [string]$App.scriptPath
        if (-not [System.IO.Path]::IsPathRooted($path)) {
            $path = Join-Path $PSScriptRoot $path
        }
        Start-Process powershell.exe -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", $path)
    }
}

function Open-AppSource {
    param($App)
    if (-not [string]::IsNullOrWhiteSpace([string]$App.scriptPath)) {
        $path = [string]$App.scriptPath
        if (-not [System.IO.Path]::IsPathRooted($path)) {
            $path = Join-Path $PSScriptRoot $path
        }
        if (Test-Path -LiteralPath $path) {
            Start-Process explorer.exe "/select,`"$path`""
            return
        }
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$App.accessUrl)) {
        Set-Clipboard ([string]$App.accessUrl)
    }
}

function New-TagPanel {
    param($App)
    $panel = [Windows.Controls.WrapPanel]::new()
    $panel.Margin = [Windows.Thickness]::new(0, 6, 0, 10)
    $labels = @((Get-OriginLabel -App $App))
    if (-not [string]::IsNullOrWhiteSpace([string]$App.category)) { $labels += [string]$App.category }
    if ($App.tags) { $labels += @($App.tags) }
    $labels = @($labels | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)

    foreach ($label in $labels) {
        $border = [Windows.Controls.Border]::new()
        $border.Background = New-Brush "#edf3ef"
        $border.CornerRadius = [Windows.CornerRadius]::new(12)
        $border.Margin = [Windows.Thickness]::new(0, 0, 6, 6)
        $border.Padding = [Windows.Thickness]::new(9, 4, 9, 4)
        $border.Child = New-TextBlock -Text $label -Size 11 -Color "#285342"
        [void]$panel.Children.Add($border)
    }
    return $panel
}

function New-AppCard {
    param($App)

    $card = [Windows.Controls.Border]::new()
    $card.Width = 360
    $card.MinHeight = 220
    $card.Margin = [Windows.Thickness]::new(0, 0, 18, 18)
    $card.Padding = [Windows.Thickness]::new(18)
    $card.Background = New-Brush "#fffdf8"
    $card.BorderBrush = New-Brush "#ded3c0"
    $card.BorderThickness = [Windows.Thickness]::new(1)
    $card.CornerRadius = [Windows.CornerRadius]::new(8)

    $stack = [Windows.Controls.StackPanel]::new()

    $top = [Windows.Controls.Grid]::new()
    [void]$top.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
    $starCol = [Windows.Controls.ColumnDefinition]::new()
    $starCol.Width = [Windows.GridLength]::new(38)
    [void]$top.ColumnDefinitions.Add($starCol)

    $title = New-TextBlock -Text ([string]$App.name) -Size 18 -Color "#0e2319" -Weight "Bold" -Bottom 4
    [Windows.Controls.Grid]::SetColumn($title, 0)
    [void]$top.Children.Add($title)

    $star = [Windows.Controls.Button]::new()
    $star.Content = if ([bool]$App.isFavorite) { [string]([char]0x2605) } else { [string]([char]0x2606) }
    $star.FontSize = 22
    $star.Width = 34
    $star.Height = 34
    $star.Background = New-Brush "#fffdf8"
    $star.BorderBrush = New-Brush "#fffdf8"
    $star.Foreground = New-Brush "#d9a623"
    $star.ToolTip = "Ajouter ou retirer des favoris"
    $star.Tag = [string]$App.id
    $star.Add_Click({
        $id = [string]$this.Tag
        $current = $script:apps | Where-Object { [string]$_.id -eq $id } | Select-Object -First 1
        Set-AppFavorite -Id $id -Favorite (-not [bool]$current.isFavorite)
    })
    [Windows.Controls.Grid]::SetColumn($star, 1)
    [void]$top.Children.Add($star)
    [void]$stack.Children.Add($top)

    [void]$stack.Children.Add((New-TextBlock -Text ([string]$App.description) -Size 13 -Color "#31463b" -Bottom 4))
    [void]$stack.Children.Add((New-TagPanel -App $App))

    if (-not [string]::IsNullOrWhiteSpace([string]$App.author) -and [string]$App.author -ne "Moi") {
        [void]$stack.Children.Add((New-TextBlock -Text "Auteur : $($App.author)" -Size 12 -Color "#56635d" -Bottom 8))
    }

    $meta = [Windows.Controls.Grid]::new()
    [void]$meta.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
    $copyCol = [Windows.Controls.ColumnDefinition]::new()
    $copyCol.Width = [Windows.GridLength]::new(86)
    [void]$meta.ColumnDefinitions.Add($copyCol)

    $ref = New-TextBlock -Text "Ref. $($App.id)" -Size 12 -Color "#56635d"
    [Windows.Controls.Grid]::SetColumn($ref, 0)
    [void]$meta.Children.Add($ref)

    $copyRef = New-Button -Text "Copier ref" -Width 82
    $copyRef.Height = 30
    $copyRef.Margin = [Windows.Thickness]::new(0)
    $copyRef.Tag = [string]$App.id
    $copyRef.Add_Click({ Set-Clipboard ([string]$this.Tag) })
    [Windows.Controls.Grid]::SetColumn($copyRef, 1)
    [void]$meta.Children.Add($copyRef)
    [void]$stack.Children.Add($meta)

    $actions = [Windows.Controls.WrapPanel]::new()
    $actions.Margin = [Windows.Thickness]::new(0, 16, 0, 0)

    $launch = New-Button -Text "Lancer" -Color "#1c6b52" -Foreground "White" -Width 92
    $launch.Tag = $App
    $launch.Add_Click({ Start-AppEntry -App $this.Tag })
    [void]$actions.Children.Add($launch)

    $source = New-Button -Text "Source" -Width 92
    $source.Tag = $App
    $source.Add_Click({ Open-AppSource -App $this.Tag })
    [void]$actions.Children.Add($source)

    $copy = New-Button -Text "Copier" -Width 92
    $copy.Tag = $App
    $copy.Add_Click({ Set-Clipboard (Get-AppText -App $this.Tag) })
    [void]$actions.Children.Add($copy)

    [void]$stack.Children.Add($actions)
    $card.Child = $stack
    return $card
}

function Render-Apps {
    $script:CardsPanel.Children.Clear()
    $query = $script:SearchBox.Text.Trim().ToLowerInvariant()
    $items = @($script:apps)
    if ($script:showFavoritesOnly) {
        $items = @($items | Where-Object { [bool]$_.isFavorite })
    }
    if (-not [string]::IsNullOrWhiteSpace($query)) {
        $items = @($items | Where-Object {
            (([string]$_.name).ToLowerInvariant().Contains($query)) -or
            (([string]$_.description).ToLowerInvariant().Contains($query)) -or
            (([string]$_.category).ToLowerInvariant().Contains($query)) -or
            (([string]$_.origin).ToLowerInvariant().Contains($query)) -or
            (([string]$_.tags).ToLowerInvariant().Contains($query))
        })
    }

    $favoriteCount = @($script:apps | Where-Object { [bool]$_.isFavorite }).Count
    $script:StatsText.Text = "$($items.Count) application(s) affichee(s) - $favoriteCount favorite(s)"
    $script:FavoriteButton.Content = if ($script:showFavoritesOnly) { "Tous" } else { "Favoris" }

    if ($items.Count -eq 0) {
        $empty = New-TextBlock -Text "Aucune application ne correspond a cette recherche." -Size 15 -Color "#465a50"
        $empty.Margin = [Windows.Thickness]::new(8, 16, 0, 0)
        [void]$script:CardsPanel.Children.Add($empty)
        return
    }

    foreach ($app in $items) {
        [void]$script:CardsPanel.Children.Add((New-AppCard -App $app))
    }
}

Load-Apps

$window = [Windows.Window]::new()
$window.Title = "Registre d'applications"
$window.Width = 1380
$window.Height = 850
$window.MinWidth = 980
$window.MinHeight = 680
$window.Background = New-Brush "#f4efe6"

$root = [Windows.Controls.DockPanel]::new()
$root.Margin = [Windows.Thickness]::new(18)
$window.Content = $root

$header = [Windows.Controls.Border]::new()
$header.Background = New-Brush "#0f2419"
$header.CornerRadius = [Windows.CornerRadius]::new(14)
$header.Padding = [Windows.Thickness]::new(22)
$header.Margin = [Windows.Thickness]::new(0, 0, 0, 16)
[Windows.Controls.DockPanel]::SetDock($header, "Top")
[void]$root.Children.Add($header)

$headerGrid = [Windows.Controls.Grid]::new()
[void]$headerGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
$rightCol = [Windows.Controls.ColumnDefinition]::new()
$rightCol.Width = [Windows.GridLength]::new(360)
[void]$headerGrid.ColumnDefinitions.Add($rightCol)
$header.Child = $headerGrid

$headline = [Windows.Controls.StackPanel]::new()
[void]$headline.Children.Add((New-TextBlock -Text "Vos applications" -Size 28 -Color "#fff8e8" -Weight "Bold" -Bottom 8))
[void]$headline.Children.Add((New-TextBlock -Text "Retrouvez les outils construits avec Codex, Google AI Studio ou Google Cloud, puis lancez-les sans passer par les dossiers." -Size 14 -Color "#fff8e8"))
[Windows.Controls.Grid]::SetColumn($headline, 0)
[void]$headerGrid.Children.Add($headline)

$info = [Windows.Controls.StackPanel]::new()
$info.Background = New-Brush "#183528"
$info.Margin = [Windows.Thickness]::new(20, 0, 0, 0)
$script:StatsText = New-TextBlock -Text "" -Size 17 -Color "#fff8e8" -Weight "Bold" -Bottom 8
[void]$info.Children.Add($script:StatsText)
[void]$info.Children.Add((New-TextBlock -Text "Ref. $script:AppReference" -Size 12 -Color "#fff8e8" -Weight "SemiBold" -Bottom 4))
[void]$info.Children.Add((New-TextBlock -Text "Mise a jour : $script:LastUpdated" -Size 12 -Color "#fff8e8"))
[Windows.Controls.Grid]::SetColumn($info, 1)
[void]$headerGrid.Children.Add($info)

$toolbar = [Windows.Controls.Grid]::new()
$toolbar.Margin = [Windows.Thickness]::new(0, 0, 0, 16)
[Windows.Controls.DockPanel]::SetDock($toolbar, "Top")
[void]$root.Children.Add($toolbar)
[void]$toolbar.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
for ($i = 0; $i -lt 5; $i++) {
    $col = [Windows.Controls.ColumnDefinition]::new()
    $col.Width = [Windows.GridLength]::new(140)
    [void]$toolbar.ColumnDefinitions.Add($col)
}

$script:SearchBox = [Windows.Controls.TextBox]::new()
$script:SearchBox.Height = 38
$script:SearchBox.FontSize = 15
$script:SearchBox.Padding = [Windows.Thickness]::new(10, 6, 10, 6)
$script:SearchBox.Margin = [Windows.Thickness]::new(0, 0, 12, 0)
$script:SearchBox.Add_TextChanged({ Render-Apps })
[Windows.Controls.Grid]::SetColumn($script:SearchBox, 0)
[void]$toolbar.Children.Add($script:SearchBox)

$refresh = New-Button -Text "Actualiser" -Color "#e0b24a" -Width 126
$refresh.Add_Click({ Load-Apps; Render-Apps })
[Windows.Controls.Grid]::SetColumn($refresh, 1)
[void]$toolbar.Children.Add($refresh)

$studio = New-Button -Text "AI Studio" -Color "#1c6b52" -Foreground "White" -Width 126
$studio.Add_Click({ Start-Process "https://aistudio.google.com/" })
[Windows.Controls.Grid]::SetColumn($studio, 2)
[void]$toolbar.Children.Add($studio)

$sync = New-Button -Text "Sync Cloud" -Color "#2b6da8" -Foreground "White" -Width 126
$sync.Add_Click({ if (Test-Path -LiteralPath $script:SyncScriptPath) { Start-Process powershell.exe -ArgumentList @("-ExecutionPolicy", "Bypass", "-NoExit", "-File", $script:SyncScriptPath) } })
[Windows.Controls.Grid]::SetColumn($sync, 3)
[void]$toolbar.Children.Add($sync)

$notice = New-Button -Text "Notice" -Width 126
$notice.Add_Click({ if (Test-Path -LiteralPath $script:NoticePath) { Start-Process notepad.exe $script:NoticePath } })
[Windows.Controls.Grid]::SetColumn($notice, 4)
[void]$toolbar.Children.Add($notice)

$script:FavoriteButton = New-Button -Text "Favoris" -Width 126
$script:FavoriteButton.Add_Click({ $script:showFavoritesOnly = -not $script:showFavoritesOnly; Render-Apps })
[Windows.Controls.Grid]::SetColumn($script:FavoriteButton, 5)
[void]$toolbar.Children.Add($script:FavoriteButton)

$scroll = [Windows.Controls.ScrollViewer]::new()
$scroll.VerticalScrollBarVisibility = "Auto"
$script:CardsPanel = [Windows.Controls.WrapPanel]::new()
$script:CardsPanel.Margin = [Windows.Thickness]::new(0, 4, 0, 0)
$scroll.Content = $script:CardsPanel
[void]$root.Children.Add($scroll)

Render-Apps
[void]$window.ShowDialog()

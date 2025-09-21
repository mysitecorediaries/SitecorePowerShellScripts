# Prompt user with a Content Tree rooted at Media Library
$props = @{
    Parameters  = @(
        @{
            Name    = "CsvFile"
            Title   = "Select CSV from Media Library"
            Tooltip = "Browse and select the CSV file you uploaded"
            Root    = "/sitecore/media library"
            Editor  = "item"
        }
    )
    Title       = "CSV Import"
    Description = "Pick your CSV file from the Media Library"
    Width       = 500
    Height      = 400
}

$result = Read-Variable @props

if ($result -ne "ok" -or $CsvFile -eq $null) {
    Write-Host "Import cancelled by user."
    return
}

# $CsvFile is already an Item
$mediaItem = $CsvFile
$media = [Sitecore.Data.Items.MediaItem]$mediaItem
$stream = $media.GetMediaStream()

# Save to a temporary file for Import-Csv
$tempPath = [System.IO.Path]::GetTempFileName()
$fs = [System.IO.File]::Create($tempPath)
$stream.CopyTo($fs)
$fs.Close()

# Import CSV
$rows = Import-Csv -Path $tempPath

if (-not $rows -or $rows.Count -eq 0) {
    Show-Alert "CSV is empty." -Title "Error"
    return
}

# Parent where items will be created
$parentPath = "master:/sitecore/content/Home/Articles"
$templatePath = "/sitecore/templates/User Defined/PowerShellDemo/Article"
$parent = Get-Item -Path $parentPath

foreach ($row in $rows) {
    $itemName = [Sitecore.Data.Items.ItemUtil]::ProposeValidItemName($row.Title)
    $newItem = New-Item -Parent $parent -Name $itemName -ItemType $templatePath

    if ($newItem) {
        $newItem.Editing.BeginEdit()
        $newItem["Title"] = $row.Title
        $newItem["Meta Title"] = $row.MetaTitle
        $newItem["Meta Description"] = $row.MetaDescription
        $newItem["Meta Keywords"] = $row.MetaKeywords
        $newItem["Author"] = $row.Author
        $newItem["Time to watch"] = $row.TimeToWatch
        $newItem["Content"] = $row.Content
        # Resolve Thumbnail if provided
        if ($row.Thumbnail -and $row.Thumbnail -ne "") {
            $thumbItem = Get-Item -Path "master:$($row.Thumbnail)"
            if ($thumbItem) {
                $newItem["Thumbnail"] = "<image mediaid=""$($thumbItem.ID)"" />"
            }
        }
        
        $newItem.Editing.EndEdit()

        Write-Host "Created: $($newItem.Paths.FullPath)"
    }
}

Show-Alert -Title "CSV import finished successfully."



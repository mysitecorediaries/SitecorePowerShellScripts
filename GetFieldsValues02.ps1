$items = Get-ChildItem -Path "master:/sitecore/content/Home" -Recurse

$results = foreach ($item in $items) {
    # Get the thumbnail image field
    $thumbnailField = [Sitecore.Data.Fields.ImageField]$item.Fields["Thumbnail"]
    $thumbnailPath = if ($thumbnailField -and $thumbnailField.MediaItem) {
        [Sitecore.Resources.Media.MediaManager]::GetMediaUrl($thumbnailField.MediaItem)
    }
    else {
        ""
    }

    [PSCustomObject]@{
        ItemName           = $item.Name
        "Meta Keywords"    = $item["Meta Keywords"]
        "Meta Description" = $item["Meta Description"]
        "Meta Title"       = $item["Meta Title"]
        "Author"           = $item["Author"]
        "Time to watch"    = $item["Time to watch"]
        "Thumbnail"        = $thumbnailPath
        "Title"            = $item["Title"]
        "Content"          = $item["Content"]
    }
}

$results | Show-ListView -Property ItemName, "Meta Keywords", "Meta Description", "Meta Title", "Author", "Time to watch", "Thumbnail", "Title", "Content"

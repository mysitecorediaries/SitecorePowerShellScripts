# --- CONFIG ---
$rootPath = "master:/sitecore/content/Home/Articles"
$includeAbsoluteMediaUrl = $false   # set $true for full http(s) urls
# ----------------

$items = Get-ChildItem -Path $rootPath -Recurse

# Collect all fields from the templates of all items (so blanks still appear)
$allFieldNames = $items |
ForEach-Object { $_.Template.Fields } |
Where-Object { $_ -and $_.Name -and ($_.Name.Trim() -ne "") -and ($_.Name -notmatch '^__') } |
Select-Object -ExpandProperty Name -Unique

# Always show ItemName first
$properties = @('ItemName') + $allFieldNames

$results = foreach ($item in $items) {
    $row = @{}
    foreach ($fn in $allFieldNames) { $row[$fn] = "" }

    $row["ItemName"] = $item.Name

    foreach ($tfield in $item.Template.Fields) {
        if ($tfield -eq $null -or $tfield.Name -match '^__') { continue }
        $fname = $tfield.Name
        $field = $item.Fields[$fname]

        if ($field -eq $null) { continue }

        try {
            $raw = $field.Value

            if ($tfield.Type -match '(?i)image') {
                $img = [Sitecore.Data.Fields.ImageField]$field
                if ($img -and $img.MediaItem) {
                    $options = New-Object Sitecore.Resources.Media.MediaUrlOptions
                    $options.AlwaysIncludeServerUrl = $includeAbsoluteMediaUrl
                    $row[$fname] = [Sitecore.Resources.Media.MediaManager]::GetMediaUrl($img.MediaItem, $options)
                }
                else {
                    $row[$fname] = ""
                }
            }
            elseif ($tfield.Type -match '(?i)rich\s*text') {
                if ($raw) {
                    #$plain = [regex]::Replace($raw, '<[^>]+>', ' ')
                    #$plain = [regex]::Replace($plain, '\s{2,}', ' ').Trim()
                    $row[$fname] = if ($raw) { $raw } else { [System.Web.HttpUtility]::HtmlEncode($raw) }
                }
            }
            else {
                $row[$fname] = if ($raw) { $raw } else { "" }
            }
        }
        catch {
            $row[$fname] = "ERROR: $($_.Exception.Message)"
        }
    }

    [PSCustomObject]$row
}

# Display dynamically
$results | Show-ListView -Property $properties -Title "Dynamic Item Fields Report"

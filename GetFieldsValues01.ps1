# Path to your parent item 
$parentItemPath = "master:/sitecore/content/Home/Articles"

# Get all child items
$items = Get-ChildItem -Path $parentItemPath

foreach ($item in $items) {
    Write-Host "Item Name: $($item.Name)"

    # Get all fields from the template
    $fields = $item.Template.Fields | Where-Object { -not $_.Name.StartsWith("__") }

    foreach ($field in $fields) {
        $fieldValue = $item[$field.Name]
        if ([string]::IsNullOrWhiteSpace($fieldValue)) {
            $fieldValue = "[empty]"
        }
        Write-Host "Field: $($field.Name) | Value: $fieldValue"
    }
    Write-Host "`n"
    Write-Host "** End of Item: $($item.Name)**"  
    Write-Host "`n" # Line break between items

}

# Databases to clean
$databases = @("core", "master", "web")

# Cutoff date = today - 30 days
$cutoffDate = [DateTime]::UtcNow.AddDays(-30)

foreach ($db in $databases) {
    try {
        $connectionString = [Sitecore.Configuration.Settings]::GetConnectionString($db)
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $sqlConnection.Open()

        Write-Host "Cleaning History table in database: $db (before $cutoffDate)" -ForegroundColor Yellow

        $sqlCmd = $sqlConnection.CreateCommand()
        $sqlCmd.CommandText = "DELETE FROM [History] WHERE [Created] < @CutoffDate"
        $null = $sqlCmd.Parameters.Add("@CutoffDate", [System.Data.SqlDbType]::DateTime)
        $sqlCmd.Parameters["@CutoffDate"].Value = $cutoffDate

        $rowsDeleted = $sqlCmd.ExecuteNonQuery()
        Write-Host "   Deleted $rowsDeleted rows from History table in $db" -ForegroundColor Cyan

        $sqlConnection.Close()
    }
    catch {
        Write-Warning "Failed to clean History table in $db : $_" -ForegroundColor Red
    }
}

Write-Host "✅ Cleanup completed: History table records older than 30 days deleted." -ForegroundColor Green
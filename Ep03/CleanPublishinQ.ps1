# 1. Prompting the User for Input
$props = @{
    Parameters  = @(
        @{
            Name  = "inputValue"
            Title = "Enter number of days to keep in Publishing Queue (0 = delete all)"
        }
    )
    Title       = "Days to Keep"
    Description = "Enter number of days to keep in Publishing Queue (0 = delete all)"
    Width       = 500
    Height      = 400
}

$result = Read-Variable @props

# 2. Validating the User Input

try {
    $daysToKeep = [int]$inputValue
    Write-Host "You entered: $daysToKeep"
}
catch {
    Write-Host "Invalid input, please enter a number."
}

if ($daysToKeep -lt 0) {
    Write-Host "Invalid input. Please enter 0 or a positive number of days." -ForegroundColor Red
    exit
}

#3. Determining the Cutoff Date (Always in UTC)
if ($daysToKeep -eq 0) {
    $cutoffDate = Get-Date   # keep nothing (delete all older than now)
    Write-Host "Deleting ALL items from Publishing Queue..." -ForegroundColor Yellow
}
else {
    $cutoffDate = (Get-Date).AddDays(-$daysToKeep)
    Write-Host "Cleaning Publishing Queue... Keeping only last $daysToKeep days (Cutoff: $cutoffDate)" -ForegroundColor Cyan
}


#$cutoffDate = (Get-Date).AddDays(-$daysToKeep)

Write-Host "Cleaning Publishing Queue... Keeping items newer than $cutoffDate"

#4. Connecting to the Database
$connectionString = [Sitecore.Configuration.Settings]::GetConnectionString("master")


$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connectionString
$sqlConnection.Open()

# 5. Building and Running the SQL Delete Command
$sqlCmd = $sqlConnection.CreateCommand()
$sqlCmd.CommandText = "DELETE FROM PublishQueue WHERE Date < @Cutoff"
$sqlCmd.Parameters.Add("@Cutoff", [System.Data.SqlDbType]::DateTime).Value = $cutoffDate

$rowsDeleted = $sqlCmd.ExecuteNonQuery()
Write-Host "$rowsDeleted rows deleted from PublishQueue (master)."

# 6. Closing the Database Connection
$sqlConnection.Close()

Write-Host "Publishing Queue cleanup completed."

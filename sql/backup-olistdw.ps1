param(
    [string]$Server = 'SQLSERVER-DEMO\SQLEXPRESS',
    [string]$Database = 'OlistDW',
    [string]$BackupFile = 'OlistDW_backup.bak'
)

$ErrorActionPreference = 'Stop'
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source'] = $Server
$builder['Initial Catalog'] = 'master'
$builder['Integrated Security'] = $true
$builder['Encrypt'] = $true
$builder['TrustServerCertificate'] = $true
$builder['Connect Timeout'] = 30
$connection = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
$connection.Open()
try {
    $command = $connection.CreateCommand()
    $command.CommandTimeout = 600
    $safeDatabase = $Database.Replace(']', ']]')
    $safeFile = $BackupFile.Replace("'", "''")
    $command.CommandText = "BACKUP DATABASE [$safeDatabase] TO DISK = N'$safeFile' WITH COPY_ONLY, INIT, CHECKSUM, STATS = 10; RESTORE VERIFYONLY FROM DISK = N'$safeFile' WITH CHECKSUM;"
    [void]$command.ExecuteNonQuery()
    Write-Output "Backup and RESTORE VERIFYONLY completed: $BackupFile"
} finally {
    $connection.Dispose()
}

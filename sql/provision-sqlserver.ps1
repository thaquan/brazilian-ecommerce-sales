param([string]$Server = 'SQLSERVER-DEMO\SQLEXPRESS')
$ErrorActionPreference = 'Stop'
function Open-OlistConnection([string]$Database) {
    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $builder['Data Source'] = $Server
    $builder['Initial Catalog'] = $Database
    $builder['Integrated Security'] = $true
    $builder['Encrypt'] = $true
    $builder['TrustServerCertificate'] = $true # Local development SQL instance.
    $builder['Connect Timeout'] = 15
    $connection = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
    $connection.Open()
    return $connection
}
$connection = Open-OlistConnection 'master'
try {
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion'))"
    if ([int]$command.ExecuteScalar() -lt 15) { throw 'SQL Server 2019+ required for UTF-8 varchar parity with Fabric.' }
    $command.CommandTimeout = 60
    $command.CommandText = "IF DB_ID(N'OlistDW') IS NULL CREATE DATABASE [OlistDW] COLLATE Latin1_General_100_CI_AS_SC_UTF8;"
    [void]$command.ExecuteNonQuery()
} finally { $connection.Dispose() }
$connection = Open-OlistConnection 'OlistDW'
try {
    $command = $connection.CreateCommand()
    $command.CommandTimeout = 60
    $ddlPath = Join-Path $PSScriptRoot '..\fabric\sql\02_create_gold.sql'
    $command.CommandText = [IO.File]::ReadAllText((Resolve-Path $ddlPath).Path)
    [void]$command.ExecuteNonQuery()
    $command.CommandText = @'
SELECT DB_NAME() AS database_name, CONVERT(nvarchar(128),DATABASEPROPERTYEX(DB_NAME(),'Collation')) AS collation;
SELECT t.name AS table_name, SUM(p.rows) AS row_count
FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id
JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN (0,1)
WHERE s.name='dbo' AND t.name IN ('DimDate','DimCustomer','DimProduct','DimSeller','FactOrders','FactOrderItem','FactPayments','GoldLoadAudit')
GROUP BY t.name ORDER BY t.name;
'@
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $results = New-Object System.Data.DataSet
    [void]$adapter.Fill($results)
    foreach ($table in $results.Tables) { $table | Format-Table -AutoSize | Out-String | Write-Output }
} finally { $connection.Dispose() }

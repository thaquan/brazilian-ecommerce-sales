$ErrorActionPreference='Stop'
$c=New-Object System.Data.SqlClient.SqlConnection 'Server=SQLSERVER-DEMO\SQLEXPRESS;Database=OlistDW;Integrated Security=True;Connect Timeout=15;Encrypt=True;TrustServerCertificate=True'
$results=@()
try {
 $c.Open()
 $q=$c.CreateCommand(); $q.CommandTimeout=60
 $sql=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'validation\09_reconcile_sqlserver.sql'))
 $keys=@{DimDate='date_key';DimCustomer='customer_key';DimProduct='product_key';DimSeller='seller_key';FactOrders='order_key';FactOrderItem='sales_key';FactPayments='payment_key'}
 foreach($table in ($keys.Keys | Sort-Object)) {
  $key=$keys[$table]
  $sql+="`nSELECT '$table' AS table_name, COUNT_BIG(*)-COUNT_BIG(DISTINCT [$key]) AS duplicate_or_null_keys FROM dbo.[$table];"
 }
 foreach($table in @('FactOrders','FactOrderItem','FactPayments')) {
  $sql+="`nSELECT '${table}_PurchaseDate' AS check_name, COUNT_BIG(*) AS orphan_count FROM dbo.[$table] f LEFT JOIN dbo.DimDate d ON d.date_key=f.purchase_date_key WHERE d.date_key IS NULL;"
 }
 foreach($key in @('delivered_date_key','estimated_date_key')) {
  $sql+="`nSELECT 'FactOrders_$key' AS check_name, COUNT_BIG(*) AS orphan_count FROM dbo.FactOrders f LEFT JOIN dbo.DimDate d ON d.date_key=f.[$key] WHERE f.[$key] IS NOT NULL AND d.date_key IS NULL;"
 }
 $sql+="`nSELECT 'OrderItemGrain' AS check_name,COUNT_BIG(*) AS duplicate_groups FROM (SELECT order_id,order_item_id FROM dbo.FactOrderItem GROUP BY order_id,order_item_id HAVING COUNT_BIG(*)>1) d;"
 $sql+="`nSELECT 'PaymentGrain' AS check_name,COUNT_BIG(*) AS duplicate_groups FROM (SELECT order_id,payment_sequential FROM dbo.FactPayments GROUP BY order_id,payment_sequential HAVING COUNT_BIG(*)>1) d;"
 $q.CommandText=$sql
 $reader=$q.ExecuteReader(); $index=0
 do {
  $rows=@()
  while($reader.Read()) {
   $row=[ordered]@{}
   for($i=0;$i -lt $reader.FieldCount;$i++) { $row[$reader.GetName($i)]=if($reader.IsDBNull($i)){$null}else{$reader.GetValue($i)} }
   $rows += [pscustomobject]$row
  }
  $results += [pscustomobject]@{resultSet=$index;rows=$rows}; $index++
 }while($reader.NextResult())
}finally{$c.Dispose()}
$evidence=[ordered]@{checkedAt=(Get-Date).ToString('o');server='SQLSERVER-DEMO\SQLEXPRESS';database='OlistDW';results=$results}
$path=Join-Path $PSScriptRoot '..\docs\phase-9-sql-validation.json'
$json=$evidence | ConvertTo-Json -Depth 9
[IO.File]::WriteAllText($path,$json)
$json

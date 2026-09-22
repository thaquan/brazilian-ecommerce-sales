[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "brz_orders_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared brz_orders = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "landing"]}[Content],
  #"Navigation 4" = #"Navigation 3"{[Name = "olist"]}[Content],
  #"Navigation 5" = #"Navigation 4"{[Name = "olist_orders_dataset.csv"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 5", [Delimiter = ",", Columns = 8, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Promoted headers", "_batch_id", each "20260912_001"), {{"_batch_id", type text}}),
  #"Added custom 1" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom", "_source_file", each "olist_orders_dataset.csv"), {{"_source_file", type text}}),
  #"Added custom 2" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 1", "_source_system", each "kaggle_olist"), {{"_source_system", type text}}),
  #"Added custom 3" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 2", "_ingest_ts", each DateTimeZone.UtcNow()), {{"_ingest_ts", type datetime}})
in
  #"Added custom 3";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "brz_customers_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared brz_customers = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "landing"]}[Content],
  #"Navigation 4" = #"Navigation 3"{[Name = "olist"]}[Content],
  #"Navigation 5" = #"Navigation 4"{[Name = "olist_customers_dataset.csv"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 5", [Delimiter = ",", Columns = 5, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Promoted headers", "_batch_id", each "20260912_001"), {{"_batch_id", type text}}),
  #"Added custom 1" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom", "_source_file", each "olist_customers_dataset.csv"), {{"_source_file", type text}}),
  #"Added custom 2" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 1", "_source_system", each "kaggle_olist"), {{"_source_system", type text}}),
  #"Added custom 3" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 2", "_ingest_ts", each DateTimeZone.UtcNow()), {{"_ingest_ts", type datetime}})
in
  #"Added custom 3";
shared brz_customers_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "brz_customers", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared brz_orders_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "brz_orders", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "brz_order_items_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared brz_order_items = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "landing"]}[Content],
  #"Navigation 4" = #"Navigation 3"{[Name = "olist"]}[Content],
  #"Navigation 5" = #"Navigation 4"{[Name = "olist_order_items_dataset.csv"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 5", [Delimiter = ",", Columns = 7, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Promoted headers", "_batch_id", each "20260912_001"), {{"_batch_id", type text}}),
  #"Added custom 1" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom", "_source_file", each "olist_order_items_dataset.csv"), {{"_source_file", type text}}),
  #"Added custom 2" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 1", "_source_system", each "kaggle_olist"), {{"_source_system", type text}}),
  #"Added custom 3" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 2", "_ingest_ts", each DateTimeZone.UtcNow()), {{"_ingest_ts", type datetime}})
in
  #"Added custom 3";
shared brz_order_items_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "brz_order_items", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "brz_payments_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared brz_payments = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "landing"]}[Content],
  #"Navigation 4" = #"Navigation 3"{[Name = "olist"]}[Content],
  #"Navigation 5" = #"Navigation 4"{[Name = "olist_order_payments_dataset.csv"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 5", [Delimiter = ",", Columns = 5, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Promoted headers", "_batch_id", each "20260912_001"), {{"_batch_id", type text}}),
  #"Added custom 1" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom", "_source_file", each "olist_order_payments_dataset.csv"), {{"_source_file", type text}}),
  #"Added custom 2" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 1", "_source_system", each "kaggle_olist"), {{"_source_system", type text}}),
  #"Added custom 3" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 2", "_ingest_ts", each DateTimeZone.UtcNow()), {{"_ingest_ts", type datetime}})
in
  #"Added custom 3";
shared brz_payments_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "brz_payments", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "brz_reviews_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared brz_reviews = let
    BatchId = "20260912_001",
    SourceFile = "olist_order_reviews_dataset.csv",
    IngestTs = DateTimeZone.RemoveZone(DateTimeZone.FixedUtcNow()),
    Source = Lakehouse.Contents(null),
    Workspace = Source{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
    Lakehouse = Workspace{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
    Files = Lakehouse{[Id = "Files", ItemKind = "Folder"]}[Data],
    Landing = Files{[Name = "landing"]}[Content],
    Olist = Landing{[Name = "olist"]}[Content],
    Binary = Olist{[Name = SourceFile]}[Content],
    Imported = Csv.Document(Binary, [Delimiter = ",", Columns = 7, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Headers = Table.PromoteHeaders(Imported, [PromoteAllScalars = true]),
    Batch = Table.AddColumn(Headers, "_batch_id", each BatchId, type text),
    File = Table.AddColumn(Batch, "_source_file", each SourceFile, type text),
    System = Table.AddColumn(File, "_source_system", each "kaggle_olist", type text),
    Ingest = Table.AddColumn(System, "_ingest_ts", each IngestTs, type datetime)
in
    Ingest;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "brz_products_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared brz_products = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "landing"]}[Content],
  #"Navigation 4" = #"Navigation 3"{[Name = "olist"]}[Content],
  #"Navigation 5" = #"Navigation 4"{[Name = "olist_products_dataset.csv"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 5", [Delimiter = ",", Columns = 9, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Promoted headers", "_batch_id", each "20260912_001"), {{"_batch_id", type text}}),
  #"Added custom 1" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom", "_source_file", each "olist_products_dataset.csv"), {{"_source_file", type text}}),
  #"Added custom 2" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 1", "_source_system", each "kaggle_olist"), {{"_source_system", type text}}),
  #"Added custom 3" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 2", "_ingest_ts", each DateTimeZone.UtcNow()), {{"_ingest_ts", type datetime}})
in
  #"Added custom 3";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "brz_sellers_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared brz_sellers = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "landing"]}[Content],
  #"Navigation 4" = #"Navigation 3"{[Name = "olist"]}[Content],
  #"Navigation 5" = #"Navigation 4"{[Name = "olist_sellers_dataset.csv"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 5", [Delimiter = ",", Columns = 4, Encoding = 65001, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Promoted headers", "_batch_id", each "20260912_001"), {{"_batch_id", type text}}),
  #"Added custom 1" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom", "_source_file", each "olist_sellers_dataset.csv"), {{"_source_file", type text}}),
  #"Added custom 2" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 1", "_source_system", each "kaggle_olist"), {{"_source_system", type text}}),
  #"Added custom 3" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 2", "_ingest_ts", each DateTimeZone.UtcNow()), {{"_ingest_ts", type datetime}})
in
  #"Added custom 3";
shared brz_reviews_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "brz_reviews", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared brz_products_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "brz_products", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared brz_sellers_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "brz_sellers", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "brz_category_translation_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared brz_category_translation = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "landing"]}[Content],
  #"Navigation 4" = #"Navigation 3"{[Name = "olist"]}[Content],
  #"Navigation 5" = #"Navigation 4"{[Name = "product_category_name_translation.csv"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 5", [Delimiter = ",", Columns = 2, Encoding = 65001, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Promoted headers", "_batch_id", each "20260912_001"), {{"_batch_id", type text}}),
  #"Added custom 1" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom", "_source_file", each "product_category_name_translation.csv"), {{"_source_file", type text}}),
  #"Added custom 2" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 1", "_source_system", each "kaggle_olist"), {{"_source_system", type text}}),
  #"Added custom 3" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 2", "_ingest_ts", each DateTimeZone.UtcNow()), {{"_ingest_ts", type datetime}})
in
  #"Added custom 3";
shared brz_category_translation_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "brz_category_translation", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "brz_geolocation_DataDestination", IsNewTarget = false], Settings = [Kind = "Manual", AllowCreation = false, ColumnSettings = [Mappings = {[SourceColumnName = "geolocation_zip_code_prefix", DestinationColumnName = "geolocation_zip_code_prefix"], [SourceColumnName = "geolocation_lat", DestinationColumnName = "geolocation_lat"], [SourceColumnName = "geolocation_lng", DestinationColumnName = "geolocation_lng"], [SourceColumnName = "geolocation_city", DestinationColumnName = "geolocation_city"], [SourceColumnName = "geolocation_state", DestinationColumnName = "geolocation_state"], [SourceColumnName = "_batch_id", DestinationColumnName = "_batch_id"], [SourceColumnName = "_source_system", DestinationColumnName = "_source_system"], [SourceColumnName = "_ingest_ts", DestinationColumnName = "_ingest_ts"], [SourceColumnName = "_source_file", DestinationColumnName = "_source_file"]}], DynamicSchema = false, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared brz_geolocation = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "landing"]}[Content],
  #"Navigation 4" = #"Navigation 3"{[Name = "olist"]}[Content],
  #"Navigation 5" = #"Navigation 4"{[Name = "olist_geolocation_dataset.csv"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 5", [Delimiter = ",", Columns = 5, Encoding = 65001, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Promoted headers", "_batch_id", each "20260912_001"), {{"_batch_id", type text}}),
  #"Added custom 1" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom", "_source_file", each "olist_geolocation_dataset.csv"), {{"_source_file", type text}}),
  #"Added custom 2" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 1", "_source_system", each "kaggle_olist"), {{"_source_system", type text}}),
  #"Added custom 3" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom 2", "_ingest_ts", each DateTimeZone.UtcNow()), {{"_ingest_ts", type datetime}})
in
  #"Added custom 3";
shared brz_geolocation_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "23f4a256-949e-5f7d-8c35-b63242139c25"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "1a0acf7b-bf59-5b79-94a8-b89cd8bb645e"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "brz_geolocation", ItemKind = "Table"]}[Data]
in
  TableNavigation;

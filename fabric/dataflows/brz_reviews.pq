let
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
    Ingest

# Ma trận kiểm thử và bằng chứng

Phân biệt bằng chứng đã lưu với hướng dẫn kiểm thử. Các số liệu ở đây thuộc snapshot đồ án, không phải số liệu thời gian thực.

| Kiểm tra | Kết quả | Bằng chứng |
|---|---|---|
| SQL: số dòng 7 bảng | Đã kiểm tra | [SQL JSON](phase-9-sql-validation.json) |
| SQL: surrogate key null/trùng, orphan, item/payment grain | 0 lỗi trong kiểm tra đã lưu | [SQL JSON](phase-9-sql-validation.json) |
| Model SQL: 8 active + 1 inactive | Đã cấu hình và kiểm tra cục bộ | [relationships TMDL](../powerbi/Olist_SQLServer.SemanticModel/definition/relationships.tmdl) |
| Model SQL trên Service: 7 bảng, 33 measures, 9 quan hệ | Đã đọc qua MCP | [Biên bản Service](phase-9-service-verification-20260921.md) |
| KPI Service khớp SQL đã lưu | Đạt với 4 KPI đã truy vấn | [DAX JSON](evidence/phase-9/service-dax.json) |
| Customer/date/seller filter scope | Đạt trong DAX Desktop | [Bảng kết quả](../powerbi/README-sqlserver.md) |
| 5 DEMO_USER SQL render Desktop | Đã xem ảnh, không visual error | [Ảnh](../powerbi/screenshots/sqlserver/Overview.png) |
| Overview trên Service | Hiển thị dữ liệu | [Ảnh — ảnh gốc giữ riêng](evidence/phase-9/README.md) |
| Pipeline Gold → SQL Server | 7/7 Succeeded | [Ảnh — ảnh gốc giữ riêng](evidence/phase-9/README.md) |
| Gateway mapping | Đúng CN_Olist_SQLServer, Running | [Ảnh — ảnh gốc giữ riêng](evidence/phase-9/README.md) |
| Refresh Service | Completed, 27 giây | [Ảnh — ảnh gốc giữ riêng](evidence/phase-9/README.md) |
| RLS Fabric: SP, REMOVEFILTERS, RJ, audit | Đạt với XMLA role impersonation | [Evidence](../powerbi/rls-evidence-20260919.json) |
| RLS web/actual Viewer | Bỏ qua web do SSO; Viewer chưa xác minh | [RLS notes](../powerbi/rls-customer-state.md) |
| RLS SQL model | Chưa triển khai | RoleCount=0 khi kiểm tra Service |
| E2E normal/rerun, DQ failure chặn downstream, recovery | Chưa có evidence đủ trong bộ tài liệu được rà soát để kết luận PASS | [Quy trình cần kiểm tra](phase-6-e2e-pipeline.md) |
| Snapshot đối soát Fabric/SQL đồng thời mới | Chưa thực hiện | Dùng các baseline đã lưu, không thay thế kiểm tra đồng thời |

## Baseline số dòng SQL

| Bảng | Dòng |
|---|---:|
| DimDate | 1,096 |
| DimCustomer | 96,096 |
| DimProduct | 32,951 |
| DimSeller | 3,095 |
| FactOrders | 99,441 |
| FactOrderItem | 112,650 |
| FactPayments | 103,886 |

## Cách lưu kết quả mới

Ghi ngày giờ/múi giờ hiển thị, model/workspace, Pipeline RunId và Silver run_id nếu áp dụng. Lưu query, output, screenshot và mô tả PASS/FAIL/SKIPPED. Khi nguồn thay đổi, lưu baseline mới thay vì ép kết quả về baseline trên.

Báo cáo giai đoạn 5 ngày 15/09 ghi dữ liệu rỗng tại thời điểm đó. Giữ tài liệu làm lịch sử; không dùng nó làm trạng thái hiện tại hoặc xóa bằng chứng cũ. Xem biên bản Service ngày 21/09 cho trạng thái nhánh SQL mới nhất.

## Ki?m tra export b? sung

7 file ng??i d?ng export ?? ???c ??c v? gi?i n?n an to?n. JSON v? notebook parse th?nh c?ng; code notebook compile ???c (kh?ng th?c thi Spark). Dataflow c? 9 query ngu?n/9 destination. 3 b?n nh?ng PL_Olist_Load_Staging gi?ng nhau. TMDL Fabric xu?t qua MCP ???c n?p offline: 8 b?ng, 20 base measures, 9 quan h?. ??y l? ki?m tra c?u tr?c, kh?ng ch?ng minh import/run th?nh c?ng ? tenant kh?c. Xem [review](fabric-export-review.md).

# Runbook triển khai và vận hành

## Điều kiện chuẩn bị

- Quyền tạo/chạy các item trong Fabric workspace; Lakehouse Bronze/Silver và Warehouse Gold.
- 9 nguồn Olist có schema tương ứng notebook. Xem [nguồn dữ liệu](sources.md).
- SQL Server 2019+ theo yêu cầu UTF-8 của script provisioning, Windows authentication và quyền tạo database/table.
- Power BI Desktop hỗ trợ định dạng PBIP/PBIR của các file trong dự án; tài khoản có quyền publish vào workspace.
- Standard gateway đã đăng ký và chạy trên máy có thể truy cập SQL Server. Nhập credentials riêng trong giao diện connection, không đặt vào repository.

## Khởi tạo Fabric

1. Tạo/kiểm tra LH_Olist_Bronze, LH_Olist_Silver và WH_Olist_Gold.
2. Cấu hình Dataflow DF_Olist_Bronze cho 9 nguồn; tham khảo bản sửa reviews tại `fabric/dataflows/brz_reviews.pq`. Template đầy đủ hiện có tại `fabric/dataflows/templates/DF_Olist_Bronze.pqt`; xem [export review](fabric-export-review.md).
3. Import `fabric/notebooks/NB_Olist_Silver_reviewed.ipynb`, gắn đúng Lakehouse và kiểm tra tên nguồn. Chạy toàn bộ cell theo thứ tự. Bản export mới đã có cell exit cuối; nếu dùng bản notebook cũ, bổ sung cell cuối từ `fabric/notebooks/phase6_pipeline_exit_cell.py` đúng hướng dẫn giai đoạn 6.
4. Kiểm tra notebook kết thúc thành công, các bảng Silver đã ghi đủ và DQ của đúng run_id không có ERROR. PASS DQ riêng lẻ không đảm bảo bước ghi Silver đã thành công.
5. Chạy trong Warehouse, từng batch: `00_preflight_silver.sql`, `01_create_staging.sql`, `02_create_gold.sql`, `03a_create_staging_validation.sql`, `03b_create_gold_validation.sql`, `04_create_usp_build_gold.sql` tại `fabric/sql/`. DDL không tự migrate bảng đã tồn tại.
6. Cấu hình 9 Copy Silver → staging theo [giai đoạn 5](phase-5-gold-warehouse.md); giữ nguồn cố định trong lúc nạp.
7. Truyền Silver run_id mới nhất vào procedure; xem chữ ký trong `04_create_usp_build_gold.sql`. Không thay bằng Pipeline RunId.
8. Chạy `05_validate_and_reconcile.sql`, kiểm tra audit và các validation view trước khi mở báo cáo.

## Vận hành Fabric E2E

Thực hiện đúng [hướng dẫn pipeline](phase-6-e2e-pipeline.md). Ghi Pipeline RunId, Silver run_id, kết quả activity và GoldLoadAudit cho cùng lượt nạp. Không chạy pipeline cha, pipeline con và notebook thủ công đồng thời.

```sql
SELECT TOP (10) * FROM dbo.GoldLoadAudit ORDER BY completed_at DESC;
SELECT * FROM dbo.vw_StageValidation WHERE failed_rows > 0;
SELECT * FROM dbo.vw_GoldValidation WHERE failed_rows > 0;
```

Hai truy vấn validation phải rỗng. Test DQ cưỡng bức chỉ dùng bản TEST theo tài liệu; không sửa dữ liệu thật để tạo lỗi. Sau test cần khôi phục bằng lượt chạy bình thường.

## Nhánh SQL Server

Từ thư mục gốc dự án, khởi tạo database bằng Windows authentication:

```powershell
.\sql\provision-sqlserver.ps1 -Server 'SQLSERVER-DEMO\SQLEXPRESS'
```

Script giữ bảng hiện có, tạo OlistDW và 7 bảng nghiệp vụ + audit nếu thiếu. Không tự nạp dữ liệu. Máy khác thay Server theo thực tế.

Trong PL_Olist_Gold_To_SQLServer, copy lần lượt DimDate, DimCustomer, DimProduct, DimSeller, FactOrders, FactOrderItem, FactPayments. Source là bảng dbo trong Warehouse; destination là bảng dbo trong OlistDW qua gateway. Mapping đúng cột và decimal; pre-copy truncate đúng bảng đích rồi insert. Đây là thao tác thay toàn bộ dữ liệu đích, chỉ chạy sau khi nguồn đã đạt kiểm tra.

Chờ cả 7 activity Succeeded rồi đối soát:

```powershell
.\sql\validate-sqlserver.ps1
```

Script hiện cố định server mẫu ở phần đầu và ghi đè `docs/phase-9-sql-validation.json`; nếu lưu lịch sử, sao chép evidence cũ trước khi chạy. Đây là bộ thu thập kết quả, không phải bộ gate tự động chặn pipeline. Đọc tất cả duplicate/orphan/grain checks, yêu cầu số lỗi bằng 0, so tổng tiền và số dòng với Gold cùng snapshot.

Mở `powerbi/Olist_SQLServer.pbip`, cấp quyền SQL trong Desktop và Refresh. Publish với tên riêng, sau đó trên Service ánh xạ nguồn SQL tới CN_Olist_SQLServer/GW_Olist_Demo, Refresh now và lưu Refresh history Completed. Bản triển khai hiện tại đã hoàn thành bước này; không cần chạy lại chỉ để chụp ảnh.

## Báo cáo và kiểm tra sau refresh

- Overview: 99,441 đơn và BRL 15,843,553.24 order value trên snapshot đã lưu.
- Payments: BRL 16,008,872.12; payment và order value là hai chỉ số khác nhau.
- Chọn SP: Orders 41,752, Items 47,461, Payments BRL 6,000,585.04 trên snapshot này.
- Chọn seller SP chỉ thay item metrics; không kỳ vọng Total Orders/Payment Value giảm.
- Đổi ngày mua phải tác động cả ba fact. Home và sidebar phải dẫn tới đúng DEMO_USER.

## Xử lý lỗi

| Triệu chứng | Hành động |
|---|---|
| DQ ERROR | Đọc rule của đúng run_id, sửa nguyên nhân rồi chạy lại; không bỏ gate |
| Một Copy thất bại | Không build/refresh downstream; sửa và hoàn tất một batch nhất quán |
| Run_id cũ bị từ chối | Lấy exitValue notebook mới, không dùng lại mã cũ |
| Gateway Offline | Kiểm tra máy, mạng và dịch vụ gateway; sau đó xác nhận trong Service |
| Không tìm thấy connection mapping | Kiểm tra chính xác server, instance, database và quyền dùng connection |
| Visual thiếu measure | Kiểm tra report đang trỏ đúng model và schema/measure trong TMDL |
| Web Test as role báo SSO | Ghi chưa kiểm chứng web; không coi là test đạt hoặc tự đổi identity |

## Chuyển sang môi trường khác

Thay server trong provisioning, validation và Power Query source của 7 bảng SQL model; thay connection/workspace/item IDs của Fabric, pipeline và report live connection. Kiểm tra đường dẫn tương đối PBIP/Report/SemanticModel. Không chỉnh GUID nếu chỉ đang mở lại dự án trên môi trường gốc.

RLS pilot chứa UPN đã dùng cho demo: thay mapping theo người dùng thực tế trước khi áp dụng ở tenant khác. Role trên Fabric không tự chuyển sang SQL model.

Scheduled refresh hiện Off. Chỉ đặt lịch sau khi luồng nạp có cơ chế hoàn tất batch và thứ tự phụ thuộc rõ ràng; máy SQL/gateway phải sẵn sàng. Tránh refresh Import khi truncate/insert đang chạy.

> Ghi chú cập nhật 21/09/2026: nội dung triển khai/kiểm tra dưới đây được giữ theo thời điểm ghi nhận. Xem [trạng thái và evidence mới nhất](testing.md). Không suy luận test đã đạt chỉ từ hướng dẫn cấu hình.

# Giai đoạn 5 — Gold Warehouse

Bộ hướng dẫn này dựa trên `fabric/notebooks/NB_Olist_Silver_reviewed.ipynb` trong repository.
Tên sử dụng: `LH_Olist_Silver.dbo` và `WH_Olist_Gold`, cùng workspace.
SQL nằm trong `../fabric/sql/`. Đây là bản full rebuild cho bộ dữ liệu đồ án.
Chưa triển khai hay chạy SQL trên Fabric từ môi trường cục bộ.

## 1. Mở Warehouse và xác nhận Silver

Mở `WH_Olist_Gold` đã tạo. Nếu chưa có: workspace → New item → Warehouse → đặt tên `WH_Olist_Gold`.
Tất cả SQL dưới đây chạy trong **Warehouse**, ở New SQL query.
SQL analytics endpoint của Lakehouse chỉ dùng đọc dữ liệu Silver.

Trong Explorer của Warehouse, thêm SQL analytics endpoint `LH_Olist_Silver` bằng tùy chọn thêm warehouse/endpoint nếu cần.
Chạy `00_preflight_silver.sql`. Nếu tên hoặc schema khác thực tế, sửa tham chiếu trong các file SQL trước khi chạy.

Xác nhận lần Run All mới nhất hoàn tất cả cell ghi 10 bảng và cell đếm dòng cuối.
Ghi lại `run_id` mới nhất, yêu cầu `fail_count = 0`; WARN phải được xem xét.
Notebook ghi DQ trước khi ghi Silver, vì vậy PASS không thay thế kiểm tra notebook thành công.
Giữ Silver cố định trong suốt copy và build; không chạy notebook/pipeline khác đồng thời.

## 2. Tạo cấu trúc

Chạy riêng từng file, đúng thứ tự:

1. `01_create_staging.sql` — 9 bảng staging.
2. `02_create_gold.sql` — 4 dimension, 3 fact và bảng audit.
3. `03a_create_staging_validation.sql` — view 68 quy tắc staging.
4. `03b_create_gold_validation.sql` — view 50 quy tắc Gold.
5. `04_create_usp_build_gold.sql` — tạo procedure, chưa nạp Gold.

Mỗi file CREATE OR ALTER VIEW/PROCEDURE phải chạy riêng trong query/batch của nó.
DDL bỏ qua bảng đã tồn tại, không tự sửa schema cũ. Nếu đã có bảng cùng tên, đối chiếu cột và kiểu trước.

## 3. Tạo pipeline copy Silver → staging

Workspace → New item → Data pipeline → `PL_Olist_Load_Staging`.
Thêm Copy data activity đầu tiên, tên `CP_orders`.

Source:

- Connection: `LH_Olist_Silver`.
- Root folder: Tables; Use query: Table.
- Schema: dbo; Table: slv_orders.

Destination:

- Connection: `WH_Olist_Gold`.
- Table option: Use existing.
- Table: staging.orders.
- Write behavior: Insert.
- Advanced → Pre-copy script: `TRUNCATE TABLE staging.orders;`.

Mapping → Import schemas → chỉ giữ các cặp có trong `copy_activity_mapping.csv`.
Các cột nguồn dư không có đích thì bỏ khỏi mapping. Không tạo metadata giả.
Đối chiếu NOT NULL và độ dài chuỗi trong `01_create_staging.sql`.
ZIP là chuỗi 5 ký tự; tiền là decimal; timestamp đích là datetime2(6).
Nếu cần staged copy, Settings → Enable staging → Workspace. Đây là vùng lưu tạm của Copy,
khác schema `staging` trong Warehouse.

Nhân bản activity và đổi nguồn, đích, mapping, pre-copy cho đủ 9 cặp:

| Silver (dbo) | Warehouse |
|---|---|
| slv_orders | staging.orders |
| slv_order_items | staging.order_items |
| slv_customers | staging.customers |
| slv_customer_current | staging.customer_current |
| slv_products | staging.products |
| slv_sellers | staging.sellers |
| slv_payments | staging.payments |
| slv_reviews_order | staging.reviews_order |
| slv_date | staging.date |

Không copy `slv_geolocation_zip`: tọa độ đã được ghép vào customer_current/sellers.
Không copy `dq_results` vào bảng business staging: SQL kiểm tra đọc audit trực tiếp từ Silver.
Nối các activity bằng điều kiện On success cho lần triển khai đầu, Save và Run.
Yêu cầu cả 9 activity thành công; kiểm tra rowsRead/rowsCopied và không bỏ qua bản ghi lỗi.
Nếu một copy lỗi, sửa và chạy lại pipeline; không build Gold với staging mới nạp một phần.

## 4. Kiểm tra staging

Trong Warehouse chạy:

```sql
SELECT * FROM dbo.vw_StageValidation
WHERE failed_rows > 0
ORDER BY [rule];
```

Kết quả phải không có dòng. View kiểm tra bảng rỗng, khóa trùng, giá trị bắt buộc,
orphan, số dòng và dữ liệu các cột đã chọn so với Silver bằng EXCEPT hai chiều.
Nếu notebook vừa ghi Silver, kiểm tra SQL analytics endpoint đã phản ánh đủ schema/dữ liệu.
Không dùng số dòng mẫu trong bài viết thay cho số dòng Silver thực tế.

## 5. Nạp Gold

Lấy đúng `run_id` đã xác nhận ở bước 1 rồi chạy:

```sql
EXEC dbo.usp_build_gold
    @silver_run_id = 'THAY_BANG_RUN_ID_THUC_TE';
```

Procedure kiểm tra run DQ, kiểm tra staging, rebuild 7 bảng, kiểm tra Gold,
ghi một dòng thành công vào `dbo.GoldLoadAudit` và commit.
Phần thay đổi Gold nằm trong transaction; lỗi trong rebuild/validation được rollback.
Audit này chỉ ghi các lần thành công; lỗi vẫn xem trong kết quả query/pipeline.

| Bảng Gold | Một dòng đại diện cho |
|---|---|
| DimDate | Một ngày |
| DimCustomer | Một customer_unique_id |
| DimProduct | Một product_id |
| DimSeller | Một seller_id |
| FactOrders | Một order_id |
| FactOrderItem | Một cặp order_id, order_item_id |
| FactPayments | Một cặp order_id, payment_sequential |

Mapping khách: orders.customer_id → customers.customer_unique_id → DimCustomer.customer_key.
Review là LEFT JOIN từ reviews_order đã có một dòng/order, nên order thiếu review vẫn được giữ.
Payments và items vào hai fact riêng để tránh nhân bản giá trị khi join.
Tất cả trạng thái order được giữ; bộ lọc nghiệp vụ KPI sẽ được xác định ở semantic model.

Khóa số dùng ROW_NUMBER theo business key và dựng lại toàn bộ dimension/fact cùng lần.
Khóa có thể đổi khi nguồn thay đổi: không dùng bộ SQL này như incremental load hoặc dùng khóa
đã sinh để upsert từng phần sang SQL Server. Khi mở rộng incremental cần thiết kế khóa bền vững.

## 6. Đối soát và chạy lại

Chạy `05_validate_and_reconcile.sql`, rồi `06_preview_gold.sql`.
Mọi quy tắc staging/Gold phải PASS; tổng tiền cùng chỉ tiêu phải khớp qua các lớp.
Chạy lại EXEC với cùng Silver/staging, kiểm tra số dòng/tổng tiền không đổi và có thêm một audit thành công.
Việc chạy lại này kiểm tra full rebuild không nhân đôi dữ liệu.

Lưu bằng chứng: pipeline 9 copy thành công, run_id, kết quả validation,
số dòng 7 bảng và đối soát tiền trước/sau chạy lại.
Hoàn thành các mục này thì kết thúc giai đoạn 5. Giai đoạn 6 ghép Bronze → notebook →
copy → Gold với điều kiện thành công và DQ gate xuyên suốt.

## Quy ước nghiệp vụ cần giữ khi làm BI

- `item_gmv` hiện bằng `price + freight_value` theo notebook; ghi rõ bao gồm phí vận chuyển.
  Không mặc định gọi đây là doanh thu thực nhận của Olist. Giá trị hàng hóa riêng là SUM(price).
- So sánh cùng metric Silver/staging/Gold. Tổng payment không bị ép bằng tổng item_gmv;
  chênh lệch giữa hai chỉ tiêu là nội dung đối soát nghiệp vụ riêng.
- `DimCustomer` dùng vị trí hiện tại theo logic notebook, không phải lịch sử địa chỉ từng đơn.
- Review thiếu và is_late chưa xác định giữ NULL. Các bất thường delivery_days âm được giữ
  để xem xét, không tự biến thành quan sát giao hàng hợp lệ.
- Thiết kế quan hệ và phạm vi RLS cho tất cả fact thực hiện ở giai đoạn 7–8.

## Nguồn Microsoft

- [Tạo Warehouse](https://learn.microsoft.com/en-us/fabric/data-warehouse/create-warehouse)
- [Lakehouse Copy Activity](https://learn.microsoft.com/en-us/fabric/data-factory/connector-lakehouse-copy-activity)
- [Warehouse Copy Activity và pre-copy script](https://learn.microsoft.com/en-us/fabric/data-factory/connector-data-warehouse-copy-activity)
- [Kiểu dữ liệu Warehouse](https://learn.microsoft.com/en-us/fabric/data-warehouse/data-types)
- [Transaction và đọc Lakehouse endpoint](https://learn.microsoft.com/en-us/fabric/data-warehouse/transactions)

## Phạm vi kiểm thử cục bộ

`fabric/sql/check_phase5_logic.py` dùng SQLite sau chuyển đổi dialect để kiểm tra logic join,
khách mua lại, order thiếu review, chạy lại trên nguồn không đổi và phát hiện dữ liệu copy sai,
khóa trùng, orphan. Đây không phải kiểm thử cú pháp T-SQL hay transaction trên Fabric.
Chưa chạy Copy Activity, procedure hoặc đối soát bộ Olist thật trên Fabric từ môi trường này.

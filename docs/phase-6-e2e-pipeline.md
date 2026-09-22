> Ghi chú cập nhật 21/09/2026: nội dung triển khai/kiểm tra dưới đây được giữ theo thời điểm ghi nhận. Xem [trạng thái và evidence mới nhất](testing.md). Không suy luận test đã đạt chỉ từ hướng dẫn cấu hình.

# Giai đoạn 6 — Pipeline E2E và DQ gate

Điều kiện trước lần chạy E2E đầu: giai đoạn 5 đã tạo và chạy thành công
`dbo.usp_build_gold`, 9 copy staging thành công, validation PASS.
Hướng dẫn này không xác nhận thay kết quả chạy thực tế trên Fabric.

## 1. Hoàn thiện notebook

Trong notebook Silver đã xác minh trên Fabric, thêm nội dung
`../fabric/notebooks/phase6_pipeline_exit_cell.py` thành cell code CUỐI CÙNG.
Cell đọc lại 10 bảng, đối chiếu số dòng với biến `counts` đã tính trước ghi,
rồi gọi `notebookutils.notebook.exit(RUN_ID)` để trả mã lần chạy.
Không đặt exit trước bước ghi bảng hoặc trong try/except.
Lưu notebook. Bản cục bộ reviewed không bị tự thay đổi bởi hướng dẫn này.

## 2. Pipeline cha

Mở `PL_Olist_E2E` nếu đã có; nếu chưa, tạo Data pipeline cùng tên.
Tạo/cấu hình các activity sau, nối toàn bộ bằng On success:

```text
DF_Bronze
  → NB_Silver
  → LOAD_Staging
  → SP_Build_Gold
```

- DF_Bronze: Dataflow activity, chọn workspace và `DF_Olist_Bronze` đang dùng.
  Đích Bronze giữ chế độ replace/full refresh đã xác minh cho nguồn tĩnh.
- NB_Silver: Notebook activity, chọn đúng notebook đã bổ sung cell cuối.
  Chọn connection có quyền chạy notebook; kiểm tra notebook vẫn gắn đúng Lakehouse.
- LOAD_Staging: Invoke pipeline activity, chọn `PL_Olist_Load_Staging`.
  Phải đợi pipeline con chạy xong. Nếu dùng Invoke pipeline (Legacy) cùng workspace,
  bật Wait on completion. Xác nhận trong run history rằng cả 9 copy kết thúc trước Gold.
- SP_Build_Gold: Stored procedure activity, connection `WH_Olist_Gold`,
  chọn `dbo.usp_build_gold`, Import parameters.

Trong giá trị tham số `silver_run_id` (String), Add dynamic content:

```text
@activity('NB_Silver').output.result.exitValue
```

`NB_Silver` phải trùng tên activity. Sau lần chạy, xem Output để xác nhận
`result.exitValue` chứa chuỗi UUID. Nếu cấu trúc Output thực tế khác, dùng đúng
đường dẫn từ Output; không đoán run_id hoặc gán một mã từ lần chạy cũ.

Trong phiên bản này, DQ run_id do notebook tạo riêng cho mỗi lần thực thi.
Pipeline RunId là mã khác; không truyền `@pipeline().RunId` vào procedure hiện tại.

## 3. DQ gate và lỗi

Notebook đã gọi gate() trước khi ghi Silver: ERROR làm notebook fail, WARN giữ lại
để xem xét. Nếu ghi Silver lỗi, activity cũng fail và cell exit không được chạy.
Chuỗi On success ngăn gọi staging/Gold khi bước trước fail.

Pipeline con phải có 9 copy nối On success, không có nhánh xử lý lỗi biến thất bại
thành thành công. Procedure kiểm tra DQ đúng run_id, staging và Gold trước commit.
Không dùng On completion cho chuỗi nạp dữ liệu này.

Lần cấu hình đầu đặt Retry = 0 để nhìn rõ lỗi. Nếu gặp lỗi tạm thời do SQL endpoint
chưa đồng bộ hoặc transaction conflict, xác minh nguyên nhân rồi có thể đặt retry
giới hạn cho SP_Build_Gold, ví dụ 2 lần, cách 60 giây. Không dùng retry để bỏ qua DQ.
Audit Gold chỉ ghi thành công; lịch sử pipeline/activity là bằng chứng cho lần thất bại.

Không chạy đồng thời notebook thủ công, pipeline con và pipeline cha.
Chưa bật lịch tự động trong khi kiểm thử. Thiết kế này chưa có distributed lock;
điều kiện một lượt nạp tại một thời điểm là bắt buộc để giữ dữ liệu các lớp nhất quán.

## 4. Chạy thật và đối soát

Save → Run pipeline cha. Theo dõi Output và run history.
Mở pipeline con để kiểm tra cả 9 copy.
Ghi lại Pipeline RunId và Silver run_id từ notebook output, rồi chạy ở Warehouse:

```sql
SELECT TOP (10) *
FROM dbo.GoldLoadAudit
ORDER BY completed_at DESC;

SELECT * FROM dbo.vw_StageValidation WHERE failed_rows > 0;
SELECT * FROM dbo.vw_GoldValidation WHERE failed_rows > 0;
```

Audit mới phải chứa đúng Silver run_id vừa nhận. Hai truy vấn lỗi phải rỗng.
Chạy tiếp `../fabric/sql/05_validate_and_reconcile.sql` để lưu tổng tiền và số dòng.

Chạy lại toàn bộ pipeline khi lần trước đã kết thúc, nguồn không đổi.
Kỳ vọng số dòng/tổng tiền không đổi; notebook có RUN_ID mới và audit Gold thêm dòng mới.

## 5. Kiểm thử DQ gate có chủ đích

Tạo bản sao notebook và pipeline cha dành cho kiểm thử, tắt mọi lịch tự động.
Trong notebook TEST, ngay trước lệnh `gate()` cuối cùng của cell validation
(và trước cell ghi Silver), thêm:

```python
check("TEST.forced_failure", 1, 1, "ERROR")
```

Pipeline TEST trỏ NB_Silver vào notebook TEST; giữ các liên kết On success.
Chạy khi không có lượt nạp khác đang hoạt động.
Kỳ vọng: notebook FAIL, dq_results có TEST.forced_failure, LOAD_Staging và
SP_Build_Gold không chạy, không xuất hiện audit Gold thành công mới.

Bài test dùng cùng nguồn sẽ tạo một DQ run thất bại mới trong audit thật;
không sửa/xóa dữ liệu Bronze để tạo lỗi. Sau test, chạy pipeline bình thường
với notebook không có rule ép lỗi để tạo lại run thành công mới nhất.
Không gọi Gold bằng run_id cũ sau bài test: procedure chủ động chặn mã cũ.

## 6. Kết thúc giai đoạn

- Một lần E2E thành công, có đủ bằng chứng từng activity.
- Lần chạy lại không tăng số dòng/tổng tiền khi nguồn không đổi.
- Test DQ thất bại chặn downstream như mong đợi.
- Khôi phục bằng một lượt E2E bình thường thành công sau test.
- Lưu mapping Pipeline RunId → Silver run_id → GoldLoadAudit và kết quả đối soát.

Sau đó chuyển sang giai đoạn 7: semantic model và DAX.

## Tài liệu Microsoft

- https://learn.microsoft.com/en-us/fabric/data-factory/dataflow-activity
- https://learn.microsoft.com/en-us/fabric/data-factory/notebook-activity
- https://learn.microsoft.com/en-us/fabric/data-engineering/notebookutils/notebookutils-notebook-run
- https://learn.microsoft.com/en-us/fabric/data-factory/invoke-pipeline-activity
- https://learn.microsoft.com/en-us/fabric/data-factory/stored-procedure-activity

Chưa có định nghĩa pipeline xuất từ Fabric trong workspace cục bộ, nên hướng dẫn
này cung cấp cấu hình UI; không tuyên bố đã triển khai pipeline trên Fabric.

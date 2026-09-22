# Fabric exports — imported 21/09/2026

Đã nhận bản export người dùng tải từ Fabric; nguồn gốc và SHA-256 ghi trong [inventory](fabric-export-inventory.json). Không chạy hoặc sửa các artifact trên tenant trong bước nhập này.

## Nội dung đã nhập

| Artifact | Vị trí | Kết quả kiểm tra |
|---|---|---|
| DF_Olist_Bronze | `fabric/dataflows/DF_Olist_Bronze/` và `fabric/dataflows/templates/` | 9 query nguồn và 9 query DataDestination |
| PL_Olist_E2E | `fabric/pipelines/PL_Olist_E2E/` | 4 activity; chuỗi On success; chờ staging; truyền notebook exitValue |
| PL_Olist_Load_Staging | `fabric/pipelines/PL_Olist_Load_Staging/` | 9 Copy, không dependencies giữa các Copy (có thể chạy song song) |
| PL_Olist_Gold_To_SQLServer | `fabric/pipelines/PL_Olist_Gold_To_SQLServer/` | 7 Copy |
| PL_Olist_E2E_TEST_DQ | `fabric/pipelines/PL_Olist_E2E_TEST_DQ/` | 4 activity; trỏ notebook TEST riêng |
| NB_Olist_Silver_reviewed | `fabric/notebooks/NB_Olist_Silver_reviewed.ipynb` | Đã bổ sung cell kiểm tra persisted counts và notebook exit RUN_ID |
| NB_Olist_Silver_TEST_DQ | `fabric/notebooks/NB_Olist_Silver_TEST_DQ.ipynb` | Có TEST.forced_failure trước gate và trước ghi Silver |

## Cách import lại

1. Chuẩn bị Lakehouse/Warehouse và connection tại môi trường đích theo runbook.
2. Dùng template `.pqt` để tạo Dataflow. Kiểm tra nguồn OneLake/SharePoint và destination; chọn lại connections, credentials, workspace/item IDs theo môi trường mới.
3. Import notebook chính và TEST, gắn đúng default Lakehouse. Bản mã nguồn đã bỏ output/execution_count để không hiển thị kết quả cũ như kết quả chạy mới.
4. Import pipeline từ các ZIP trong `fabric/pipelines/templates/`. E2E và E2E_TEST_DQ đều chứa resource PL_Olist_Load_Staging bên trong, nên không mặc định import cả ba template mà không kiểm tra trùng resource. Chọn một cách tạo staging, rồi kiểm tra pipelineId mà activity InvokePipeline tham chiếu.
5. Chọn lại connections từ template parameters; kiểm tra notebookId, workspaceId, pipelineId và Warehouse endpoint còn gắn với môi trường cũ. Template không tự tạo mọi prerequisite hoặc credentials.
6. Đối chiếu schema/procedure từ SQL cục bộ với tenant; các file export lần này chưa bao gồm định nghĩa Warehouse và semantic model Direct Lake.
7. Chạy normal E2E, đối soát; chỉ chạy TEST ở thời điểm không có lượt nạp khác. Lưu run history riêng làm bằng chứng.

## Khác biệt với hướng dẫn cũ

Hướng dẫn giai đoạn 5/6 mô tả 9 Copy staging nối On success. Export thực tế có 9 activity độc lập. Pipeline cha vẫn `waitOnCompletion=true`, nên phải chờ toàn bộ pipeline con; không sửa export chỉ để khớp hướng dẫn cũ. Khi tái lập, giữ Silver cố định trong toàn bộ batch và không chạy Gold nếu pipeline con fail.

Một số chuỗi trong template có dấu `[[` (ví dụ tên procedure): đây là bản template xuất nguyên gốc; không tự sửa biểu thức template thành cấu hình runtime. Kiểm tra giá trị sau import trước khi chạy.

## Bằng chứng notebook và giới hạn

Notebook chính lưu output persisted counts và exitValue `11a8db49-790a-5e68-bd60-b93905b09807` từ 17/09. Notebook TEST giữ cùng output và execution counts với notebook chính, dù source có rule ép lỗi. Vì vậy không dùng output TEST này để kết luận test đã thực thi hoặc downstream đã bị chặn. Hai file gốc ở workspace/zip được giữ nguyên, SHA-256 trong inventory.

Bản export là bằng chứng cấu hình, không thay cho run history. Còn thiếu metadata Direct Lake, đối chiếu SQL đang triển khai và evidence E2E/rerun/recovery như ghi trong testing.md.

> Ghi chú cập nhật 21/09/2026: nội dung triển khai/kiểm tra dưới đây được giữ theo thời điểm ghi nhận. Xem [trạng thái và evidence mới nhất](testing.md). Không suy luận test đã đạt chỉ từ hướng dẫn cấu hình.

# Kiểm tra giai đoạn 5 bằng MCP — 2026-09-15

## Kết luận

Chưa đủ điều kiện kết thúc giai đoạn 5. Đã tạo cấu trúc Warehouse; dữ liệu
staging/Gold được OneLake MCP cung cấp hiện vẫn rỗng. Chưa chuyển sang giai đoạn 6.

## Phạm vi thực tế

- Workspace: WS_Olist_Demo, 23f4a256-949e-5f7d-8c35-b63242139c25.
- Warehouse: WH_Olist_Gold, 16e8686d-40c4-5372-bde4-0b5af8d807f8.
- Đọc bằng Fabric MCP: catalog, danh sách pipeline, bảng, schema, thư mục dữ liệu,
  và nội dung Delta log của từng bảng. Không chạy pipeline hoặc thay đổi dữ liệu Fabric.

## Kết quả

| Hạng mục | Kết quả |
|---|---|
| Warehouse | Có |
| 9 bảng staging | Có đủ |
| 4 dimension + 3 fact | Có đủ |
| GoldLoadAudit | Có |
| Dữ liệu của cả 17 bảng | Không có file dữ liệu/add action ở phiên bản Delta đang hiển thị |
| Pipeline PL_Olist_Load_Staging | Không có trong danh sách pipeline MCP trả về |
| Pipeline PL_Olist_E2E | Có; công cụ get_pipeline chỉ trả thuộc tính, không trả activities/run history |
| Procedure usp_build_gold | Chưa xác minh trực tiếp trong SQL |
| Hai view validation | Chưa xác minh trực tiếp trong SQL |
| Đối soát và kiểm tra chạy lại | Chưa đạt điều kiện kiểm tra vì bảng chưa có dữ liệu |

Từng bảng chỉ có `_delta_log/00000000000000000000.json`.
Đã tải và đọc log của cả 17 bảng: chỉ có txn, protocol, metaData; không có add action.
Metadata của cả 17 bảng trả current-snapshot-id = -1 và snapshots rỗng.
Các log staging có thời điểm 2026-09-14 22:13:04 +07:00;
Gold/audit có thời điểm 2026-09-14 22:16:04 +07:00.
Đây là bằng chứng từ lớp lưu trữ OneLake hiện thấy, không phải kết quả SELECT COUNT trên SQL endpoint.

## Giới hạn

Fabric MCP trong phiên này không có công cụ thực thi T-SQL.
Đã mở Warehouse bằng Playwright MCP nhưng browser dừng ở màn hình đăng nhập Fabric.
Vì vậy chưa kiểm tra được định nghĩa procedure/view hoặc kết quả truy vấn SQL.
Không suy luận việc các object SQL này đã tồn tại từ những file SQL cục bộ.

## Việc cần tiếp tục ở giai đoạn 5

1. Xác nhận/tạo hai validation view và procedure bằng bản SQL đã sửa [rule].
2. Cấu hình và chạy 9 Copy Activity Silver → staging theo hướng dẫn giai đoạn 5.
   Nếu các copy đặt trong PL_Olist_E2E thay vì pipeline riêng, kiểm tra trực tiếp cấu hình đó.
3. Chỉ build Gold sau khi staging validation PASS.
4. Đối soát Gold, kiểm tra GoldLoadAudit và thử chạy lại trên nguồn không đổi.

Bằng chứng chi tiết: phase-5-mcp-evidence-2026-09-15.json.

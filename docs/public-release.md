# Bản công khai đã ẩn thông tin môi trường

Bản public giữ logic xử lý, DAX, cấu trúc pipeline và các số liệu kiểm thử. Email, tên tài khoản/máy, tên workspace, hostname Warehouse và GUID được thay bằng giá trị mẫu. Các GUID trong file này là ID tổng hợp, không dùng để truy cập tenant gốc.

- UPN mẫu: `analyst@example.com`; workspace mẫu: `WS_Olist_Demo`.
- SQL server mẫu: `SQLSERVER-DEMO\SQLEXPRESS`; gateway mẫu: `GW_Olist_Demo`.
- Các ZIP/PQT là bản template đã xử lý thông tin, không còn byte-identical với export gốc.
- Cần chọn lại connection, notebook/pipeline/workspace IDs, OneLake/Warehouse endpoint và RLS identity của bạn trước khi triển khai. Không chạy provisioning hoặc publish bằng thông số mẫu.
- Kết quả DAX/KPI và thời gian chạy được giữ; GUID trong bằng chứng đã thay nên không thể dùng để mở run gốc.
- Ảnh Fabric có account chrome và metadata nhận diện không được phát hành. Các ảnh báo cáo Desktop SQL được giữ sau kiểm tra trực quan, không được trình bày như ảnh refresh/gateway trên Service.
- Notebook outputs đã bỏ; không coi source TEST là bằng chứng DQ gate đã chạy.
- Bản public chưa được deploy/test lại trên một tenant sạch. Thay thế ID giữ quan hệ tham chiếu nội bộ nhưng không tự tạo kết nối/credentials.

Mã nguồn gốc, ảnh bằng chứng đầy đủ và commit cũ được chủ đồ án giữ riêng, không nằm trong lịch sử public. Xem `release-manifest.json` cho SHA-256 của các file công khai sau xử lý.

# Kiểm tra và triển khai bản sửa

## Kết luận từ file gốc

- Notebook gắn mặc định đúng LH_Olist_Silver (c7b6840e-9fc1-5463-87ba-f7250ccff244). Không có bằng chứng nó đang ghi vào Lakehouse trùng tên NB_Olist_Silver.
- Cell cuối lưu lỗi NameError: orders is not defined. Cần chạy tuần tự từ đầu trong cùng phiên; dữ liệu đã lưu không tạo lại các biến Python sau khi phiên kết thúc.
- Code gốc có đúng một lệnh ghi slv_orders mỗi lần chạy cell ghi. Chưa giải thích được lịch sử 3093 phiên bản; cần lịch sử chạy notebook/pipeline để tìm nguyên nhân. Không xóa Delta log.
- Code xuất hiện tại thời điểm gửi đã trả null is_late khi thiếu ngày giao. Kết quả bảng quan sát trước đó không có null: code và dữ liệu đã lưu chưa đồng nhất.
- M người dùng gửi đã có cả _batch_id và _source_file. Không kết luận code M thiếu cột. Bảng Bronze quan sát trước đó thiếu cột: cần kiểm tra query được publish, đích và mapping, rồi refresh.

## Thực hiện theo thứ tự

1. Trong DF_Olist_Bronze, kiểm tra query reviews đang dùng đúng mã đã gửi. File fabric/dataflows/brz_reviews.pq là bản sạch định dạng, khai báo kiểu metadata và giữ một ingest timestamp UTC ổn định cho lần đánh giá query. BatchId hiện là batch nguồn cố định, không phải run ID; đổi theo batch nguồn khi nạp dữ liệu mới.
2. Trong cấu hình Data destination của query reviews, xác nhận LH_Olist_Bronze / dbo.brz_reviews. Preview phải có 11 cột: 7 nguồn + 4 metadata. Kiểm tra mapping có _batch_id, _source_file, _source_system, _ingest_ts. Nếu mapping/schema cố định chưa có cột mới, cập nhật qua giao diện. Giữ chế độ replace/full refresh phù hợp nguồn tĩnh; không append lại cùng bộ dữ liệu.
3. Publish và refresh Dataflow. Kiểm tra bảng đích vẫn có 99.224 dòng và đủ 11 cột. Nếu preview đủ cột nhưng đích thiếu, gửi cấu hình destination/mapping và kết quả refresh; không cần xóa bảng để thử.
4. Import fabric/notebooks/NB_Olist_Silver_reviewed.ipynb thành notebook mới để giữ bản cũ. Xác nhận mặc định LH_Olist_Silver. Chạy Run All một lần từ phiên mới sau khi Bronze đạt kiểm tra. Chạy notebook này sẽ cập nhật 10 bảng Silver và ghi audit dq_results.
5. Nếu ERROR, xem dq_results theo run_id; sửa nguyên nhân trước khi chạy lại. WARN giữ các bất thường như ngày giao trước ngày mua hoặc không tìm được tọa độ để đánh giá nghiệp vụ, chưa phải chứng nhận dữ liệu sạch hoàn toàn.
6. Sau khi chạy thành công, đối chiếu số dòng và schema. Chỉ cập nhật activity Notebook trong PL_Olist_E2E sang bản đã xác minh. Chưa có định nghĩa pipeline để sửa liên kết trực tiếp.

## Thay đổi notebook

- ZIP chuẩn string 5 ký tự; timestamp giao hàng và các cột số sản phẩm được chuyển kiểu; chuỗi rỗng thành null trước khi cast.
- is_late so sánh ngày lịch, cùng quy tắc với delay_days: giao trong đúng ngày hẹn không bị coi trễ do giờ hẹn 00:00. Thiếu actual hoặc estimated => null. Khi xây KPI phải giới hạn mẫu số theo trạng thái/khả năng quan sát.
- Customer/review có tiêu chí phụ ổn định khi trùng timestamp; nhãn địa lý chọn cặp city/state phổ biến nhất và tie-break ổn định. Centroid vẫn dùng trung bình nguồn; chưa loại ngoại lệ địa lý.
- Kiểm tra metadata và khóa trước dedup, kiểm tra orphan, row reconciliation, grain, tiền, review score, chuyển kiểu và coverage lịch trước ghi Silver.
- Không bịa metadata thiếu bằng cách thêm vào Silver. Bronze phải được sửa trước.
- Ghi rõ đích LH_Olist_Silver.dbo; mỗi bảng một lệnh ghi mỗi lần chạy cell. Các bảng không có transaction chung: nếu ghi giữa chừng thất bại, không chạy Gold và phải chạy lại notebook sau khi sửa lỗi.
- Cell cuối đọc bảng đã lưu, không phụ thuộc biến orders.

## Giới hạn xác minh

Đã parse cú pháp Python toàn bộ cell và kiểm tra cấu trúc notebook bằng công cụ cục bộ. Máy không có PySpark/Java để chạy Spark; chưa import/chạy bản sửa trên Fabric. M chưa được đánh giá bởi Power Query. DQ không bao quát mọi rủi ro: lỗi cast có thể dừng Spark trước khi audit cuối được ghi. Kiểm tra trùng khóa nguồn dừng xử lý thay vì tự chọn một dòng xung đột. Chưa xác nhận nguồn CSV nguyên bản bằng checksum Kaggle.

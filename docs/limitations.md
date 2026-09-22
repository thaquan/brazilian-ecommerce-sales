# Giới hạn và công việc tiếp theo

1. Lịch refresh SQL model đang Off; mới kiểm chứng refresh On demand.
2. Copy SQL truncate/insert từng bảng; chưa staging + promote cả batch. Khóa ROW_NUMBER có thể đổi khi nguồn đổi; không nạp fact/dimension rời rạc hoặc refresh giữa batch.
3. Role Fabric là pilot một UPN → SP, chưa triển khai SecurityUserState. XMLA tests đã lưu; web test bị bỏ qua vì SSO, actual Viewer và danh tính thứ hai chưa xác minh. SQL model riêng chưa có RLS.
4. Chưa lưu đủ bằng chứng E2E normal/rerun/DQ forced-failure/recovery trong bộ đóng gói này. Không suy luận PASS từ sự tồn tại của pipeline TEST hoặc từ dữ liệu cuối có sẵn.
5. Đã có Dataflow/Pipeline/notebook exports; semantic model Fabric Direct Lake chưa được export. Template còn tham chiếu môi trường cũ và cần chọn lại connection/IDs; chưa kiểm chứng import trên môi trường sạch.
6. DimCustomer dùng vị trí hiện tại; không hỗ trợ lịch sử địa chỉ theo thời gian. Repeat customer tính trong filter context hiện tại, không phải cohort lifetime.
7. SQL report bỏ Data Health vì audit chưa được nạp. Fabric audit chỉ ghi load thành công, không thay thế run history/DQ chi tiết.
8. PBIR validator của bản SQL đã báo 0 errors nhưng 1 warning không tải được schema Microsoft visualContainer 2.12.0. Đã kiểm tra render; không tuyên bố full schema validation cho phần schema chưa tải được.
9. Bộ dữ liệu tĩnh dùng cho học tập; chưa đánh giá CDC, incremental load, tải lớn, SLA hoặc production concurrency.

Ưu tiên tiếp theo: bổ sung metadata Direct Lake/evidence còn thiếu → staging batch SQL và phụ thuộc refresh → RLS SQL và kiểm tra Viewer → lịch tự động → incremental/CDC nếu phạm vi dự án mở rộng.

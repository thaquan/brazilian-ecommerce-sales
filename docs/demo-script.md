# Kịch bản demo 8–10 phút

## Chuẩn bị

Mở README, báo cáo đã publish và bộ ảnh evidence. Không chạy lại toàn bộ pipeline giữa buổi demo nếu không cần. Kiểm tra mạng và gateway nếu muốn trình diễn refresh thật; có thể dùng run history đã lưu.

| Thời gian | Thao tác | Điểm cần giải thích |
|---|---|---|
| 0:00–1:00 | Giới thiệu bài toán | Đơn hàng, người bán, khách hàng, giao hàng, thanh toán |
| 1:00–2:30 | Sơ đồ kiến trúc | Bronze/Silver/Gold, DQ gate, hai nhánh phục vụ |
| 2:30–4:00 | Model và dictionary | Ba grain fact; tránh nối fact-fact và đếm lặp |
| 4:00–6:00 | Overview rồi Sales/Customers/Delivery/Payments | KPI, sidebar/Home, ngày mua và customer state; seller chỉ ảnh hưởng item |
| 6:00–7:00 | RLS evidence | SP pilot kiểm tra XMLA; nói rõ web SSO/Viewer chưa kiểm chứng |
| 7:00–8:30 | Pipeline và refresh evidence | 7 copy Succeeded, gateway mapping, refresh 27 giây |
| 8:30–10:00 | Giới hạn và hướng phát triển | Batch nguyên tử, lịch refresh, RLS SQL, evidence còn thiếu |

## Câu hỏi thường gặp

**Vì sao ba fact?** Order, order item và payment record có grain khác nhau. Gộp bằng join có thể nhân bản tiền và số đơn.

**Vì sao payment khác order value?** Chúng tổng hợp hai nguồn/grain khác nhau. Đồ án báo cáo riêng và đối soát riêng; không tự quy toàn bộ chênh lệch cho phí hoặc lỗi.

**Vì sao AOV không chia Total Orders?** Measure dùng số đơn có item làm mẫu số, phù hợp tử số từ item.

**Seller filter có giảm Total Orders không?** Không trong model này; seller chỉ liên quan FactOrderItem. Orders With Items dùng khi phân tích người bán.

**RLS đã hoàn tất chưa?** Fabric pilot có XMLA evidence; web/Viewer chưa hoàn tất. SQL model chưa có role.

**Chạy tự động chưa?** Nhánh SQL đã chứng minh manual E2E và refresh On demand; lịch đang Off.

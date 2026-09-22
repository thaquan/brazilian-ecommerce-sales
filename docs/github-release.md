# Chuẩn bị GitHub

## Ranh giới repository

Khi rà soát, `git rev-parse --show-toplevel` tại dự án trả về `D:/`. Không dùng `git add .` từ repository cha đó. Đóng gói chỉ các file của `microsoft-fabric-olist-e2e` theo manifest; tạo repository riêng trong một thư mục sạch ngoài Git repository cha, hoặc clone repository đích rồi copy các file được chọn vào đó.

Đợt đóng gói này không tạo remote, commit hoặc push. Chưa biết GitHub repository đích và lựa chọn public/private của chủ sở hữu.

## Nội dung giữ lại

README; docs và evidence; notebook; SQL; Power Query; PBIP/PBIR/TMDL; script tạo report. Xem `release-manifest.json` để biết danh sách và SHA-256 của từng file. `.gitignore` loại raw data, PBIX/ZIP thông thường, cache `.pbi`, dependencies và backup; cho phép riêng ZIP template dưới fabric/pipelines/templates/. Ignore không loại file đã từng được commit trong repository khác.

## Trước khi công khai

- Review thông tin nhận diện trong screenshots/RLS: UPN, tên chủ tài khoản, máy, workspace/item IDs. Đây là thông tin cấu hình/nhận diện, không phải password; evidence gốc được giữ nguyên, chưa tạo bộ ảnh ẩn danh cho public.
- Kiểm tra credentials/token/recovery key, notebook outputs và file connection. Dùng secret scanner độc lập trước public; kiểm tra mẫu chuỗi cục bộ không chứng minh tuyệt đối không có bí mật.
- Dữ liệu gốc và PBIX không nằm trong bundle Git. Chỉ phân phối riêng khi đã xác nhận quyền sử dụng và phạm vi dữ liệu.
- Đã bổ sung export Dataflow/Pipeline. Cần remap connection/IDs theo export review và bổ sung metadata Direct Lake trước khi tái lập đầy đủ.
- Chọn LICENSE cho mã riêng; giữ attribution dữ liệu và template.

## Đưa lên repository riêng

Tạo repository đích, clone vào thư mục sạch; copy đúng các file trong manifest, bao gồm `.gitignore`. Trong thư mục clone:

```powershell
git status --short
git add README.md .gitignore docs fabric sql powerbi
git diff --cached --stat
git diff --cached --check
```

Review staged files, sau đó mới commit và push vào remote đã chọn. Thư mục trống không được Git lưu. Không chạy các lệnh staging ở `D:/`.

## Checklist phát hành

- [ ] Chọn repository đích và public/private.
- [ ] Rà soát thông tin cá nhân và secret scan độc lập.
- [ ] Quyết định LICENSE và quyền phân phối dữ liệu.
- [ ] Review staged diff, notebook outputs và file lớn.
- [ ] Commit/push rồi mở README trên GitHub để kiểm tra ảnh, Mermaid và links.
- [ ] Chạy thử theo runbook trên môi trường sạch; ghi các bước thủ công còn cần.

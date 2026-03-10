# 🐾 Happy Pet Shop - Game Chăm Sóc Thú Cưng

Chào mừng bạn đến với **Happy Pet Shop**! Đây là một tựa game quản lý thời gian vô cùng đáng yêu nhưng cũng không kém phần thử thách. Bạn sẽ vào vai một nhân viên chăm sóc, phục vụ thức ăn và đồ chơi cho những bé thú cưng đang thiếu kiên nhẫn!

## 🎮 Trải Nghiệm Game Ngay!
👉 **[BẤM VÀO ĐÂY ĐỂ CHƠI TRÊN WEB](https://nhahangthucungg.netlify.app/)**

*(Khuyên dùng máy tính hoặc mở toàn màn hình trình duyệt để có trải nghiệm kéo-thả tốt nhất)*

## ✨ Tính Năng Nổi Bật

* **Hệ thống Tài khoản:** Đăng nhập và Đăng ký an toàn với Firebase Authentication. Dữ liệu của bạn luôn được lưu lại!
* **Gameplay Kéo Thả Thử Thách:** * Kéo các vật dụng (🦴, 🐟, 🥕...) vào bàn chuẩn bị.
  * Canh thời gian chuẩn xác để đồ ăn/đồ chơi sẵn sàng (hiện chữ ✨ XONG!). Nếu để quá lâu, đồ sẽ bị hỏng (💥 HỎNG!).
  * Giao đúng món đồ cho các bé thú cưng (🐶, 🐱, 🐰...) trước khi thanh kiên nhẫn của chúng cạn kiệt.
* **Hệ thống Cửa Hàng (Shop):** Dùng số tiền 💰 kiếm được sau mỗi màn chơi để nâng cấp cửa tiệm:
  * 📦 **Thêm Bàn Chuẩn Bị:** Mở rộng không gian làm việc (Tối đa 4 bàn).
  * ⏳ **Tủ Lạnh Mini:** Giúp đồ ăn lâu bị hỏng hơn (Tối đa cấp 5).
  * ❤️ **Tăng Tim Tối Đa:** Tăng số lần được phép mắc lỗi/bỏ lỡ khách (Tối đa 6 tim).
* **Bảng Xếp Hạng Thời Gian Thực:** Vinh danh Top 10 người chăm thú xuất sắc nhất trên hệ thống Cloud Firestore.
* **Âm Thanh & Hiệu Ứng:** Tích hợp âm thanh chuông báo khách, tiếng thu tiền, tiếng báo lỗi và hiệu ứng rung (Haptic Feedback) sống động.

## 🛠️ Công Nghệ Sử Dụng

* **Frontend:** Flutter & Dart
* **Backend & Cơ Sở Dữ Liệu:** Firebase (Authentication & Cloud Firestore)
* **Quản lý Âm thanh:** Gói thư viện `audioplayers`

## 🚀 Hướng Dẫn Cài Đặt (Dành cho Developer)

Nếu bạn muốn tải source code này về để tham khảo hoặc phát triển thêm:

1. Clone repository này về máy:
   ```bash
   git clone [https://github.com/nhp1675/DACSCNTT-COOKING-GAME.git](https://github.com/nhp1675/DACSCNTT-COOKING-GAME.git)
Cài đặt các thư viện phụ thuộc:

Bash
flutter pub get
Chạy dự án:

Bash
flutter run

# 🐾 Nhà Hàng Thú Cưng (Happy Pet Shop) 🐾

Chào mừng bạn đến với **Nhà Hàng Thú Cưng** – một tựa game quản lý thời gian và nấu ăn vui nhộn được xây dựng bằng Flutter. Vào vai một đầu bếp tài ba, nhiệm vụ của bạn là phục vụ những vị khách thú cưng siêu đáng yêu nhưng cũng rất thiếu kiên nhẫn!

🎮 **[CHƠI GAME TRỰC TUYẾN TẠI ĐÂY](https://happypetrestaurant.netlify.app/)** 🎮

---

## 👨‍💻 Thông tin sinh viên

Dự án được phát triển bởi nhóm 3 thành viên:
- **Nguyễn Hồng Phong** - 23010873
- **Vũ Hồng Phúc** - 23010855
- **Cung Đỗ Hải Phong** - 23010341

---

## 🌟 Các tính năng chính

### 1. Dành cho Người chơi (Player)
- **Hệ thống Tài khoản**: Đăng nhập/Đăng ký bằng Email & Mật khẩu hoặc đăng nhập nhanh qua Google (Tích hợp Firebase Auth).
- **Chế độ chơi Đa dạng**:
  - 🗺️ *Cày Ải*: Vượt qua các cấp độ với điểm số và thời gian giới hạn.
  - ♾️ *Vô Tận*: Thử thách bản thân với số lượng khách hàng lớn và độ khó tăng dần theo thời gian.
- **Gameplay Cuốn hút**: 
  - Kéo thả nguyên liệu để nấu ăn, quản lý thời gian để không làm cháy món.
  - Phục vụ Khách VIP (👑) để nhận nhiều tiền hơn.
  - Tích lũy thanh COMBO (x2, x3, x4...) để bùng nổ doanh thu.
  - Sử dụng Thùng Rác (🗑️) để vứt đồ cháy và Bình Cứu Hỏa (🧯) để dập tắt bếp lửa.
- **Cửa Hàng Nâng Cấp (Shop)**: Dùng tiền kiếm được để mua thêm Bếp nấu, Tăng tốc độ nấu, Chảo chống dính, Mua thêm Tim (Mạng) và Mở khóa các nguyên liệu cao cấp.
- **Nhiệm vụ & Thành tựu**: Hệ thống phần thưởng phong phú kích thích người chơi cày cuốc.
- **Bảng Xếp Hạng (Leaderboard)**: So tài điểm số với các đầu bếp khác trên toàn server.
- **Tùy chỉnh Hồ sơ**: Đổi tên, thay đổi Avatar thú cưng và lựa chọn Nhạc nền (BGM) yêu thích.

### 2. Dành cho Quản trị viên (Admin Panel)
Tích hợp sẵn bảng điều khiển (Dashboard) dành riêng cho tài khoản được cấp quyền `admin` trên Firebase:
- 🍔 **Quản lý Thực đơn**: Thêm/Xóa các món ăn (Emoji) trực tiếp, mọi người chơi sẽ được cập nhật menu ngay lập tức.
- 🗺️ **Quản lý Màn chơi (Cày Ải)**: Thêm mới, chỉnh sửa (thời gian, điểm mục tiêu) hoặc xóa các màn chơi mà không cần phải cập nhật lại app.
- ♾️ **Quản lý Chế độ Vô tận**: Điều chỉnh số lượng khách hàng tối đa cho thử thách vô tận.
- 🔓 **Đặc quyền Admin**: Tự động mở khóa toàn bộ màn chơi để test game dễ dàng.

---

## 🛠️ Công nghệ sử dụng

- **Frontend Framework**: [Flutter](https://flutter.dev/) (Hỗ trợ Responsive xoay ngang/dọc, tối ưu cho cả Web và Mobile).
- **Backend/Database**: [Firebase](https://firebase.google.com/)
  - `Firebase Authentication`: Quản lý xác thực người dùng.
  - `Cloud Firestore`: Lưu trữ cơ sở dữ liệu thời gian thực (Thông tin người chơi, Nhiệm vụ, Shop, Leaderboard, Cấu hình Admin).
- **Thư viện bên thứ 3**:
  - `google_sign_in`: Đăng nhập bằng Google.
  - `audioplayers`: Xử lý âm thanh, nhạc nền và hiệu ứng (BGM, Kaching, Oh no, Bell...).

---

## 🚀 Cài đặt & Khởi chạy

**1. Clone repository về máy**:
```bash
git clone [link-repo-cua-ban]
cd [ten-thu-muc-repo]
```

**2. Cài đặt các gói thư viện phụ thuộc:**
Mở terminal tại thư mục dự án và chạy lệnh:
```bash
flutter pub get
```

**3. Chạy ứng dụng:**
*(💡 Khuyên dùng trên thiết bị thật, máy ảo hoặc trình duyệt Web để có trải nghiệm mượt mà nhất)*
```bash
flutter run
```

---

## 👑 Hướng dẫn Phân quyền Admin

Để có thể truy cập vào **Bảng điều khiển Admin** và quản lý game, bạn cần cấp quyền cho tài khoản của mình thông qua Firebase:

1. Tạo một tài khoản trực tiếp trong game.
2. Truy cập [Firebase Console](https://console.firebase.google.com/) và mở dự án **`cooking-game-cf5a9`**.
3. Ở menu bên trái, vào mục **Firestore Database** > Chọn collection **`users`**.
4. Tìm đến **UID** của tài khoản mà bạn vừa tạo.
5. Chọn **Thêm trường dữ liệu (Add field)** và điền chính xác các thông số sau:
   - **Field**: `role`
   - **Type**: `string`
   - **Value**: `admin`
6. **Khởi động lại game**. Nút **QUẢN LÝ (ADMIN)** màu đỏ quyền lực sẽ xuất hiện ngay tại Menu chính!

---

## 📂 Cấu trúc thư mục (Các file chính)

Dưới đây là danh sách các tệp tin quan trọng trong dự án để bạn dễ dàng theo dõi và tùy chỉnh mã nguồn:

- 📄 `main.dart` : Khởi tạo app, ép màn hình ngang (Landscape Immersive), cấu hình kết nối Firebase.
- 📄 `auth_screen.dart` : Giao diện và logic Đăng nhập / Đăng ký tài khoản.
- 📄 `main_menu.dart` : Giao diện sảnh chờ chính của game.
- 📄 `game_screen.dart` : Nơi chứa toàn bộ logic Gameplay cốt lõi (Đếm ngược thời gian, sinh khách hàng, quản lý bếp nấu, thao tác kéo thả, tính điểm...).
- 📄 `sub_screens.dart` : Các màn hình phụ trợ bao gồm: Chọn Level, Shop nâng cấp, Nhiệm vụ, Thành tựu, Cài đặt và Bảng xếp hạng.
- 📄 `admin_screen.dart` : Giao diện Bảng điều khiển dành riêng cho Admin quản lý game.
- 📄 `models.dart` : Các Class định nghĩa đối tượng dữ liệu trong game (`PetClient`, `PetItem`, `FloatingScore`).

---

> 🎉 **Cảm ơn bạn đã trải nghiệm Nhà Hàng Thú Cưng! Chúc bạn chơi game vui vẻ và có những giây phút thư giãn tuyệt vời!** 🐾❤️

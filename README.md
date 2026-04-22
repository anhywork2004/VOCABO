# 📖 VOCABO — Ứng dụng học tiếng Anh thông qua Flashcard

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.38.7-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10.7-0175C2?style=for-the-badge&logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=for-the-badge&logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**Ứng dụng học từ vựng tiếng Anh thông minh với Flashcard, AI Assistant và hệ thống ôn tập khoa học**

[📱 App Mobile](#-cài-đặt--chạy-app) · [🌐 Web App](#-web-app) · [✨ Tính năng](#-tính-năng) · [🛠 Công nghệ](#-công-nghệ-sử-dụng)

</div>

---

## 📸 Giao diện

| Trang chủ | Học Flashcard | Ôn tập | Kiểm tra |
|:---------:|:-------------:|:------:|:--------:|
| Dashboard với stats & biểu đồ | 8 chủ đề + custom topics | Flashcard theo chủ đề | Trắc nghiệm 4 đáp án |

---

## ✨ Tính năng

### 🔐 Xác thực
- Đăng ký / Đăng nhập bằng Email & Password
- Đăng nhập bằng Google Sign-In
- Quên mật khẩu qua email
- Thiết lập hồ sơ: tên, ảnh đại diện, cấp độ (A1–C2), mục tiêu hàng ngày

### 📚 Học từ vựng (Flashcard)
- **8 chủ đề có sẵn:** Animals, Food, Travel, Technology, Business, Health, Nature, Education
- Mỗi chủ đề 20 từ, tự động seed từ Dictionary API + dịch tiếng Việt qua MyMemory
- Tạo chủ đề tùy chỉnh với từ vựng riêng
- Flashcard lật 3D với hiệu ứng animation
- Phát âm từ vựng bằng Text-to-Speech
- Ảnh minh họa từ Unsplash API
- Đánh dấu **"Đã nhớ"** để lưu vào hệ thống ôn tập

### 🔁 Ôn tập (Review)
- Hiển thị danh sách chủ đề đã học theo dạng grid
- Flashcard ôn tập theo từng chủ đề
- Đánh giá "Đã nhớ!" / "Ôn thêm" sau mỗi thẻ
- Thống kê kết quả phiên ôn tập

### 📝 Kiểm tra (Test)
- **Tab "Từ của tôi":** câu hỏi từ từ vựng đã học
- **Tab "IELTS":** 200+ từ IELTS Academic Word List
- Trắc nghiệm 4 đáp án, 2 chế độ: Từ→Nghĩa và Nghĩa→Từ
- Hiệu ứng rung khi chọn sai
- Xem lại câu sai sau khi hoàn thành
- Lưu điểm số lên Firestore

### 📖 Ngữ pháp (Grammar)
- 26 bài học chia 3 nhóm: 12 thì, 4 câu điều kiện, 10 chủ điểm khác
- Cấu trúc, cách dùng, ví dụ minh họa
- Đánh dấu bài đã học

### 😺 Meow AI
- Chatbot AI tích hợp **Groq API** (model llama-3.3-70b-versatile)
- Hỗ trợ lập kế hoạch học tập, gợi ý từ vựng
- Tự động nhận diện yêu cầu thêm sự kiện vào lịch
- Lưu lịch sử hội thoại

### 📅 Lịch học tập (Calendar)
- Xem lịch theo tháng với `table_calendar`
- Thêm, xem, xóa sự kiện học tập
- Đánh dấu hoàn thành sự kiện
- Sự kiện từ Meow AI tự động thêm vào lịch

### 🔍 Tra từ (Search)
- Tra từ tiếng Anh → tiếng Việt
- Tra từ tiếng Việt → tiếng Anh (tự động dịch)
- Hiển thị phiên âm, định nghĩa, ví dụ, synonyms, antonyms
- Nguồn: Free Dictionary API (Oxford-based) + MyMemory

### 📊 Trang chủ (Dashboard)
- Thống kê: số từ đã học, streak, tiến độ, điểm test
- Biểu đồ học tập theo tuần (fl_chart)
- Lộ trình học theo cấp độ A1–C2
- Thông báo mới nhất từ Admin

### ⚙️ Cài đặt
- Chế độ sáng/tối (Light/Dark Mode) đồng bộ Firestore
- Quản lý thông báo
- Hồ sơ cá nhân

### 🛡️ Admin Panel
- Slide menu bên trái
- Dashboard: thống kê người dùng, chủ đề, từ vựng
- Quản lý người dùng: xem, khóa/mở khóa, xóa tài khoản
- Quản lý chủ đề & từ vựng
- Gửi thông báo đến tất cả hoặc theo cấp độ

---

## 🛠 Công nghệ sử dụng

| Công nghệ | Mục đích |
|-----------|----------|
| **Flutter 3.38.7** | Framework đa nền tảng (Android, iOS, Web) |
| **Dart 3.10.7** | Ngôn ngữ lập trình |
| **Firebase Auth** | Xác thực người dùng |
| **Cloud Firestore** | Cơ sở dữ liệu realtime |
| **Firebase Storage** | Lưu trữ ảnh đại diện |
| **Google Sign-In** | Đăng nhập bằng Google |
| **Groq API** | AI Assistant (llama-3.3-70b-versatile) |
| **Free Dictionary API** | Tra từ điển Oxford |
| **MyMemory API** | Dịch tiếng Việt |
| **Unsplash API** | Ảnh minh họa từ vựng |
| **Provider** | Quản lý state (ThemeProvider) |
| **table_calendar** | Lịch học tập |
| **fl_chart** | Biểu đồ học tập tuần |
| **flutter_tts** | Text-to-Speech phát âm |

---

## 🗂 Cấu trúc Firestore

```
users/{uid}
  ├── displayName, email, photoURL
  ├── level (A1–C2), dailyGoal
  ├── wordsLearned, streak, progress
  ├── lastTestScore, totalTests
  └── learned_words/{topicId_wordId}
      └── word, meaning, phonetic, topicId, topicName...

topics/{topicId}
  ├── uid, name, nameVi, emoji, color
  ├── wordCount, isPreset
  └── words/{wordId}
      └── word, meaning, phonetic, example, exampleVi

events/{eventId}
  └── uid, title, date, time, completed, source

study_sessions/{uid_date}
  └── uid, date, wordsLearned

notifications/{id}
  └── title, body, target, type, createdAt

ielts_questions/{id}
  └── word, meaning, phonetic, example
```

---

## 📱 Cài đặt & Chạy app

### Yêu cầu
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Firebase project đã cấu hình

### Các bước

```bash
# 1. Clone repo
git clone https://github.com/TenCuaBan/vocabo-app.git
cd vocabo-app

# 2. Cài dependencies
flutter pub get

# 3. Chạy app
flutter run
```

### Cấu hình API Keys

Tạo file `.env` ở thư mục gốc:

```env
GROQ_API_KEY=gsk_your_groq_key_here
UNSPLASH_ACCESS_KEY=your_unsplash_key_here
```

Lấy Groq API key miễn phí tại: [console.groq.com](https://console.groq.com)

---

## 🌐 Web App

Web app được xây dựng bằng HTML/CSS/JS thuần, dùng chung Firebase với app mobile.

### Các trang

| File | Chức năng |
|------|-----------|
| `web/index.html` | Đăng nhập / Đăng ký |
| `web/dashboard.html` | Trang chủ |
| `web/flashcard.html` | Học từ vựng |
| `web/review.html` | Ôn tập |
| `web/test.html` | Kiểm tra trắc nghiệm |
| `web/calendar.html` | Lịch học tập |
| `web/search.html` | Tra từ điển |
| `web/grammar.html` | Ngữ pháp |
| `web/profile.html` | Hồ sơ cá nhân |

### Chạy web locally

```bash
# Dùng Live Server (VS Code extension) hoặc:
python -m http.server 8000
# Truy cập: http://localhost:8000/web/index.html
```

> **Lưu ý:** Web app dùng ES Modules nên cần chạy qua HTTP server, không mở trực tiếp file HTML.

---

## 👥 Nhóm thực hiện

| Thành viên          | MSSV | Lớp |
|---------------------|------|-----|
| Phạm Nguyễn Anh Huy | 2224802010738 | D22CNTT02 |
| Dương Hoàng Phúc    | 2224802010608 | D22CNTT02 |


**Giảng viên hướng dẫn:** TS. Huỳnh Nguyễn Thành Luân

**Trường:** Đại học Thủ Dầu Một — Viện Công nghệ Số

---

## 📄 License

MIT License © 2026 VOCABO Team

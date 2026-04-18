# Firebase Storage Readiness Check

## Mục tiêu
Kiểm tra các điều kiện để có thể lưu trữ **toàn bộ dự án** lên Firebase Realtime Database.

---

## 1) Dữ liệu nào của app cần được lưu?

### Đã có trong project
- **Auth / Session**
  - `AppUser`
  - `AuthSession`
- **Learning**
  - `Course`
  - `Lesson`
- **Quiz**
  - `Quiz`
  - `QuizQuestion`
  - `QuizAttemptResult`
  - `QuizReviewItem`
- **Admin**
  - quản lý user, course, lesson, role
- **Trang tĩnh / UI**
  - `contact_page`
  - `policy_page`

### Dữ liệu có thể lưu vào Firebase
- User / profile / session
- Course / lesson
- Quiz / review / attempt
- Role / admin actions
- Contact form submissions
- Analytics / progress / history

---

## 2) Điều kiện cần có để lưu toàn bộ dự án

### A. Firebase project phải đúng và đầy đủ
- [x] Có project Firebase: `news-app-6ef88`
- [x] Có Realtime Database URL
- [ ] Có `google-services.json` trong `android/app/`
- [ ] Có `GoogleService-Info.plist` nếu chạy iOS
- [x] Firebase đã được khởi tạo trong `lib/main.dart`
- [x] Firebase packages đã thêm vào `pubspec.yaml`

### B. Dữ liệu phải có cấu trúc lưu trữ rõ ràng
Cần tách theo node:
- `/users/{uid}`
- `/profiles/{uid}`
- `/sessions/{uid}`
- `/courses/{courseId}`
- `/lessons/{lessonId}`
- `/quizzes/{quizId}`
- `/attempts/{attemptId}`
- `/roles/{uid}` hoặc nằm trong `/users`
- `/contacts/{messageId}` nếu muốn lưu form liên hệ

### C. Rules phải đủ chặt
- Chỉ user đã đăng nhập mới được đọc/ghi phần được phép
- `student` chỉ sửa dữ liệu của chính họ
- `mentor` được đọc dữ liệu học tập theo phạm vi cho phép
- `admin` mới được đổi role và quản lý toàn hệ thống

### D. App phải chuyển sang Firebase làm nguồn dữ liệu chính
Hiện trạng project:
- `auth_repository.dart` → đã ghi Firebase
- `learning_repository.dart` → vẫn gọi HTTP API
- `quiz_repository.dart` → vẫn gọi HTTP API
- `admin_repository.dart` → vẫn gọi HTTP API

=> Nghĩa là hiện tại **chưa phải toàn bộ dự án** đã lưu trên Firebase.

---

## 3) Trạng thái hiện tại của từng phần

| Phần | Trạng thái | Ghi chú |
|---|---:|---|
| Auth / đăng nhập | ✅ Đạt | Đã dùng Firebase Auth + RTDB sync |
| Hồ sơ người dùng | ✅ Đạt | Lưu `users`, `profiles`, `sessions` |
| Khóa học | ⚠️ Chưa xong | Vẫn lấy từ backend HTTP |
| Bài học | ⚠️ Chưa xong | Vẫn lấy từ backend HTTP |
| Quiz | ⚠️ Chưa xong | Vẫn lấy từ backend HTTP |
| Kết quả quiz | ⚠️ Chưa xong | Chưa lưu toàn bộ lên Firebase |
| Admin | ⚠️ Chưa xong | Vẫn lấy từ backend HTTP |
| Contact / policy | ⚪ Không cần lưu bắt buộc | Có thể lưu nếu muốn |
| Quyền truy cập | ⚠️ Cần siết rules | Rules hiện tại còn quá rộng |

---

## 4) Những việc còn thiếu để lưu toàn bộ dự án

### Bắt buộc nếu muốn Firebase là nơi lưu toàn bộ dữ liệu
1. **Chuyển repository dữ liệu sang Firebase**
   - `learning_repository.dart`
   - `quiz_repository.dart`
   - `admin_repository.dart`

2. **Thiết kế schema chuẩn cho Realtime Database**
   - courses
   - lessons
   - quizzes
   - attempts
   - users/profiles/sessions

3. **Viết rules riêng cho từng node**
   - không dùng rule chung `.read/.write = auth != null`

4. **Seed dữ liệu ban đầu**
   - course mẫu
   - lesson mẫu
   - quiz mẫu
   - user seed

5. **Xử lý đồng bộ dữ liệu**
   - khi update profile → update cả `users` và `profiles`
   - khi làm quiz → lưu `attempts`
   - khi admin đổi role → update `users.role`

6. **Kiểm tra quota / giới hạn Spark**
   - nếu lưu dữ liệu học tập lớn, có thể chạm giới hạn miễn phí

---

## 5) Kết luận

### Hiện tại
Dự án **chưa thể nói là đã lưu toàn bộ lên Firebase** vì:
- phần auth đã xong
- nhưng learning / quiz / admin vẫn đang dùng HTTP API

### Để đạt mục tiêu “lưu toàn bộ dự án lên Firebase”
Bạn cần làm tiếp 3 khối chính:
1. **Chuyển dữ liệu học tập sang Firebase**
2. **Chuyển quiz sang Firebase**
3. **Viết rules chặt hơn cho Realtime Database**

---

## 6) Đánh giá nhanh
- **Sẵn sàng cho auth/profile**: ✅
- **Sẵn sàng cho toàn bộ dự án**: ❌ chưa xong
- **Ưu tiên bước tiếp theo**: viết schema + rules + chuyển learning/quiz/admin sang Firebase

---

**Ngày kiểm tra:** 11/04/2026


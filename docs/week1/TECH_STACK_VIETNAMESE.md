# BTL Learning - Giải Thích Công Nghệ (Tiếng Việt)

## 📱 Ứng Dụng Di Động (Frontend)

### **Platform sử dụng là gì?**
**Trả lời: Flutter (Dart)**

- Flutter là một framework được phát triển bởi Google
- Cho phép viết một lần, chạy được trên nhiều nền tảng:
  - 📱 Android
  - 📱 iOS
  - 🌐 Web
- Ưu điểm:
  - Phát triển nhanh, test nhanh (hot reload)
  - Giao diện đẹp mặc định (Material Design 3)
  - Hiệu năng cao, mượt mà trên điện thoại

### **Công cụ & Thư viện**
- **Flutter SDK**: Bộ công cụ chính
- **Firebase Integration** (kết nối Firebase):
  - `firebase_core`: Khởi tạo Firebase
  - `firebase_auth`: Xác thực người dùng
  - `firebase_database`: Lấy dữ liệu từ database
  - `firebase_analytics`: Theo dõi hành động người dùng
  - `firebase_crashlytics`: Theo dõi lỗi ứng dụng

### **Quản lý trạng thái (State Management)**
- **ChangeNotifier** (có sẵn trong Flutter)
- Tức là: khi dữ liệu thay đổi, giao diện tự động cập nhật
- Đơn giản, không cần thư viện phức tạp

---

## 🖥️ Máy chủ Phía Sau (Backend API)

### **Sử dụng gì để giải quyết dữ liệu?**
**Trả lời: Express.js (Node.js) hoặc Shelf (Dart)**

- Đây là các framework để tạo API (Giao diện lập trình ứng dụng)
- API là cái cầu nối giữa ứng dụng mobile và database
- Công việc của Backend:
  - ✅ Kiểm tra email/mật khẩu người dùng
  - ✅ Kiểm tra quiz (so đáp án, tính điểm)
  - ✅ Kiểm tra quyền (admin/mentor/student)
  - ✅ Lưu dữ liệu người dùng
  - ✅ Trả về kết quả cho app

### **Ví dụ: Quá trình kiểm tra quiz**

```
1. Học viên làm xong quiz trên điện thoại
2. App gửi câu trả lời đến Backend:
   {
     "quizId": "quiz-1",
     "answers": {
       "câu hỏi 1": "đáp án A",
       "câu hỏi 2": "đáp án C",
       "câu hỏi 3": "đáp án B"
     }
   }
3. Backend nhận dữ liệu, so sánh với đáp án đúng
4. Backend tính: 
   - Điểm = (số câu đúng / tổng câu) × 100
   - Ví dụ: 2 câu đúng / 3 câu = 66.7 điểm
5. Backend lưu kết quả vào database
6. Backend gửi kết quả về cho app
7. App hiển thị điểm số và giải thích cho học viên
```

### **Các API Endpoint (Điểm cuối)**

```
Địa chỉ: http://localhost:3000 (khi phát triển)
          https://... (khi chạy trên internet)

Đăng ký tài khoản:
  POST /api/v1/auth/register
  Gửi: email, mật khẩu, tên

Đăng nhập:
  POST /api/v1/auth/login
  Gửi: email, mật khẩu

Lấy thông tin cá nhân:
  GET /api/v1/profile/me

Cập nhật thông tin cá nhân:
  PATCH /api/v1/profile/me
  Gửi: tên mới

Thay đổi vai trò người dùng (chỉ Admin):
  PATCH /api/v1/profile/role
  Gửi: userId, vai trò mới

Lấy danh sách khóa học:
  GET /api/v1/courses

Lấy danh sách bài học trong khóa:
  GET /api/v1/courses/{courseId}/lessons

Nộp bài quiz:
  POST /api/v1/quizzes/{quizId}/submit
  Gửi: câu trả lời

Lấy kết quả làm bài:
  GET /api/v1/quizzes/{quizId}/attempts/me
```

### **Bảo mật**
- **JWT Token**: Một mã đặc biệt để xác minh người dùng
  - Cấp cho người dùng khi đăng nhập thành công
  - Mỗi lần app gửi yêu cầu, phải kèm token
  - Backend kiểm tra token có hợp lệ không
- **Vai trò**: Student < Mentor < Admin
  - Admin chỉ có thể thay đổi vai trò người khác
  - Student không thể xem dữ liệu của người khác

---

## 💾 Lưu Trữ Dữ Liệu (Storage)

### **Sử dụng gì để lưu trữ?**
**Trả lời: Firebase Realtime Database**

- **Loại**: Database NoSQL (không phải SQL truyền thống)
- **Đặc điểm**: 
  - Lưu dữ liệu dưới dạng JSON (cây cấu trúc)
  - Thay đổi dữ liệu, app sẽ nhận được ngay (real-time)
  - Không cần viết SQL phức tạp
- **Vị trí**: Asia-Southeast1 (Đông Nam Á, gần Việt Nam)
- **URL**: `https://news-app-6ef88-default-rtdb.asia-southeast1.firebasedatabase.app`

### **Dữ liệu được lưu như thế nào?**

```
Người Dùng:
  /users/
    /user1/
      - email: "hoc.vien@email.com"
      - displayName: "Nguyễn Văn A"
      - role: "student" (học viên)
      - createdAt: "2024-01-15"
    /user2/
      - email: "admin@email.com"
      - displayName: "Admin"
      - role: "admin"

Khóa Học:
  /courses/
    /course-python/
      - title: "Lập Trình Python Cơ Bản"
      - description: "Học Python từ zero"
      - level: "beginner" (cơ bản)
    /course-web/
      - title: "Lập Trình Web"
      - level: "intermediate" (trung cấp)

Bài Giảng:
  /lessons/
    /lesson1/
      - courseId: "course-python"
      - title: "Biến và Kiểu Dữ Liệu"
      - content: "Nội dung giảng dạy..."
      - quizId: "quiz1" (có quiz hoặc không)

Bài Quiz:
  /quizzes/
    /quiz1/
      - courseId: "course-python"
      - lessonId: "lesson1"
      - title: "Quiz: Biến và Kiểu Dữ Liệu"
      - questions: [
          {
            questionId: "q1",
            prompt: "Biến là gì?",
            options: ["Là một hộp chứa dữ liệu", "Là một hàm", ...],
            correctIndex: 0 (đáp án đúng là option 0)
          }
        ]

Kết Quả Làm Bài:
  /quizAttempts/
    /attempt1/
      - quizId: "quiz1"
      - userId: "user1"
      - score: 80 (điểm)
      - total: 100 (tổng điểm)
      - submittedAt: "2024-01-20 10:30:00"
      - answers: { q1: 0, q2: 1, q3: 0 }
      - review: [
          {
            questionId: "q1",
            userAnswer: 0 (học viên chọn A),
            correctAnswer: 0 (đáp án đúng là A),
            isCorrect: true (đúng)
          }
        ]
```

### **Firebase Authentication (Xác thực)**
- **Phương pháp**: Email + Mật khẩu
- **Bảo mật**:
  - Firebase tự động mã hóa mật khẩu
  - Mật khẩu không được lưu dưới dạng rõ
  - Chỉ lưu mã hash (mã hóa không thể đảo ngược)
- **Session**: 
  - Sau khi đăng nhập, Firebase cấp JWT token
  - Token có thời hạn 1 giờ
  - Sau đó phải đăng nhập lại

### **Quyền Truy Cập (Database Rules)**

```
Luật 1: Học viên chỉ có thể xem/sửa dữ liệu của mình
  - Xem thông tin cá nhân: ✅
  - Xem dữ liệu người khác: ❌
  - Xem khóa học công khai: ✅
  - Sửa tên người khác: ❌

Luật 2: Mentor có thể xem tiến độ học viên
  - Xem bài tập của học viên: ✅
  - Sửa bài tập của học viên: ❌
  - Xem tất cả khóa học: ✅

Luật 3: Admin có thể làm tất cả
  - Xem tất cả dữ liệu: ✅
  - Sửa tất cả dữ liệu: ✅
  - Xóa người dùng: ✅
  - Quản lý vai trò: ✅
```

---

## 🔐 Qua Trình Xác Thực (Authentication Flow)

### **Khi Đăng Ký Tài Khoản Mới**

```
1. Học viên nhập: email, mật khẩu, tên
2. App gửi dữ liệu đến Backend
3. Backend kiểm tra:
   - Email đã tồn tại chưa?
   - Mật khẩu đủ mạnh không? (tối thiểu 6 ký tự)
   - Tên hợp lệ không?
4. Backend dùng Firebase Auth để tạo tài khoản
5. Firebase mã hóa mật khẩu
6. Backend tạo bản ghi người dùng trong database
7. Firebase cấp JWT token
8. Backend trả về token cho app
9. App lưu token vào điện thoại (an toàn)
10. App hiển thị trang chủ
```

### **Khi Đăng Nhập**

```
1. Học viên nhập: email, mật khẩu
2. App gửi đến Backend
3. Backend kiểm tra email/mật khẩu với Firebase
4. Nếu đúng: Firebase tạo JWT token
5. Backend trả về token + thông tin người dùng
6. App lưu token
7. App hiển thị trang chủ
```

### **Khi Gửi Yêu Cầu Có Bảo Mật**

```
Mỗi lần app cần dữ liệu cá nhân, nó gửi:

Header: Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

Backend:
  1. Kiểm tra token có tồn tại không? ✅
  2. Giải mã token để lấy userId
  3. Kiểm tra token còn hợp lệ không? ✅
  4. Kiểm tra người dùng có quyền xem dữ liệu này không?
  5. Nếu ✅ tất cả: Trả về dữ liệu
  6. Nếu ❌: Trả về lỗi "Truy cập bị từ chối"
```

---

## 📊 Xử Lý Dữ Liệu Bài Toán

### **Bài Toán 1: Kiểm Tra Quiz**

**Vấn đề**: Khi học viên nộp bài quiz, làm sao biết đúng sai?

**Giải pháp**:

```
1. Backend nhận câu trả lời từ app

2. Backend lấy quiz từ database:
   {
     "quizId": "quiz-1",
     "questions": [
       {
         "id": "q1",
         "question": "2 + 2 = ?",
         "options": ["3", "4", "5"],
         "correctIndex": 1  ← Đáp án đúng là index 1 (= "4")
       },
       {
         "id": "q2",
         "question": "3 + 3 = ?",
         "options": ["5", "6", "7"],
         "correctIndex": 1  ← Đáp án đúng là index 1 (= "6")
       }
     ]
   }

3. Backend so sánh:
   - Câu 1: Học viên chọn index 1 (4) = Đúng ✅
   - Câu 2: Học viên chọn index 0 (5) = Sai ❌

4. Tính điểm:
   - Số câu đúng: 1
   - Tổng câu: 2
   - Điểm: (1 / 2) × 100 = 50 điểm

5. Lưu kết quả:
   {
     "attemptId": "attempt-123",
     "userId": "user-1",
     "quizId": "quiz-1",
     "score": 50,
     "total": 100,
     "submittedAt": "2024-01-20 10:30:00",
     "review": [
       {
         "questionId": "q1",
         "userAnswer": 1,
         "correctAnswer": 1,
         "isCorrect": true,
         "explanation": "Đúng! 2 + 2 = 4"
       },
       {
         "questionId": "q2",
         "userAnswer": 0,
         "correctAnswer": 1,
         "isCorrect": false,
         "explanation": "Sai! Đáp án đúng là 3 + 3 = 6"
       }
     ]
   }

6. Backend trả về kết quả cho app
7. App hiển thị: Điểm 50/100, Câu đúng 1/2, Giải thích từng câu
```

### **Bài Toán 2: Theo Dõi Tiến Độ**

**Vấn đề**: Làm sao biết học viên học được bao nhiêu?

**Giải pháp**:

```
Backend thu thập dữ liệu từ database:

1. Lấy tất cả quiz attempt của học viên:
   - quiz-1: 50 điểm
   - quiz-2: 80 điểm
   - quiz-3: 90 điểm

2. Tính thống kê:
   - Tổng quiz làm: 3
   - Điểm trung bình: (50 + 80 + 90) / 3 = 73.3 điểm
   - Điểm cao nhất: 90
   - Điểm thấp nhất: 50

3. Lấy bài giảng đã xem:
   - Bài 1: đã xem ✅
   - Bài 2: đã xem ✅
   - Bài 3: chưa xem ❌
   - Tiến độ: 2/3 bài = 66.7%

4. Gửi dữ liệu lên dashboard:
   {
     "totalCoursesEnrolled": 1,
     "totalLessonsCompleted": 2,
     "totalLessons": 3,
     "completionRate": 66.7,
     "averageScore": 73.3,
     "quizzesTaken": 3,
     "studyStreak": 15  (15 ngày liên tiếp học)
   }

5. App hiển thị biểu đồ, tiến độ cho học viên xem
```

### **Bài Toán 3: Quản Lý Quyền (RBAC)**

**Vấn đề**: Admin mới có thể thay đổi vai trò người khác, student không được?

**Giải pháp**:

```
Khi Backend nhận yêu cầu "Thay đổi vai trò":

1. Backend kiểm tra token:
   - Lấy userId từ token = "user-123"

2. Backend lấy thông tin user từ database:
   {
     "userId": "user-123",
     "email": "admin@email.com",
     "role": "admin"
   }

3. Backend kiểm tra:
   - Vai trò của người gửi là "admin"? ✅
   - Nếu ✅: Được phép thay đổi
   - Nếu ❌ (role = "student"): Không được phép
     Trả về lỗi: "Bạn không có quyền làm điều này"

4. Nếu được phép, Backend:
   - Lấy userId cần thay đổi: "user-456"
   - Thay đổi role trong database: "student" → "mentor"
   - Lưu vào database
   - Trả về thành công cho app
```

---

## 🚀 Triển Khai (Deployment)

### **Lúc Phát Triển (Development)**

```
Máy Tính Của Lập Trình Viên:
  📱 Flutter app (chế độ debug)
  🖥️ Backend API chạy trên localhost:3000
  💾 Firebase Emulator (database giả để test)

Lợi ích:
  - Thay đổi code → app tự update ngay (hot reload)
  - Test nhanh mà không ảnh hưởng tới người dùng thực
  - Kiểm tra lỗi dễ dàng
```

### **Khi Chính Thức Chạy (Production)**

```
Ứng Dụng (Frontend):
  📱 Android app → Google Play Store
  📱 iOS app → Apple App Store
  🌐 Web app → Firebase Hosting

Backend API:
  🖥️ Google Cloud Run (máy chủ trên internet)
  - Tự động scale (thêm máy khi có nhiều người)
  - Vị trí: Asia-Southeast1

Database:
  💾 Firebase Realtime Database
  - Tự động backup
  - Thay đổi real-time
  - Bảo mật tự động

Giám Sát:
  📊 Firebase Analytics: Xem người dùng dùng sao
  🐛 Firebase Crashlytics: Theo dõi lỗi
  📈 Cloud Monitoring: Theo dõi hiệu năng
```

---

## 📦 Công Cụ & Thư Viện Dùng

### **Ứng Dụng (Flutter)**
| Công Cụ | Dùng Để Làm Gì |
|---------|----------------|
| Flutter | Tạo ứng dụng mobile |
| firebase_core | Kết nối Firebase |
| firebase_auth | Đăng nhập/đăng ký |
| firebase_database | Lấy dữ liệu từ database |
| firebase_analytics | Theo dõi hành động người dùng |
| firebase_crashlytics | Tìm lỗi trong app |

### **Backend**
| Công Cụ | Dùng Để Làm Gì |
|---------|----------------|
| Express.js | Tạo API server |
| firebase-admin | Kết nối Firebase từ server |
| cors | Cho phép app gọi API |
| jsonwebtoken | Tạo JWT token |

---

## ⚡ Mục Tiêu Hiệu Năng

### **Ứng Dụng Mobile**
- **Dung lượng**: < 100 MB (không quá nặng)
- **Tốc độ khởi động**: < 3 giây
- **Tiết kiệm pin**: Không chạy ngầm lâu
- **Tiết kiệm data**: Dữ liệu JSON nhỏ gọn

### **Backend API**
- **Thời gian phản hồi**: < 200 millisecond (rất nhanh)
- **Người dùng đồng thời**: Chịu được 1000+ người
- **Lưu trữ**: Có index để tìm kiếm nhanh
- **Lưu đệm**: Cache dữ liệu không thay đổi

### **Database**
- **Giới hạn**: Plan Spark miễn phí có hạn
  - Có thể nâng cấp lên Blaze nếu cần
- **Kết nối đồng thời**: Tự động quản lý
- **Kích thước dữ liệu**: Mỗi message < 16 MB

---

## 🔄 Kế Hoạch Phát Triển Tương Lai

### **Tuần 4-5**
- ✅ Hoàn thiện API Khóa Học
- ✅ Engine Quiz chi tiết
- ✅ Dashboard xem tiến độ
- ✅ Biểu đồ thống kê

### **Tuần 6+**
- ✅ AI feedback từ Google Gemini
- ✅ Upload file bài tập
- ✅ Diễn đàn thảo luận
- ✅ Video hosting
- ✅ Push notification (thông báo)
- ✅ Chế độ offline (dùng khi không có internet)

---

## 📚 Tài Liệu Tham Khảo

- **Firebase**: https://firebase.flutter.dev
- **Flutter**: https://flutter.dev/docs
- **Dart**: https://dart.dev/guides
- **Test API**: Postman hoặc Insomnia (ứng dụng test API)
- **Quản lý Code**: Git/GitHub

---

**Cập nhật lần cuối**: 11/04/2026


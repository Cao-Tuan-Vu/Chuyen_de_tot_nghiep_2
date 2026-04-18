# BTL Learning App - Requirements & Planning

## 1. Product Goal

Xây dựng app học lập trình cơ bản trên mobile, gồm quiz + bài tập thực hành + AI trợ giảng.

---

## 2. MVP Scope (Week 1-3)

### Week 1-3 Core Features
- Đăng ký, đăng nhập, đăng xuất
- Hồ sơ người dùng: xem và cập nhật tên hiển thị
- Role cơ bản: `student`, `mentor`, `admin`
- REST API auth/profile/role cho mobile
- Firebase project setup (Auth/Realtime Database/Analytics)

### Out of Scope (Phase 2+)
- Quiz engine đầy đủ
- Nộp bài tập file
- Gemini feedback endpoint
- Admin CMS giao diện đầy đủ

---

## 3. Acceptance Criteria (Week 1)

- ✓ Flutter app khởi động vào màn hình login
- ✓ Đăng nhập tài khoản seed thành công và vào home
- ✓ Cập nhật display name thành công qua backend
- ✓ API role update chỉ cho admin

---

## 4. Data Model

### Core Entities (Week 1)

#### User
- `id` (string)
- `email` (string)
- `passwordHash` / `password` (dev only)
- `displayName` (string)
- `role` (enum: student, mentor, admin)
- `createdAt` (datetime)
- `updatedAt` (datetime)

#### Profile
- `userId` (string, 1:1 relation with User)
- `avatarUrl` (string, nullable)
- `bio` (string, nullable)

### Entities for Week 4-5

#### Course
- `id` (string)
- `title` (string)
- `description` (string)
- `level` (enum: beginner, intermediate, advanced)

#### Lesson
- `id` (string)
- `courseId` (string, n:1 relation with Course)
- `title` (string)
- `order` (int)
- `content` (string, lý thuyết)
- `quizId` (string, nullable)

#### Quiz
- `id` (string)
- `courseId` (string)
- `lessonId` (string)
- `title` (string)
- `questions` (Question[])

#### Question
- `id` (string)
- `prompt` (string)
- `options` (string[])
- `correctIndex` (int, server-side only)
- `explanation` (string)

#### QuizAttempt
- `attemptId` (string)
- `quizId` (string)
- `userId` (string)
- `score` (int)
- `total` (int)
- `submittedAt` (datetime)
- `answers` (map: questionId -> selectedIndex)
- `review` (list: {questionId, selectedIndex, correctIndex, isCorrect, explanation})

---

## 5. API Contract

### Base URL
- Development: `http://localhost:3000`
- API Version: `/api/v1`

### Authentication
- **Scheme**: Bearer Token (JWT)
- **Header**: `Authorization: Bearer <token>`

### Endpoints (Week 1)

#### Health Check
```
GET /health
Response: 200 OK
```

#### Authentication

**Register Account**
```
POST /api/v1/auth/register
Content-Type: application/json

Request:
{
  "email": "user@example.com",
  "password": "password123",
  "displayName": "User Name"
}

Response: 201 Created
```

**Login**
```
POST /api/v1/auth/login
Content-Type: application/json

Request:
{
  "email": "user@example.com",
  "password": "password123"
}

Response: 200 OK
```

#### Profile Management

**Get Current Profile**
```
GET /api/v1/profile/me
Authorization: Bearer <token>

Response: 200 OK
```

**Update Current Profile**
```
PATCH /api/v1/profile/me
Authorization: Bearer <token>
Content-Type: application/json

Request:
{
  "displayName": "New Display Name"
}

Response: 200 OK
```

**Update User Role (Admin Only)**
```
PATCH /api/v1/profile/role
Authorization: Bearer <token>
Content-Type: application/json

Request:
{
  "userId": "user-id",
  "role": "student|mentor|admin"
}

Response: 200 OK
```

### Endpoints (Week 4-5)

#### Courses
```
GET /api/v1/courses
Response: 200 OK (List all courses)

GET /api/v1/courses/{courseId}/lessons
Response: 200 OK | 404 Not Found

GET /api/v1/courses/{courseId}/lessons/{lessonId}
Response: 200 OK | 404 Not Found
```

#### Quiz
```
GET /api/v1/quizzes/{quizId}
Response: 200 OK | 404 Not Found
(Returns quiz without exposing correct answers)

POST /api/v1/quizzes/{quizId}/submit
Authorization: Bearer <token>
Content-Type: application/json

Request:
{
  "answers": {
    "question-1": 0,
    "question-2": 2
  }
}

Response: 200 OK | 400 Bad Request | 401 Unauthorized | 404 Not Found

GET /api/v1/quizzes/{quizId}/attempts/me
Authorization: Bearer <token>
Response: 200 OK | 401 Unauthorized
(Get current user attempts by quiz)
```

---

## 6. Firebase Setup

### Current Project Configuration
- **Project ID**: `news-app-6ef88`
- **Realtime Database URL**: `https://news-app-6ef88-default-rtdb.asia-southeast1.firebasedatabase.app`
- **Region**: `asia-southeast1`
- **Plan**: Spark

### Setup Checklist

- [ ] **Firebase Authentication**
  - Enable Email/Password sign-in method

- [ ] **Realtime Database**
  - Import `database.rules.json` from project root
  - Configure security rules for RBAC

- [ ] **Flutter App Registration**
  - Add Android app in Firebase console
  - Add iOS app in Firebase console
  - Download `google-services.json` (Android)
  - Download `GoogleService-Info.plist` (iOS)

- [ ] **FlutterFire Configuration**
  - Run `flutterfire configure` command
  - Generate `lib/firebase_options.dart`

- [ ] **Analytics & Crashlytics**
  - Enable Firebase Analytics
  - Enable Firebase Crashlytics

### Security Notes
- ⚠️ Do NOT commit service account JSON to Git
- Use environment variables for backend secrets and Firebase admin credentials

---

## 7. RBAC Matrix (Role-Based Access Control)

| Action | Student | Mentor | Admin |
|---|:---:|:---:|:---:|
| Login / Register | ✓ | ✓ | ✓ |
| View own profile | ✓ | ✓ | ✓ |
| Update own display name | ✓ | ✓ | ✓ |
| Update another user's role | ✗ | ✗ | ✓ |
| Access admin content APIs | ✗ | Limited | ✓ |

---

## 8. UI/UX Wireframes

### Screen 1: Login / Register
**Components:**
- Email input field
- Password input field
- Display name input (only visible in Register mode)
- Toggle button: Switch between Login / Register
- Primary button: "Đăng nhập" (Login) / "Tạo tài khoản" (Register)

### Screen 2: Home
**Components:**
- Greeting: "Xin chào {displayName}"
- Display current user role
- Navigation button: "Vào khóa học" (Browse Courses)
- Navigation button: "Mở profile" (Edit Profile)
- Action button: "Đăng xuất" (Logout)

### Screen 3: Profile
**Components:**
- Email display (read-only)
- Role display (read-only)
- Display name input (editable)
- Primary button: "Lưu thay đổi" (Save Changes)

### Screen 4: Course List (Week 4)
**Components:**
- List of courses with:
  - Course title
  - Difficulty level
  - Short description
- Action: Tap course to view lessons

### Screen 5: Lesson List (Week 4)
**Components:**
- Ordered list of lessons
- Show lesson type indicators:
  - "Lý thuyết" (Theory only)
  - "Lý thuyết + Quiz" (Theory with Quiz)
- Action: Tap lesson to view details

### Screen 6: Lesson Detail (Week 4)
**Components:**
- Lesson title
- Theory content (HTML or formatted text)
- Conditional button: "Làm quiz bài này" (Take Quiz) if quiz available

### Screen 7: Quiz (Week 5)
**Components:**
- Question list with options
- Radio buttons / Multiple choice UI
- Navigation between questions
- Primary button: "Nộp bài" (Submit Quiz)

### Screen 8: Quiz Result (Week 5)
**Components:**
- Overall score display: "Điểm / Tổng điểm"
- List of questions with:
  - Correct/Incorrect indicator
  - User's answer
  - Correct answer
  - Explanation
- Action: Return to course or go home

### Screen Flow Diagram
```
Login/Register
    ↓
Home
    ├→ Profile → Update displayName → Home
    ├→ Khóa học
    │   ├→ Danh sách bài học
    │   │   ├→ Chi tiết bài học
    │   │   │   ├→ Quiz
    │   │   │   │   └→ Kết quả
    │   │   │   └→ Back to lesson list
    │   │   └→ Back to courses
    │   └→ Back to home
    └→ Đăng xuất
        ↓
    Login
```

---

## 9. Development Timeline

- **Week 1**: Auth, Profile, Firebase setup ✓ (Current)
- **Week 2**: Refine UI/UX, Backend API polish
- **Week 3**: Integration testing, bug fixes
- **Week 4-5**: Course & Lesson APIs, Quiz engine
- **Week 6+**: Advanced features (AI feedback, file submissions)

---

## 10. Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter (Dart)
- **State Management**: TBD
- **Firebase Integration**: FlutterFire
- **Analytics**: Firebase Analytics + Crashlytics

### Backend (Dart)
- **Framework**: Shelf / Express
- **Database**: Firebase Realtime Database
- **Authentication**: Firebase Auth
- **Deployment**: Cloud Run (GCP)

### Infrastructure
- **Firebase Project**: Spark plan (scalable to Blaze)
- **Version Control**: Git (GitHub)
- **CI/CD**: GitHub Actions

---

## 11. Notes & Constraints

- Support Vietnamese language throughout UI
- Mobile-first design (responsive for various screen sizes)
- Offline support consideration for future releases
- Performance target: < 3s app load time
- Comply with Firebase Spark plan free tier limits during development
- Migrate to Blaze pay-as-you-go plan for production


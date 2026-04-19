# 📚 BTL - Ứng dụng Học Lập trình với Quiz và Bài Tập

> Ứng dụng Flutter cho việc học các khóa học lập trình từ cơ bản đến nâng cao, với các bài học, quiz và hệ thống tracking tiến độ.

---

## 🎯 Mục tiêu & Features

### ✅ Tính năng chính

#### 1️⃣ **Hệ thống Khóa học**
- 📖 3 khóa học (Dart cơ bản, OOP, Flutter)
- 🎓 Phân cấp độ khó (Beginner, Intermediate)
- 📝 Mô tả chi tiết mỗi khóa học

#### 2️⃣ **Bài học & Lý thuyết**
- 📚 9 bài học tổng cộng
- 📄 Nội dung lý thuyết đầy đủ (Markdown format)
- 💡 Ví dụ code inline
- 🔖 Bài học có thứ tự (order)

#### 3️⃣ **Quiz theo bài học**
- ✅ 8 quiz đi kèm bài học
- ❓ 5 câu hỏi mỗi quiz
- 🎯 Multiple choice (4 tuỳ chọn)
- 💬 Giải thích chi tiết

#### 4️⃣ **Quiz Tổng hợp (Final/Comprehensive Quiz)**
- 🏆 1-2 quiz tổng hợp mỗi khóa học
- ⭐ 10 câu hỏi mỗi cái
- 📊 Kiểm tra toàn bộ kiến thức khóa học
- 🎊 Hiển thị rõ ràng cuối danh sách bài học

#### 5️⃣ **Tracking & Results**
- 📈 Lưu kết quả quiz attempts
- 🔍 Review chi tiết sau khi làm quiz
- ✔️ Tính điểm percentage
- 💾 Persistence trong Firebase

---

## 🗂️ Cấu trúc Dữ liệu

### Database Schema

```
Firebase Realtime Database/
├── courses/
│   ├── course_dart_basics
│   │   ├── id: "course_dart_basics"
│   │   ├── title: "Dart cơ bản"
│   │   ├── description: "..."
│   │   ├── level: "beginner"
│   │   └── comprehensiveQuizId: "quiz_dart_comprehensive"
│   │
│   ├── course_oop
│   │   └── comprehensiveQuizId: "quiz_oop_comprehensive"
│   │
│   └── course_flutter_basics
│       └── comprehensiveQuizId: null
│
├── lessons/
│   ├── lesson_dart_001
│   │   ├── id: "lesson_dart_001"
│   │   ├── courseId: "course_dart_basics"
│   │   ├── title: "Giới thiệu Dart"
│   │   ├── order: 1
│   │   ├── content: "Dart là ngôn ngữ..."  # Markdown
│   │   └── quizId: "quiz_dart_001"
│   │
│   └── [ 8 more lessons ]
│
├── quizzes/
│   ├── quiz_dart_001  (5 questions)
│   ├── quiz_dart_002  (5 questions)
│   ├── ...
│   ├── quiz_dart_comprehensive  (10 questions)
│   └── quiz_oop_comprehensive   (10 questions)
│
├── attempts/  # Generated when user submits
│   └── attempt_id_xyz
│       ├── attemptId: "..."
│       ├── quizId: "quiz_dart_001"
│       ├── userId: "student_001"
│       ├── score: 80
│       ├── total: 5
│       ├── submittedAt: "2026-04-18T..."
│       └── review: [{ question, selected, correct, ... }]
│
├── users/
│   ├── admin_001
│   └── student_001
│
├── profiles/
│   ├── admin_001
│   └── student_001
│
├── sessions/
│   └── [session tracking]
│
└── contacts/
    └── [user feedback]
```

---

## 🚀 Quick Start

### 1. Nạp dữ liệu mẫu

#### **Easiest: Firebase Console**
```
1. Firebase Console → BTL Project
2. Realtime Database
3. Menu (⋮) → Import JSON
4. Chọn file: docs/week1/firebase_seed.json
5. Nhấp Import ✅
```

#### **Alternative: Node.js Script**
```bash
# Cài đặt dependencies
npm install firebase-admin dotenv

# Tạo .env
cat > .env << EOF
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
DATABASE_URL=https://btl-app-db-default-rtdb.firebaseio.com
EOF

# Download serviceAccountKey.json từ Firebase Console
# (Project Settings → Service Accounts → Node.js → Generate)

# Chạy script
node scripts/load_firebase_seed.js
```

### 2. Chạy ứng dụng

```bash
# Build & run
flutter clean
flutter pub get
flutter run

# Or use script
./scripts/start-dev.ps1
```

### 3. Test dữ liệu

```bash
# Navigate in app:
# 1. Login (student@btl-learning.com / student_001)
# 2. Tap "Khóa học" → "Dart cơ bản"
# 3. Thấy 5 bài học
# 4. Scroll xuống → "Làm bài kiểm tra tổng hợp"
# 5. Làm 10 câu hỏi
# 6. Xem kết quả
```

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| `docs/week1/firebase_seed.json` | Dữ liệu mẫu (600+ lines) |
| `docs/SEED_DATA_GUIDE.md` | Hướng dẫn nạp dữ liệu |
| `docs/FEATURES_SUMMARY.md` | Chi tiết tính năng |
| `scripts/load_firebase_seed.js` | Automatic data loader |
| `lib/features/learning/domain/entities/course.dart` | ✅ Thêm comprehensiveQuizId |
| `lib/features/learning/presentation/pages/lesson_list_page.dart` | ✅ Thêm Final Quiz button |

---

## 🎓 Learning Path

### Khóa 1: Dart cơ bản (5 bài)
```
📌 Bài 1: Giới thiệu Dart
   - Nội dung + Quiz 5 câu
   
📌 Bài 2: Biến và kiểu dữ liệu
   - Nội dung + Quiz 5 câu
   
📌 Bài 3: Vòng lặp và điều kiện
   - Nội dung + Quiz 5 câu
   
📌 Bài 4: Hàm (Functions)
   - Nội dung + Quiz 5 câu
   
📌 Bài 5: Xử lý chuỗi & Collections
   - Nội dung + Quiz 5 câu
   
🏆 FINAL: Quiz tổng hợp Dart
   - 10 câu kiểm tra toàn bộ
```

### Khóa 2: OOP (2 bài)
```
📌 Bài 1: Class và Object
   - Nội dung + Quiz 5 câu
   
📌 Bài 2: Inheritance
   - Nội dung + Quiz 5 câu
   
🏆 FINAL: Quiz tổng hợp OOP
   - 10 câu từ toàn khóa học
```

### Khóa 3: Flutter (2 bài)
```
📌 Bài 1: Widget cơ bản
   - Nội dung + Quiz 5 câu
   
📌 Bài 2: State Management
   - Chỉ lý thuyết (không quiz)
```

---

## 🧪 Testing & Quality

```bash
# Kiểm tra lint
flutter analyze          # ✅ No issues

# Chạy unit & widget tests
flutter test            # ✅ All tests passing

# Build release
flutter build apk       # Hoặc ios, web
```

---

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.11+
- **Backend**: Firebase Realtime Database
- **Auth**: Firebase Authentication
- **Language**: Dart 3+
- **Package Management**: pubspec.yaml

### Key Dependencies
```yaml
firebase_core: ^3.13.1
firebase_auth: ^5.5.4
firebase_database: ^11.3.7
firebase_analytics: ^11.4.7
shared_preferences: ^2.3.2
http: ^1.2.2
```

---

## 📊 Statistics

| Loại | Số lượng |
|------|---------|
| Khóa học | 3 |
| Bài học | 9 |
| Quiz bài | 8 |
| Quiz tổng | 2 |
| Câu hỏi | 50+ |
| Dòng dữ liệu JSON | 600+ |

---

## 🎨 UI Components

### Quiz Screen
- Questions displayed one at a time
- 4 multiple choice options
- Progress bar
- Submit button

### Results Screen
- Score (percentage)
- Correct/incorrect breakdown
- Review each question
- Detailed explanations

### Course List
- Course cards with level
- Tap to enter course
- Show progress

### Lesson List
- Ordered lesson items
- Quiz indicator
- **NEW**: Final Quiz button at bottom

---

## 🔒 Permissions & Rules

### Firebase Database Rules (Development)
```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

⚠️ **Production**: Implement proper security rules

---

## 🐛 Troubleshooting

### Data not loading
```
✓ Check: User is logged in
✓ Check: Database URL in firebase_options.dart
✓ Check: Firebase rules allow read
✓ Check: Repository loads from correct path
✓ Check: Network connection
```

### Import JSON fails
```
✓ Validate JSON syntax (https://jsonlint.com)
✓ Check key names don't have special chars
✓ Ensure Firebase rules allow write
✓ File size reasonable (<10MB)
```

### Quiz doesn't display
```
✓ Verify comprehensiveQuizId in Database
✓ Verify quiz exists in quizzes/
✓ Check QuizRepository getQuiz() works
✓ Verify course has comprehensiveQuizId
```

---

## 📚 Additional Resources

- [Firebase Docs](https://firebase.google.com/docs)
- [Flutter Docs](https://flutter.dev/docs)
- [Dart Docs](https://dart.dev/guides)
- [Material Design](https://material.io/design)

---

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/new-feature`
2. Commit changes: `git commit -am 'Add feature'`
3. Push to branch: `git push origin feature/new-feature`
4. Submit pull request

---

## 📝 Naming Conventions

### Database Keys
- `course_dart_basics` - snake_case
- `lesson_dart_001` - lesson_subject_number format
- `quiz_dart_001` - quiz_subject_number format

### File Names
- `course.dart` - entity files are lowercase
- `course_list_page.dart` - pages use _page suffix
- `learning_repository.dart` - repos use _repository suffix

---

## 📅 Release Notes

### v1.0 (2026-04-18)
- ✅ 3 courses with 9 lessons
- ✅ 8 lesson quizzes + 2 comprehensive quizzes
- ✅ Seed data loader script
- ✅ UI for final quiz
- ✅ Quiz result tracking

### Planned v1.1
- 🔄 Progress tracking
- 🔄 Leaderboard
- 🔄 Certificates
- 🔄 Coding exercises

---

## 📞 Support

Gặp vấn đề? 
- 📧 Email: support@btl-learning.com
- 🐛 Report bugs: issues/
- 💬 Discussions: discussions/

---

**Made with ❤️ by BTL Team**  
*Build to Learn (BTL) - Xây dựng để Học*

Last Updated: 2026-04-18  
License: MIT


import json
from pathlib import Path

path = Path(r"C:/Users/phuca/AndroidStudioProjects/BTL/sample_data/realtiem database.json")


def build_quiz(quiz_id, title, course_id, lesson_id, questions):
    payload = {
        "id": quiz_id,
        "title": title,
        "courseId": course_id,
        "lessonId": lesson_id,
    }
    for idx, question in enumerate(questions, start=1):
        payload[f"q{idx}"] = question["q"]
        payload[f"q{idx}_opts"] = question["opts"]
        payload[f"q{idx}_ans"] = question["ans"]
    return payload


COURSE_BLUEPRINT = {
    "laravel": {
        "prefix": "lv",
        "title": "Laravel",
        "desc": "Learn Laravel from basic to practical web app development",
        "level": "intermediate",
        "finalQuiz": "quiz_laravel_final",
        "lessons": [
            ("Laravel Intro & Architecture", "Overview of Laravel architecture and project structure"),
            ("Routing and Controllers", "Define routes and map requests to controllers"),
            ("Blade Templates", "Build reusable UI views with Blade"),
            ("Eloquent ORM", "Model database entities and relationships"),
            ("API and Security", "Create APIs with auth and middleware"),
        ],
    },
    "firebase_fundamentals": {
        "prefix": "fb",
        "title": "Firebase",
        "desc": "Learn Firebase services for mobile and web apps",
        "level": "intermediate",
        "finalQuiz": "quiz_firebase_final",
        "lessons": [
            ("Firebase Overview", "Understand Firebase products and app architecture"),
            ("Authentication", "Implement sign in and user session flows"),
            ("Realtime Database", "Store and sync JSON tree data in real time"),
            ("Cloud Firestore", "Model scalable document based data"),
            ("Functions and Hosting", "Run backend logic and deploy web resources"),
        ],
    },
    "php_basics": {
        "prefix": "php",
        "title": "PHP Basics",
        "desc": "Learn PHP syntax, backend logic and server side basics",
        "level": "beginner",
        "finalQuiz": "quiz_php_final",
        "lessons": [
            ("PHP Syntax and Variables", "Start with PHP tags, variables and output"),
            ("Functions and Arrays", "Write reusable functions and array logic"),
            ("Forms and Request Data", "Handle GET and POST input safely"),
            ("Sessions and Cookies", "Maintain login state and browser context"),
            ("File and Database Access", "Read files and connect to relational databases"),
        ],
    },
    "python_basics": {
        "prefix": "py",
        "title": "Python Basics",
        "desc": "Learn Python programming fundamentals",
        "level": "beginner",
        "finalQuiz": "quiz_python_final",
        "lessons": [
            ("Python Intro and Data Types", "Work with core data types and variables"),
            ("Conditionals and Loops", "Control flow using if, for and while"),
            ("Functions and Modules", "Organize code into reusable modules"),
            ("Collections and Comprehensions", "Use list, dict, set and clean transformations"),
            ("Files and Exceptions", "Read files and handle runtime errors"),
        ],
    },
    "java_core": {
        "prefix": "jv",
        "title": "Java Core",
        "desc": "Learn Java core concepts for backend and OOP development",
        "level": "intermediate",
        "finalQuiz": "quiz_java_final",
        "lessons": [
            ("Java Fundamentals", "Understand syntax, JVM and class structure"),
            ("OOP in Java", "Apply encapsulation, inheritance and polymorphism"),
            ("Collections Framework", "Use List, Set and Map effectively"),
            ("Exception Handling", "Create robust error handling flows"),
            ("Streams and Generics", "Write modern type safe and functional style code"),
        ],
    },
    "sql_fundamentals": {
        "prefix": "sql",
        "title": "SQL Fundamentals",
        "desc": "Learn SQL querying and relational database fundamentals",
        "level": "beginner",
        "finalQuiz": "quiz_sql_final",
        "lessons": [
            ("SQL Select Basics", "Query and filter rows with SELECT and WHERE"),
            ("JOIN and Aggregate", "Combine tables and summarize data"),
            ("Data Definition", "Create and alter tables with DDL"),
            ("Data Manipulation", "Insert, update and delete records safely"),
            ("Index and Optimization", "Improve query performance with indexes"),
        ],
    },
}


THEORY_BLUEPRINT = {
    "laravel": [
        {
            "core": "kiến trúc MVC, cấu trúc thư mục và vòng đời request",
            "objectives": ["Hiểu luồng route -> controller -> view", "Đọc nhanh cấu trúc dự án", "Dùng artisan ở mức cơ bản"],
            "practice": "Tạo project mới, mở routes/web.php và ánh xạ một URL vào một method của controller.",
        },
        {
            "core": "khai báo route, truyền tham số route và tổ chức controller",
            "objectives": ["Viết route GET/POST", "Nhận tham số từ URL", "Nhóm route theo prefix"],
            "practice": "Xây route danh sách sản phẩm và chi tiết sản phẩm bằng ProductController.",
        },
        {
            "core": "directive Blade, kế thừa template và component tái sử dụng",
            "objectives": ["Dùng @extends và @section", "Render vòng lặp/điều kiện", "Tách partial dùng lại"],
            "practice": "Tạo layout có header/footer và render bảng dữ liệu động từ controller.",
        },
        {
            "core": "model Eloquent, quan hệ dữ liệu và query builder",
            "objectives": ["Khai báo quan hệ one-to-many", "CRUD với Eloquent", "Dùng eager loading"],
            "practice": "Tạo model Post và Comment, sau đó lấy bài viết kèm bình luận bằng eager loading.",
        },
        {
            "core": "middleware, xác thực route và chuẩn hóa response API",
            "objectives": ["Bảo vệ route bằng middleware", "Thiết kế JSON nhất quán", "Xử lý lỗi validate"],
            "practice": "Tạo một API endpoint có bảo vệ và trả về payload success/error theo chuẩn.",
        },
    ],
    "firebase_fundamentals": [
        {
            "core": "hệ sinh thái Firebase và cách chọn dịch vụ phù hợp",
            "objectives": ["Phân biệt Auth, Database, Firestore, Storage", "Chọn dịch vụ theo bài toán", "Phác thảo kiến trúc app"],
            "practice": "Vẽ sơ đồ kiến trúc đơn giản dùng Auth + Database + Hosting.",
        },
        {
            "core": "luồng đăng ký/đăng nhập, provider xác thực và trạng thái phiên",
            "objectives": ["Làm đăng nhập email-password", "Xử lý lỗi xác thực", "Lưu trạng thái đăng nhập"],
            "practice": "Tạo form login/register và chỉ hiển thị profile sau khi đăng nhập thành công.",
        },
        {
            "core": "cấu trúc JSON tree realtime, fan-out dữ liệu và security rules",
            "objectives": ["Thiết kế dữ liệu lồng nhau", "Đọc/ghi realtime", "Bảo vệ node theo user"],
            "practice": "Lưu tiến độ học tại users/{uid} và kiểm thử quyền đọc/ghi theo rule.",
        },
        {
            "core": "collection document, index và pattern truy vấn",
            "objectives": ["Thiết kế schema document", "Truy vấn có filter", "Dùng composite index"],
            "practice": "Tạo collection lessons và truy vấn theo courseId có sắp xếp.",
        },
        {
            "core": "backend hướng sự kiện với Functions và deploy tĩnh bằng Hosting",
            "objectives": ["Trigger function khi dữ liệu đổi", "Đưa logic nhạy cảm lên server", "Deploy web nhanh"],
            "practice": "Tạo cloud function cộng điểm và deploy một trang web cơ bản.",
        },
    ],
    "php_basics": [
        {
            "core": "cú pháp PHP, biến, toán tử và xuất dữ liệu",
            "objectives": ["Viết block PHP đúng", "Dùng kiểu dữ liệu cơ bản", "Xuất dữ liệu an toàn"],
            "practice": "Tạo script nhận input và in thông tin profile đã định dạng.",
        },
        {
            "core": "hàm, thao tác mảng và tái sử dụng logic",
            "objectives": ["Khai báo hàm", "Dùng mảng associative", "Trả dữ liệu có cấu trúc"],
            "practice": "Viết helper để biến đổi và lọc danh sách sản phẩm.",
        },
        {
            "core": "xử lý HTTP request và kiểm tra dữ liệu đầu vào",
            "objectives": ["Đọc GET/POST", "Làm sạch input", "Xử lý submit form"],
            "practice": "Tạo validate form liên hệ và trả lỗi theo từng trường.",
        },
        {
            "core": "session, vòng đời cookie và xác thực cơ bản",
            "objectives": ["Lưu session người dùng", "Set/xóa cookie", "Làm luồng logout"],
            "practice": "Làm login theo session và trang dashboard có bảo vệ.",
        },
        {
            "core": "xử lý file và kết nối SQL cơ bản",
            "objectives": ["Đọc/ghi file local", "Kết nối cơ sở dữ liệu", "Dùng prepared statement"],
            "practice": "Lưu ghi chú người dùng vào DB và hiển thị có phân trang.",
        },
    ],
    "python_basics": [
        {
            "core": "biến, kiểu số/chuỗi/bool và toán tử cơ bản",
            "objectives": ["Dùng dynamic typing đúng cách", "Chuyển đổi kiểu dữ liệu", "Viết biểu thức dễ đọc"],
            "practice": "Tạo chương trình tính điểm đơn giản từ input dòng lệnh.",
        },
        {
            "core": "if/elif/else, vòng lặp for và while",
            "objectives": ["Rẽ nhánh đúng", "Lặp qua list an toàn", "Tránh vòng lặp vô hạn"],
            "practice": "Xây game đoán số bằng điều kiện và vòng lặp.",
        },
        {
            "core": "định nghĩa hàm, tham số và import module",
            "objectives": ["Chia code thành hàm nhỏ", "Dùng tham số mặc định", "Import module tiện ích"],
            "practice": "Refactor script thành io.py, calc.py và main.py.",
        },
        {
            "core": "sử dụng list/dict/set và comprehension",
            "objectives": ["Biến đổi collection gọn", "Dùng dict để tra cứu", "Giảm vòng lặp dư thừa"],
            "practice": "Chuyển dữ liệu quiz thô thành thống kê bằng comprehension.",
        },
        {
            "core": "đọc ghi file và xử lý ngoại lệ",
            "objectives": ["Đọc/ghi file text", "Bắt đúng loại exception", "Giữ chương trình chạy ổn định"],
            "practice": "Parse file dạng CSV và xử lý mềm khi gặp dòng lỗi.",
        },
    ],
    "java_core": [
        {
            "core": "mô hình JVM, cấu trúc class và kiểu dữ liệu",
            "objectives": ["Compile/run chương trình Java", "Nắm cấu trúc class", "Dùng kiểu dữ liệu chính xác"],
            "practice": "Viết class Student và chạy từ main method đơn giản.",
        },
        {
            "core": "đóng gói, kế thừa, interface và đa hình",
            "objectives": ["Thiết kế abstraction", "Áp dụng contract qua interface", "Override rõ ràng"],
            "practice": "Tạo interface Payment với nhiều implementation.",
        },
        {
            "core": "Collections API và chiến lược duyệt dữ liệu",
            "objectives": ["Chọn List/Set/Map phù hợp", "Dùng iterator an toàn", "Tránh lỗi mutate phổ biến"],
            "practice": "Lưu quiz attempts trong Map<userId, List<Attempt>> và tính tổng kết.",
        },
        {
            "core": "checked/unchecked exception và try-catch-finally",
            "objectives": ["Mô hình hóa loại lỗi", "Xử lý lỗi có thể phục hồi", "Giữ code dễ bảo trì"],
            "practice": "Tạo custom exception cho invalid score và missing quiz.",
        },
        {
            "core": "generics và stream pipeline",
            "objectives": ["Viết utility type-safe", "Filter/map/reduce collection", "Tăng độ rõ ràng"],
            "practice": "Dùng stream để tạo output top-N leaderboard.",
        },
    ],
    "sql_fundamentals": [
        {
            "core": "SELECT, WHERE, ORDER BY, LIMIT",
            "objectives": ["Viết truy vấn lấy dữ liệu", "Lọc bằng điều kiện", "Sắp xếp kết quả"],
            "practice": "Truy vấn top 10 học viên theo điểm và lọc theo level.",
        },
        {
            "core": "INNER/LEFT JOIN và hàm tổng hợp",
            "objectives": ["Join bảng liên quan", "Dùng COUNT/SUM/AVG", "Đọc kết quả nhóm"],
            "practice": "Join users với attempts để tính điểm trung bình theo user.",
        },
        {
            "core": "DDL: CREATE, ALTER, DROP",
            "objectives": ["Thiết kế schema bảng", "Thêm ràng buộc", "Thay đổi schema an toàn"],
            "practice": "Tạo bảng courses, lessons và quiz_attempts có khóa chính/ngoại.",
        },
        {
            "core": "DML: INSERT, UPDATE, DELETE",
            "objectives": ["Thao tác dữ liệu chính xác", "Cập nhật an toàn", "Dùng transaction"],
            "practice": "Thêm dữ liệu attempts mẫu và cập nhật final score trong một transaction.",
        },
        {
            "core": "index và tối ưu truy vấn cơ bản",
            "objectives": ["Hiểu trade-off của index", "Đọc query plan", "Giảm chi phí scan"],
            "practice": "Thêm index cho courseId và so sánh hiệu năng truy vấn.",
        },
    ],
}


SNIPPET_BLUEPRINT = {
    "laravel": [
        """```php
Route::get('/hello', function () {
    return 'Xin chao Laravel';
});
```""",
        """```php
Route::get('/products/{id}', [ProductController::class, 'show']);

public function show($id) {
    return "Product ID: $id";
}
```""",
        """```php
<!-- resources/views/products/index.blade.php -->
@extends('layouts.app')
@section('content')
  <h1>{{ $title }}</h1>
@endsection
```""",
        """```php
class Post extends Model {
    public function comments() {
        return $this->hasMany(Comment::class);
    }
}
```""",
        """```php
Route::middleware('auth')->get('/profile', function () {
    return response()->json(['ok' => true]);
});
```""",
    ],
    "firebase_fundamentals": [
        """```text
App -> Firebase Auth -> Realtime DB -> UI update
      -> Cloud Functions (xu ly su kien)
```""",
        """```dart
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```""",
        """```dart
final ref = FirebaseDatabase.instance.ref('users/$uid/progress');
await ref.set({'lesson': 'fb001', 'done': true});
```""",
        """```dart
final snapshot = await FirebaseFirestore.instance
    .collection('lessons')
    .where('courseId', isEqualTo: 'firebase_fundamentals')
    .get();
```""",
        """```js
exports.onAttemptCreated = onValueCreated('/attempts/{id}', async (event) => {
  // cap nhat thong ke diem
});
```""",
    ],
    "php_basics": [
        """```php
<?php
$name = "Phuc";
echo "Xin chao, $name";
```""",
        """```php
function sum($a, $b) {
  return $a + $b;
}
echo sum(2, 3);
```""",
        """```php
$email = filter_input(INPUT_POST, 'email', FILTER_SANITIZE_EMAIL);
if (!$email) {
  echo "Email khong hop le";
}
```""",
        """```php
session_start();
$_SESSION['user_id'] = 123;
echo $_SESSION['user_id'];
```""",
        """```php
$pdo = new PDO($dsn, $user, $pass);
$stmt = $pdo->prepare('SELECT * FROM notes WHERE user_id = ?');
$stmt->execute([$userId]);
```""",
    ],
    "python_basics": [
        """```python
name = "Phuc"
score = 8.5
print(f"{name}: {score}")
```""",
        """```python
for i in range(1, 4):
    if i % 2 == 0:
        print("chan", i)
```""",
        """```python
def greet(name="ban"):
    return f"Xin chao {name}"

print(greet("Phuc"))
```""",
        """```python
attempts = [5, 7, 9]
passed = [s for s in attempts if s >= 7]
print(passed)
```""",
        """```python
try:
    with open("data.txt", "r", encoding="utf-8") as f:
        print(f.read())
except FileNotFoundError:
    print("Khong tim thay file")
```""",
    ],
    "java_core": [
        """```java
public class Main {
  public static void main(String[] args) {
    System.out.println("Hello Java");
  }
}
```""",
        """```java
interface Payment { void pay(double amount); }
class CardPayment implements Payment {
  public void pay(double amount) { System.out.println(amount); }
}
```""",
        """```java
Map<String, Integer> scores = new HashMap<>();
scores.put("u1", 8);
System.out.println(scores.get("u1"));
```""",
        """```java
try {
  int x = Integer.parseInt("abc");
} catch (NumberFormatException e) {
  System.out.println("Du lieu khong hop le");
}
```""",
        """```java
List<Integer> top = scores.values().stream()
    .filter(s -> s >= 8)
    .toList();
```""",
    ],
    "sql_fundamentals": [
        """```sql
SELECT name, score
FROM leaderboard
WHERE level = 'easy'
ORDER BY score DESC
LIMIT 10;
```""",
        """```sql
SELECT u.name, AVG(a.score) AS avg_score
FROM users u
JOIN attempts a ON a.user_id = u.id
GROUP BY u.name;
```""",
        """```sql
CREATE TABLE lessons (
  id VARCHAR(32) PRIMARY KEY,
  title VARCHAR(200) NOT NULL
);
```""",
        """```sql
UPDATE attempts
SET score = 10
WHERE id = 'attempt_001';
```""",
        """```sql
CREATE INDEX idx_attempts_course ON attempts(course_id);
```""",
    ],
}


def build_theory(course_title, lesson_title, lesson_content, detail):
    objectives = "\n".join(f"- {item}" for item in detail["objectives"])
    return (
        f"## Khai niem\n"
        f"{lesson_title} trong khoa {course_title} tap trung vao: {lesson_content}. "
        f"No giai thich ro {detail['core']} de ban hieu dung ban chat van de.\n\n"
        f"## Dac diem\n"
        f"{objectives}\n\n"
        f"## Vi du\n"
        f"Ban co the ap dung theo luong: doc ly thuyet -> code nhanh -> kiem tra ket qua.\n\n"
        f"## Bai tap thuc hanh\n"
        f"{detail['practice']}\n\n"
        f"## Loi thuong gap\n"
        f"- Bo qua validate input va edge-case.\n"
        f"- Copy code mau nhung khong hieu luong chay.\n"
        f"- Khong test voi ca du lieu dung va du lieu sai.\n\n"
        f"## Tu kiem tra\n"
        f"Neu ban giai thich duoc vi sao code chay dung va debug duoc mot case loi, bai hoc da dat yeu cau."
    )


def validate_theory_quality(theory_text):
    return (
        len(theory_text) >= 700
        and theory_text.count("## ") >= 6
        and "Khai niem" in theory_text
        and "Dac diem" in theory_text
        and "Vi du" in theory_text
        and "Vi du code ngan" in theory_text
    )


def build_theory_with_snippet(course_id, course_title, lesson_title, lesson_content, detail, order):
    base_theory = build_theory(course_title, lesson_title, lesson_content, detail)
    snippet = SNIPPET_BLUEPRINT[course_id][order - 1]
    return f"{base_theory}\n\n## Vi du code ngan\n{snippet}"


def lesson_questions(course_title, lesson_title):
    return [
        {
            "q": f"Main goal of '{lesson_title}' in {course_title} is?",
            "opts": ["UI animation", "Core backend/topic understanding", "Cloud billing", "Hardware setup"],
            "ans": 1,
        },
        {
            "q": "Best learning approach for this lesson is?",
            "opts": ["Read theory then code examples", "Skip theory", "Only memorize syntax", "Ignore practice"],
            "ans": 0,
        },
        {
            "q": "Which activity improves retention the most?",
            "opts": ["Write and run small exercises", "Only watch videos", "Copy without understanding", "Do nothing"],
            "ans": 0,
        },
        {
            "q": "After this lesson, student should be able to?",
            "opts": ["Apply concept in mini task", "Design a game engine", "Build an OS", "Skip debugging"],
            "ans": 0,
        },
        {
            "q": "How to validate understanding quickly?",
            "opts": ["Solve short quiz and explain answer", "Avoid questions", "Random guess only", "Close lesson"],
            "ans": 0,
        },
    ]


def final_questions(course_title):
    return [
        {"q": f"{course_title}: Which mindset helps most for long term progress?", "opts": ["Practice regularly", "Avoid exercises", "Memorize only", "Skip review"], "ans": 0},
        {"q": "What should be done after each chapter?", "opts": ["Take a short quiz", "Ignore concepts", "Delete notes", "Start random topic"], "ans": 0},
        {"q": "Best way to improve debugging skill is?", "opts": ["Read errors and test incrementally", "Guess blindly", "Never run code", "Disable logs"], "ans": 0},
        {"q": "Why use version control while learning projects?", "opts": ["Track progress and rollback", "Increase bugs", "Hide code", "Avoid teamwork"], "ans": 0},
        {"q": "What is a good mini project strategy?", "opts": ["Build feature by feature", "Write everything once", "Skip plan", "Do no testing"], "ans": 0},
        {"q": "How to keep code quality stable?", "opts": ["Refactor and test often", "Ignore warnings", "Duplicate all code", "Skip naming rules"], "ans": 0},
        {"q": "When should documentation be updated?", "opts": ["When behavior changes", "Never", "Only at release end", "Only by admin"], "ans": 0},
        {"q": "What is a healthy way to learn new APIs?", "opts": ["Read docs + build tiny sample", "Copy random snippet only", "Avoid experiments", "Rely on memory"], "ans": 0},
        {"q": "How do you measure actual understanding?", "opts": ["Explain and implement without copy", "Recognize keywords only", "Read title", "Skip exercises"], "ans": 0},
        {"q": "Final step before moving to next course is?", "opts": ["Review weak areas and retry quiz", "Forget old topic", "Delete project", "Skip feedback"], "ans": 0},
    ]


data = json.loads(path.read_text(encoding="utf-8"))
courses = data.setdefault("courses", {})
lessons = data.setdefault("lessons", {})
quizzes = data.setdefault("quizzes", {})

new_courses = {}
new_lessons = {}
new_quizzes = {}

for course_id, spec in COURSE_BLUEPRINT.items():
    new_courses[course_id] = {
        "id": course_id,
        "title": spec["title"],
        "desc": spec["desc"],
        "description": spec["desc"],
        "level": spec["level"],
        "finalQuiz": spec["finalQuiz"],
    }

    for order, (lesson_title, lesson_content) in enumerate(spec["lessons"], start=1):
        lesson_id = f"lesson_{spec['prefix']}{order:03d}"
        quiz_id = f"quiz_{spec['prefix']}{order:03d}"
        theory_detail = THEORY_BLUEPRINT[course_id][order - 1]
        theory_text = build_theory_with_snippet(
            course_id=course_id,
            course_title=spec["title"],
            lesson_title=lesson_title,
            lesson_content=lesson_content,
            detail=theory_detail,
            order=order,
        )

        new_lessons[lesson_id] = {
            "id": lesson_id,
            "course": course_id,
            "courseId": course_id,
            "title": lesson_title,
            "order": order,
            "content": lesson_content,
            "theory": theory_text,
            "quiz": quiz_id,
            "quizId": quiz_id,
        }

        new_quizzes[quiz_id] = build_quiz(
            quiz_id=quiz_id,
            title=f"Quiz: {lesson_title}",
            course_id=course_id,
            lesson_id=lesson_id,
            questions=lesson_questions(spec["title"], lesson_title),
        )

    new_quizzes[spec["finalQuiz"]] = build_quiz(
        quiz_id=spec["finalQuiz"],
        title=f"Final Quiz: {spec['title']}",
        course_id=course_id,
        lesson_id="",
        questions=final_questions(spec["title"]),
    )

courses.update(new_courses)
lessons.update(new_lessons)
quizzes.update(new_quizzes)

errors = []
for course_id, spec in COURSE_BLUEPRINT.items():
    course_lessons = [
        lesson for lesson in lessons.values() if lesson.get("courseId") == course_id or lesson.get("course") == course_id
    ]
    if len(course_lessons) < 5:
        errors.append(f"{course_id}: expected >= 5 lessons, found {len(course_lessons)}")

    for lesson in course_lessons:
        quiz_id = lesson.get("quizId") or lesson.get("quiz")
        if not quiz_id or quiz_id not in quizzes:
            errors.append(f"{course_id}: missing lesson quiz for {lesson.get('id')}")
        theory_text = lesson.get("theory", "")
        if not validate_theory_quality(theory_text):
            errors.append(f"{course_id}: theory content too short or incomplete in {lesson.get('id')}")

    final_quiz_id = spec["finalQuiz"]
    final_quiz = quizzes.get(final_quiz_id)
    if not final_quiz:
        errors.append(f"{course_id}: missing final quiz {final_quiz_id}")
    else:
        question_count = sum(1 for key in final_quiz if key.startswith("q") and key[1:].isdigit())
        if question_count < 10:
            errors.append(f"{course_id}: final quiz {final_quiz_id} has {question_count} questions (need >= 10)")

if errors:
    raise SystemExit("\n".join(errors))

path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print(f"Updated: {path}")
print(f"courses={len(courses)} lessons={len(lessons)} quizzes={len(quizzes)}")
for course_id, spec in COURSE_BLUEPRINT.items():
    course_lessons = [
        lesson for lesson in lessons.values() if lesson.get("courseId") == course_id or lesson.get("course") == course_id
    ]
    final_quiz = quizzes[spec["finalQuiz"]]
    final_count = sum(1 for key in final_quiz if key.startswith("q") and key[1:].isdigit())
    print(f"- {course_id}: lessons={len(course_lessons)} final_questions={final_count}")


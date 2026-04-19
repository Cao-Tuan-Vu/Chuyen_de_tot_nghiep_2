# BTL - Ung dung hoc lap trinh co ban

Project Flutter + Firebase + Gemini (planned), trien khai theo roadmap.

## Trang thai hien tai

- Week 1: da co requirements, wireframe text, data model, RBAC, API contract, Firebase setup docs.
- Week 2: da dung skeleton Flutter app + CI Flutter.
- Week 3: da co auth/login/register, profile update, role-based UI (admin/student).
- Week 4-5: da co Course/Lesson + Quiz + Admin CMS co ban.

## Cau truc chinh

- `lib/`: Flutter app (auth/home/profile/admin).
- `docs/week1/`: tai lieu chot scope/contract/model.
- `.github/workflows/`: CI cho Flutter.
- `firebase.json`, `.firebaserc`, `database.rules.json`: cau hinh Firebase ban dau.

## Chay nhanh mot lenh (Windows PowerShell)

```powershell
cd "C:\path\to\BTL"
powershell -ExecutionPolicy Bypass -File .\scripts\start-dev.ps1
```

Script se:

1. Chay `flutter pub get`
2. Chay `flutter run`

## Chay thu cong

```powershell
cd "C:\path\to\BTL"
flutter pub get
flutter run
```

## Route guard (admin)

- Chua dang nhap -> moi route deu redirect ve `LoginPage`.
- Dang nhap role `admin` -> redirect vao `AdminPage` (luong quan tri rieng).
- Dang nhap role `student` -> khong vao duoc route admin.

## Firebase project

Dang su dung project `news-app-6ef88` (Realtime Database khu vuc `asia-southeast1`).
Chi tiet xem trong `docs/week1/firebase_setup.md`.

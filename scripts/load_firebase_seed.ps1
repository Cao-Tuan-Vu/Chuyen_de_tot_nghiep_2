# Script để nạp dữ liệu mẫu vào Firebase Realtime Database
# Điều kiện tiên quyết: Cần có Node.js và Firebase CLI cài đặt

# 1. Cài đặt Firebase CLI nếu chưa có
Write-Host "Kiểm tra Firebase CLI..." -ForegroundColor Green
firebase --version

# 2. Đăng nhập Firebase
Write-Host "`nĐăng nhập Firebase..." -ForegroundColor Green
firebase login --no-localhost

# 3. Chọn project Firebase
Write-Host "`nChọn project Firebase của bạn:" -ForegroundColor Green
firebase projects:list

# 4. Nạp dữ liệu vào Realtime Database
Write-Host "`nNạp dữ liệu mẫu vào Firebase..." -ForegroundColor Green

# Tạo file config tạm để set dữ liệu
$firebaseConfig = @{
    "project" = "btl-app-db"  # Thay bằng project ID của bạn
} | ConvertTo-Json

# Sử dụng Firebase Import để nạp dữ liệu
# Phương pháp 1: Sử dụng Firebase Admin SDK

Write-Host @"
Hướng dẫn nạp dữ liệu theo cách thủ công:

1. Truy cập Firebase Console: https://console.firebase.google.com/
2. Chọn project của bạn: BTL
3. Chọn Realtime Database -> Import JSON
4. Chọn file: docs/week1/firebase_seed.json
5. Nhấp Import

HOẶC sử dụng Firebase Admin SDK qua Node.js:

const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://your-project.firebaseio.com'
});

const db = admin.database();
const seedData = require('./docs/week1/firebase_seed.json');

// Nạp dữ liệu
db.ref().set(seedData).then(() => {
  console.log('Dữ liệu đã được nạp thành công!');
}).catch((error) => {
  console.error('Lỗi khi nạp dữ liệu:', error);
});
"@ -ForegroundColor Cyan

Write-Host "`n✅ Script hoàn thành!" -ForegroundColor Green


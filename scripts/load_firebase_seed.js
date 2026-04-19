/**
 * Script nạp dữ liệu seed vào Firebase Realtime Database
 * Cách sử dụng:
 * 1. Cài đặt: npm install firebase-admin dotenv
 * 2. Đặt file serviceAccountKey.json trong thư mục gốc
 * 3. Chạy: node scripts/load_firebase_seed.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Hàm kiểm tra file
function checkFile(filePath) {
  if (!fs.existsSync(filePath)) {
    console.error(`❌ File không tìm thấy: ${filePath}`);
    process.exit(1);
  }
}

// Khởi tạo Firebase Admin SDK
try {
  const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    './serviceAccountKey.json';

  checkFile(serviceAccountPath);

  const serviceAccount = require(path.resolve(serviceAccountPath));

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.DATABASE_URL || 'https://btl-app-db-default-rtdb.firebaseio.com'
  });

  console.log('✅ Firebase Admin SDK đã khởi tạo thành công');
} catch (error) {
  console.error('❌ Lỗi khởi tạo Firebase:', error.message);
  process.exit(1);
}

// Tải dữ liệu seed JSON
async function loadSeedData() {
  try {
    const seedDataPath = path.join(__dirname, '../docs/week1/firebase_seed.json');
    checkFile(seedDataPath);

    const seedData = require(seedDataPath);
    const db = admin.database();

    console.log('📤 Đang nạp dữ liệu vào Firebase...');

    // Nạp từng section
    const sections = Object.keys(seedData);

    for (const section of sections) {
      console.log(`   📝 Nạp ${section}...`);
      await db.ref(section).set(seedData[section]);
    }

    console.log('\n✅ Dữ liệu đã được nạp thành công!');
    console.log('\n📊 Tóm tắt dữ liệu đã nạp:');
    console.log(`   - Khóa học: ${Object.keys(seedData.courses || {}).length}`);
    console.log(`   - Bài học: ${Object.keys(seedData.lessons || {}).length}`);
    console.log(`   - Quiz: ${Object.keys(seedData.quizzes || {}).length}`);
    console.log(`   - Người dùng: ${Object.keys(seedData.users || {}).length}`);

  } catch (error) {
    console.error('❌ Lỗi nạp dữ liệu:', error.message);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

// Chạy
loadSeedData();


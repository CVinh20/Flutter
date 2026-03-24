// Script to clear all stylists from database
const { MongoClient } = require('mongodb');

const MONGODB_URI = 'mongodb+srv://lionjoki123:BaiFQNr0eYVqz8Eh@gentlemangrooming.0y3io.mongodb.net/grooming_db?retryWrites=true&w=majority&appName=GentlemanGrooming';

async function clearStylists() {
  const client = new MongoClient(MONGODB_URI);
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db('grooming_db');
    const stylistsCollection = db.collection('stylists');
    
    // Xóa tất cả stylists
    const result = await stylistsCollection.deleteMany({});
    console.log(`🗑️  Đã xóa ${result.deletedCount} stylists`);
    
    // Xóa cả users có role stylist (optional)
    const usersCollection = db.collection('users');
    const userResult = await usersCollection.deleteMany({ role: 'stylist' });
    console.log(`🗑️  Đã xóa ${userResult.deletedCount} user accounts với role stylist`);
    
    console.log('✅ Hoàn thành! Database đã được làm sạch.');
  } catch (error) {
    console.error('❌ Lỗi:', error);
  } finally {
    await client.close();
    console.log('👋 Đã đóng kết nối');
  }
}

clearStylists();

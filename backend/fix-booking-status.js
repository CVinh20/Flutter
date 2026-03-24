// Script to fix booking status
const mongoose = require('mongoose');
require('dotenv').config();

async function fixBookingStatus() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const db = mongoose.connection.db;
    const bookingsCollection = db.collection('bookings');

    // Update all bookings with status "Hoàn tất" or "Hoàn thành" but serviceStatus != "completed"
    // Reset them to "in_progress" (because they are checked in but not completed)
    const result1 = await bookingsCollection.updateMany(
      { 
        status: { $in: ['Hoàn tất', 'Hoàn thành'] },
        serviceStatus: { $in: ['in_progress', null] },
        checkInTime: { $ne: null }
      },
      { 
        $set: { status: 'in_progress' }
      }
    );

    console.log(`✅ Updated ${result1.modifiedCount} bookings to "in_progress" (checked in but not completed)`);

    // Update all bookings with status "Đang thực hiện" but no checkInTime
    // Reset them to "Đã xác nhận"
    const result2 = await bookingsCollection.updateMany(
      { 
        status: 'Đang thực hiện',
        checkInTime: null
      },
      { 
        $set: { status: 'Đã xác nhận' }
      }
    );

    console.log(`✅ Updated ${result2.modifiedCount} bookings from "Đang thực hiện" to "Đã xác nhận" (no check-in)`);

    // Show all bookings status
    const allBookings = await bookingsCollection.find({}).toArray();
    console.log('\n📋 Current booking statuses:');
    allBookings.forEach(booking => {
      console.log(`- ${booking.customerName}: status="${booking.status}", serviceStatus="${booking.serviceStatus || 'N/A'}", checkIn=${booking.checkInTime ? 'Yes' : 'No'}`);
    });

    await mongoose.connection.close();
    console.log('\n✅ Done!');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

fixBookingStatus();

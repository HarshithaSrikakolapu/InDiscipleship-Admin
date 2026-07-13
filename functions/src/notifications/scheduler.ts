import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { NotificationService } from './notification_service';
import { SCHEDULE_FREQUENCY } from '../utils';

export const processScheduledNotifications = functions.pubsub
  .schedule(SCHEDULE_FREQUENCY)
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    
    // Convert to Date for easy extraction of current hour, minute, day in IST (UTC+5:30)
    const nowDate = now.toDate();
    // Add 5 hours and 30 minutes to UTC to get IST
    nowDate.setUTCHours(nowDate.getUTCHours() + 5);
    nowDate.setUTCMinutes(nowDate.getUTCMinutes() + 30);
    
    const currentHour = nowDate.getUTCHours();
    const currentMinute = nowDate.getUTCMinutes();
    const currentDayOfWeek = nowDate.getUTCDay() === 0 ? 7 : nowDate.getUTCDay(); // Convert Sun=0 to Sun=7
    
    const timeString = `${currentHour.toString().padStart(2, '0')}:${currentMinute.toString().padStart(2, '0')}`;

    console.log(`Scheduler running at ${timeString} UTC, Day ${currentDayOfWeek}`);

    // Process One-time Scheduled Broadcast Notifications
    const scheduledSnapshot = await db.collection('notifications')
      .where('status', '==', 'scheduled')
      .where('scheduledAt', '<=', now)
      .get();
      
    const allDocs = scheduledSnapshot.docs;

    if (allDocs.length === 0) {
      console.log('No broadcast notifications to process at this time.');
      return null;
    }

    console.log(`Found ${allDocs.length} scheduled broadcasts to process.`);

    const processingPromises = allDocs.map(doc => {
      const data = doc.data();
      return NotificationService.processNotification(doc.id, data);
    });

    await Promise.all(processingPromises);
    
    return null;
  });

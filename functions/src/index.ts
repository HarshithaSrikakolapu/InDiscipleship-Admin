import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { NotificationService } from './notifications/notification_service';

// Initialize the Firebase Admin SDK once here
admin.initializeApp();

// Export the scheduler function
export { processScheduledNotifications } from './notifications/scheduler';

// Firestore trigger to process immediate/broadcast notifications when status is 'sending'
export const onNotificationWrite = functions.firestore
  .document('notifications/{notificationId}')
  .onWrite(async (change, context) => {
    const data = change.after.exists ? change.after.data() : null;
    if (!data) return;

    if (data.status === 'sending') {
      await NotificationService.processNotification(context.params.notificationId, data);
    }
  });

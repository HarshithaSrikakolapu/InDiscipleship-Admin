import * as admin from 'firebase-admin';
import { TokenManager } from './token_manager';
import { chunkArray } from '../utils';

export class NotificationService {
  /**
   * Dispatches a notification document to its target users.
   */
  static async processNotification(docId: string, data: any): Promise<void> {
    const db = admin.firestore();
    const notificationRef = db.collection('notifications').doc(docId);
    
    // Safety check again inside processing
    if (data.status === 'sent' || data.isCancelled) {
      console.log(`Notification ${docId} already sent or cancelled. Skipping.`);
      return;
    }

    try {
      console.log(`Processing notification: ${docId}`);
      
      const targetType = data.targetType || 'all';
      const targetValues = data.targetValues || [];
      
      const userTokens = await TokenManager.getTokensForTarget(targetType, targetValues);
      
      const deliveryMethod = data.delivery || data.notificationType || '';

      if (userTokens.length === 0) {
        console.log(`No tokens found for notification ${docId}. Marking as sent/completed.`);
        await this.markAsSent(notificationRef, deliveryMethod, 0, 0, 0);
        return;
      }

      // FCM Multicast limit is 500
      const tokenChunks = chunkArray(userTokens, 500);
      let successCount = 0;
      let failureCount = 0;
      const invalidTokens: { uid: string; token: string }[] = [];

      for (const chunk of tokenChunks) {
        const tokens = chunk.map(c => c.token);
        const payload: admin.messaging.MulticastMessage = {
          tokens: tokens,
          notification: {
            title: data.title,
            body: data.message,
            imageUrl: data.imageUrl || undefined,
          },
          data: {
            deepLink: data.deepLink || '',
            notificationId: docId,
            delivery: deliveryMethod,
          }
        };

        const response = await admin.messaging().sendEachForMulticast(payload);
        
        successCount += response.successCount;
        failureCount += response.failureCount;

        if (response.failureCount > 0) {
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const errorCode = resp.error?.code;
              // Token cleanup logic
              if (
                errorCode === 'messaging/invalid-registration-token' ||
                errorCode === 'messaging/registration-token-not-registered'
              ) {
                invalidTokens.push(chunk[idx]);
              }
            }
          });
        }
      }

      // Cleanup invalid tokens found during this send
      if (invalidTokens.length > 0) {
        console.log(`Cleaning up ${invalidTokens.length} invalid tokens.`);
        await TokenManager.cleanupInvalidTokens(invalidTokens);
      }

      console.log(`Successfully dispatched notification ${docId}. Success: ${successCount}, Failed: ${failureCount}`);
      await this.markAsSent(notificationRef, deliveryMethod, successCount + failureCount, successCount, failureCount, invalidTokens.length);

    } catch (error) {
      console.error(`Failed to process notification ${docId}:`, error);
      await this.handleRetry(notificationRef, data);
    }
  }

  private static async markAsSent(
    ref: admin.firestore.DocumentReference, 
    deliveryMethod: string, 
    totalRecipients: number, 
    successful: number, 
    failed: number,
    invalidTokensCount: number = 0
  ) {
    const isRecurring = deliveryMethod === 'dailyReminder' || deliveryMethod === 'weeklyReminder';
    
    // For recurring, we don't change status to 'sent' because it needs to run again next time.
    // Instead, we just update the stats.
    const updates: any = {
      totalRecipients,
      delivered: successful,
      failed,
      invalidTokens: invalidTokensCount,
      completedAt: admin.firestore.Timestamp.now(),
      lastRetry: null,
      retryCount: 0 // reset retries
    };

    if (!isRecurring) {
      updates.status = 'sent';
      updates.sentAt = admin.firestore.Timestamp.now();
    }

    await ref.update(updates);
  }

  private static async handleRetry(ref: admin.firestore.DocumentReference, data: any) {
    const currentRetries = data.retryCount || 0;
    const maxRetries = data.maxRetries || 3;

    if (currentRetries < maxRetries) {
      console.log(`Retrying notification ${ref.id}. Attempt ${currentRetries + 1} of ${maxRetries}`);
      await ref.update({
        retryCount: currentRetries + 1,
        lastRetry: admin.firestore.Timestamp.now(),
        status: 'scheduled' // Keep it scheduled to be picked up again
      });
    } else {
      console.error(`Notification ${ref.id} reached max retries. Marking as failed.`);
      await ref.update({
        status: 'failed',
        failedAt: admin.firestore.Timestamp.now()
      });
    }
  }
}

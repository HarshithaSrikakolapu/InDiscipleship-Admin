import * as admin from 'firebase-admin';

export class TokenManager {
  /**
   * Fetches FCM tokens for the given users based on targetType and targetValues.
   */
  static async getTokensForTarget(targetType: string, targetValues: string[]): Promise<{ uid: string; token: string }[]> {
    const db = admin.firestore();
    let query: admin.firestore.Query = db.collection('users');

    // Normalize targetType
    let normalizedTarget = targetType;
    if (targetType === 'SELECTED_USERS' || targetType === 'selectedUsers') {
      normalizedTarget = 'selectedUsers';
    } else if (targetType === 'SELECTED_COUNTRY' || targetType === 'selectedCountry') {
      normalizedTarget = 'selectedCountry';
    } else if (targetType === 'SELECTED_LANGUAGE' || targetType === 'selectedLanguage') {
      normalizedTarget = 'selectedLanguage';
    } else if (targetType === 'MENTORS_ONLY' || targetType === 'mentorsOnly') {
      normalizedTarget = 'mentorsOnly';
    } else if (targetType === 'ALL' || targetType === 'all') {
      normalizedTarget = 'all';
    }

    if (normalizedTarget === 'selectedUsers' && targetValues.length > 0) {
      // Fetch only for selected UIDs. We handle this in chunks to avoid Firestore limits on 'in'.
      const uids = targetValues;
      const tokens: { uid: string; token: string }[] = [];
      
      // Firestore 'in' query limit is 30.
      for (let i = 0; i < uids.length; i += 30) {
        const chunk = uids.slice(i, i + 30);
        const snapshot = await db.collection('users').where(admin.firestore.FieldPath.documentId(), 'in', chunk).get();
        snapshot.docs.forEach(doc => {
          this.extractTokensFromUserDoc(doc, tokens);
        });
      }
      return tokens;
    }

    if (targetType === 'selectedCountry' && targetValues.length > 0) {
      query = query.where('country', 'in', targetValues);
    } else if (targetType === 'selectedLanguage' && targetValues.length > 0) {
      query = query.where('language', 'in', targetValues);
    } else if (targetType === 'mentorsOnly') {
      query = query.where('isMentor', '==', true);
    }
    // 'all' target uses the default query without filters

    const snapshot = await query.get();
    const tokens: { uid: string; token: string }[] = [];
    snapshot.docs.forEach(doc => {
      this.extractTokensFromUserDoc(doc, tokens);
    });

    return tokens;
  }

  private static extractTokensFromUserDoc(doc: admin.firestore.QueryDocumentSnapshot, tokensArray: { uid: string; token: string }[]) {
    const data = doc.data();
    // Support multiple FCM tokens per user (fcmTokens array) or fallback to single string (fcmToken)
    let userTokens: string[] = [];
    if (Array.isArray(data.fcmTokens)) {
      userTokens = data.fcmTokens;
    } else if (typeof data.fcmToken === 'string' && data.fcmToken.trim().length > 0) {
      userTokens = [data.fcmToken];
    }
    
    for (const t of userTokens) {
      if (t) {
        tokensArray.push({ uid: doc.id, token: t });
      }
    }
  }

  /**
   * Cleans up invalid tokens by removing them from the user's document.
   */
  static async cleanupInvalidTokens(invalidTokens: { uid: string; token: string }[]) {
    if (invalidTokens.length === 0) return;
    
    const db = admin.firestore();
    const batch = db.batch();
    let batchCount = 0;

    for (const item of invalidTokens) {
      const userRef = db.collection('users').doc(item.uid);
      
      // Use arrayRemove to safely remove the specific invalid token from fcmTokens
      batch.update(userRef, {
        fcmTokens: admin.firestore.FieldValue.arrayRemove(item.token)
      });
      batchCount++;

      // Batch limit is 500
      if (batchCount === 500) {
        await batch.commit();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }
  }
}

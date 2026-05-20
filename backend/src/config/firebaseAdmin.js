import admin from 'firebase-admin'
import { firebaseConfig, isFirebaseConfigured } from './env.js'

let app = null

export function getFirebaseAdmin () {
  if (!isFirebaseConfigured()) {
    return null
  }

  if (!app) {
    if (!admin.apps.length) {
      app = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: firebaseConfig.projectId,
          clientEmail: firebaseConfig.clientEmail,
          privateKey: firebaseConfig.privateKey
        })
      })
    } else {
      app = admin.app()
    }
  }

  return app
}

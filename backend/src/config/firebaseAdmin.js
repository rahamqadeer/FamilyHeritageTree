import admin from 'firebase-admin'
import { firebaseConfig } from './env.js'

let app

if (!admin.apps.length) {
  if (!firebaseConfig.projectId || !firebaseConfig.clientEmail || !firebaseConfig.privateKey) {
    throw new Error('Firebase admin credentials are not fully configured')
  }

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

export const firebaseAdmin = app

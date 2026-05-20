import jwt from 'jsonwebtoken'
import { getFirebaseAdmin } from '../config/firebaseAdmin.js'
import { appConfig, isFirebaseConfigured } from '../config/env.js'
import { supabaseAdmin } from '../config/supabaseClient.js'

// This middleware expects either:
// - A Firebase ID token in Authorization: Bearer <token>
// - Or an internal JWT issued by this API that wraps a Firebase user

export async function authMiddleware (req, res, next) {
  try {
    const authHeader = req.headers.authorization || ''
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null

    if (!token) {
      return res.status(401).json({ message: 'Missing Authorization token' })
    }

    if (!isFirebaseConfigured()) {
      return res.status(503).json({
        message:
          'Firebase Admin is not configured. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY in .env, or set FIREBASE_SERVICE_ACCOUNT_PATH to your service account JSON file.'
      })
    }

    const firebaseAdmin = getFirebaseAdmin()
    if (!firebaseAdmin) {
      return res.status(503).json({ message: 'Firebase Admin failed to initialize' })
    }

    let firebaseUser
    let internalPayload

    try {
      // Try verify as Firebase ID token
      firebaseUser = await firebaseAdmin.auth().verifyIdToken(token)
    } catch (err) {
      // Fallback: verify as internal JWT
      try {
        internalPayload = jwt.verify(token, appConfig.jwtSecret)
        firebaseUser = internalPayload.firebaseUser
      } catch {
        return res.status(401).json({ message: 'Invalid or expired token' })
      }
    }

    // Ensure local user record exists in Supabase
    const { data: existingUser, error } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('firebase_uid', firebaseUser.uid)
      .single()

    if (error && error.code !== 'PGRST116') {
      console.error('Error fetching user', error)
      return res.status(500).json({ message: 'Failed to resolve user' })
    }

    let user = existingUser

    if (!existingUser) {
      const { data: inserted, error: insertError } = await supabaseAdmin
        .from('users')
        .insert({
          firebase_uid: firebaseUser.uid,
          email: firebaseUser.email,
          display_name: firebaseUser.name || firebaseUser.email
        })
        .select('*')
        .single()

      if (insertError) {
        console.error('Error creating user', insertError)
        return res.status(500).json({ message: 'Failed to create user' })
      }

      user = inserted
    }

    req.auth = {
      firebaseUser,
      user
    }

    next()
  } catch (err) {
    console.error('Auth middleware error', err)
    return res.status(500).json({ message: 'Authentication failed' })
  }
}

// Issues a short-lived internal JWT after Firebase login if the client prefers
export function issueInternalJwt (firebaseUser, user) {
  const payload = {
    sub: user.id,
    firebaseUid: firebaseUser.uid,
    firebaseUser: {
      uid: firebaseUser.uid,
      email: firebaseUser.email
    }
  }

  return jwt.sign(payload, appConfig.jwtSecret, { expiresIn: '12h' })
}

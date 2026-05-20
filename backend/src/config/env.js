import dotenv from 'dotenv'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const projectRootEnvPath = path.resolve(__dirname, '../../../.env')
const backendEnvPath = path.resolve(__dirname, '../../.env')

dotenv.config({ path: projectRootEnvPath })
dotenv.config({ path: backendEnvPath })
dotenv.config()

function loadFirebaseFromServiceAccountFile () {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH
  if (!serviceAccountPath) return null

  const resolvedPath = path.isAbsolute(serviceAccountPath)
    ? serviceAccountPath
    : path.resolve(process.cwd(), serviceAccountPath)

  if (!fs.existsSync(resolvedPath)) {
    console.warn(`FIREBASE_SERVICE_ACCOUNT_PATH not found: ${resolvedPath}`)
    return null
  }

  const json = JSON.parse(fs.readFileSync(resolvedPath, 'utf8'))
  return {
    projectId: json.project_id,
    clientEmail: json.client_email,
    privateKey: json.private_key
  }
}

const firebaseFromFile = loadFirebaseFromServiceAccountFile()

export const appConfig = {
  port: process.env.PORT || 4000,
  nodeEnv: process.env.NODE_ENV || 'development',
  jwtSecret: process.env.JWT_SECRET || 'change-this-secret-in-production',
  clientBaseUrl: process.env.CLIENT_BASE_URL || 'http://localhost:8080'
}

export const firebaseConfig = {
  projectId: process.env.FIREBASE_PROJECT_ID || firebaseFromFile?.projectId,
  clientEmail: process.env.FIREBASE_CLIENT_EMAIL || firebaseFromFile?.clientEmail,
  privateKey: process.env.FIREBASE_PRIVATE_KEY
    ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
    : firebaseFromFile?.privateKey
}

export function isFirebaseConfigured () {
  return Boolean(
    firebaseConfig.projectId &&
    firebaseConfig.clientEmail &&
    firebaseConfig.privateKey
  )
}

export const supabaseConfig = {
  url: process.env.SUPABASE_URL,
  anonKey: process.env.SUPABASE_ANON_KEY,
  serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  postgresConnectionString: process.env.SUPABASE_POSTGRES_CONNECTION_STRING
}

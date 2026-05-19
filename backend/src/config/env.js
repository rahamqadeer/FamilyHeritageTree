import dotenv from 'dotenv'

dotenv.config()

export const appConfig = {
  port: process.env.PORT || 4000,
  nodeEnv: process.env.NODE_ENV || 'development',
  jwtSecret: process.env.JWT_SECRET || 'change-this-secret-in-production',
  clientBaseUrl: process.env.CLIENT_BASE_URL || 'http://localhost:8080'
}

export const supabaseConfig = {
  url: process.env.SUPABASE_URL,
  anonKey: process.env.SUPABASE_ANON_KEY,
  serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  postgresConnectionString: process.env.SUPABASE_POSTGRES_CONNECTION_STRING
}

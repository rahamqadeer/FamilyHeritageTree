import { createApp } from './app.js'
import { appConfig, isFirebaseConfigured, supabaseConfig } from './config/env.js'
import { initSchema } from './db/initSchema.js'

async function bootstrap () {
  if (!isFirebaseConfigured()) {
    console.warn(
      'Firebase Admin credentials missing. Server will start, but /api routes require Firebase config.'
    )
  }

  if (supabaseConfig.postgresConnectionString) {
    try {
      await initSchema()
    } catch (err) {
      console.error('Schema initialization failed; server will not start.', err)
      process.exit(1)
    }
  } else if (appConfig.nodeEnv === 'development') {
    console.warn(
      'SUPABASE_POSTGRES_CONNECTION_STRING not set; skipping automatic schema init.'
    )
  } else {
    console.error(
      'SUPABASE_POSTGRES_CONNECTION_STRING is required in production to initialize schema.'
    )
    process.exit(1)
  }

  const app = createApp()

  app.listen(appConfig.port, () => {
    console.log(`Family Digital Heritage Vault API listening on port ${appConfig.port}`)
  })
}

bootstrap()

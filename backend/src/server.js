import { createApp } from './app.js'
import { appConfig } from './config/env.js'
import { initSchema } from './db/initSchema.js'

async function bootstrap () {
  try {
    await initSchema()
  } catch (err) {
    console.error('Schema initialization failed; server will not start.', err)
    process.exit(1)
  }

  const app = createApp()

  app.listen(appConfig.port, () => {
    console.log(`Family Digital Heritage Vault API listening on port ${appConfig.port}`)
  })
}

bootstrap()

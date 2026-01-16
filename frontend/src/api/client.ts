import createClient from 'openapi-fetch'
import type { paths } from '../generated/demo/api-types'

export interface ApiClientConfig {
  engineUrl: string
  getToken: () => Promise<string>
}

export function createApiClient(config: ApiClientConfig) {
  const baseUrl = config.engineUrl ? `${config.engineUrl}/npl/demo` : '/npl/demo'
  
  const client = createClient<paths>({
    baseUrl,
  })

  // Add auth middleware
  client.use({
    async onRequest({ request }) {
      const token = await config.getToken()
      request.headers.set('Authorization', `Bearer ${token}`)
      return request
    },
  })

  return client
}

export type ApiClient = ReturnType<typeof createApiClient>

import createClient from 'openapi-fetch'
import type { paths } from '../generated/demo/api-types'

export interface ApiClientConfig {
  engineUrl: string
  getToken: () => Promise<string>
}

export function createApiClient(config: ApiClientConfig) {
  // Note: Don't append /npl/{package} here - the generated OpenAPI paths already include it
  // e.g., paths include '/npl/demo/Iou/' not just '/Iou/'
  const baseUrl = config.engineUrl || ''
  
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

import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  // Load env file from parent directory
  const env = loadEnv(mode, '../', 'VITE_')
  
  return {
    plugins: [react()],
    server: {
      host: '0.0.0.0',
      port: 5173,
      allowedHosts: true,
      proxy: {
        // Proxy OIDC requests to Keycloak
        '/auth': {
          target: env.VITE_KEYCLOAK_URL || 'http://localhost:11000',
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/auth/, `/realms/${env.VITE_KEYCLOAK_REALM || 'demo'}/protocol/openid-connect`),
          secure: false,
        },
        // Proxy NPL Engine requests
        '/npl': {
          target: env.VITE_NPL_ENGINE_URL || 'http://localhost:12000',
          changeOrigin: true,
          secure: false,
        },
      },
    },
    envDir: '../',
  }
})

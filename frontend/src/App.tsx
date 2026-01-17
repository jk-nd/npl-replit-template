import { isDevMode } from './auth/keycloak'
import { OIDCClient } from './auth/oidc-client'
import { OIDCApp } from './components/auth/OIDCApp'
import { KeycloakApp } from './components/auth/KeycloakApp'
import './App.css'

// Check if environment is configured
const isConfigured = 
  import.meta.env.VITE_NPL_ENGINE_URL && 
  !import.meta.env.VITE_NPL_ENGINE_URL.includes('localhost') &&
  import.meta.env.VITE_KEYCLOAK_URL &&
  !import.meta.env.VITE_KEYCLOAK_URL.includes('localhost')

// OIDC client instance for dev mode
let oidcClient: OIDCClient | null = null

if (isDevMode && isConfigured) {
  oidcClient = new OIDCClient({
    url: import.meta.env.VITE_KEYCLOAK_URL,
    realm: import.meta.env.VITE_KEYCLOAK_REALM || 'demo',
    clientId: import.meta.env.VITE_KEYCLOAK_CLIENT_ID || 'frontend'
  })
}

function App() {
  // Show error if not configured
  if (!isConfigured) {
    return (
      <div style={{ 
        display: 'flex', 
        flexDirection: 'column',
        alignItems: 'center', 
        justifyContent: 'center', 
        height: '100vh',
        fontFamily: 'system-ui, sans-serif',
        textAlign: 'center',
        padding: '2rem',
        background: '#1a1a2e',
        color: '#eee'
      }}>
        <h1 style={{ color: '#ff6b6b', marginBottom: '1rem' }}>⚠️ Setup Required</h1>
        <p style={{ fontSize: '1.2rem', marginBottom: '2rem', maxWidth: '500px' }}>
          This project is not configured yet. The environment variables are missing or using localhost defaults.
        </p>
        <div style={{ 
          background: '#0f0f23', 
          padding: '1.5rem 2rem', 
          borderRadius: '8px',
          border: '1px solid #333'
        }}>
          <p style={{ marginBottom: '1rem' }}>Run this command in the terminal:</p>
          <code style={{ 
            background: '#2d2d44', 
            padding: '0.5rem 1rem', 
            borderRadius: '4px',
            fontSize: '1.1rem',
            color: '#7bed9f'
          }}>make setup</code>
        </div>
        <p style={{ marginTop: '2rem', color: '#888', fontSize: '0.9rem' }}>
          This will configure Noumena Cloud connection and prompt for login.
        </p>
      </div>
    )
  }

  if (isDevMode && oidcClient) {
    return <OIDCApp oidcClient={oidcClient} />
  }
  return <KeycloakApp />
}

export default App

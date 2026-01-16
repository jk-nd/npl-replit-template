import { isDevMode } from './auth/keycloak'
import { OIDCClient } from './auth/oidc-client'
import { OIDCApp } from './components/auth/OIDCApp'
import { KeycloakApp } from './components/auth/KeycloakApp'
import './App.css'

// OIDC client instance for dev mode
let oidcClient: OIDCClient | null = null

if (isDevMode) {
  oidcClient = new OIDCClient({
    url: import.meta.env.VITE_KEYCLOAK_URL || 'http://localhost:11000',
    realm: import.meta.env.VITE_KEYCLOAK_REALM || 'demo',
    clientId: import.meta.env.VITE_KEYCLOAK_CLIENT_ID || 'frontend'
  })
}

function App() {
  if (isDevMode && oidcClient) {
    return <OIDCApp oidcClient={oidcClient} />
  }
  return <KeycloakApp />
}

export default App

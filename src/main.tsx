import { ReactKeycloakProvider } from '@react-keycloak/web'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'
import keycloak, { keycloakInit, isDevMode } from './auth/keycloak'

// In dev mode without Keycloak configured, render without auth
if (isDevMode) {
  console.log('🔧 Dev Mode: Keycloak authentication bypassed')
  ReactDOM.createRoot(document.getElementById('root')!).render(<App />)
} else {
  ReactDOM.createRoot(document.getElementById('root')!).render(
    <ReactKeycloakProvider
      authClient={keycloak}
      initOptions={keycloakInit}
      LoadingComponent={<LoadingScreen />}
    >
      <App />
    </ReactKeycloakProvider>
  )
}

function LoadingScreen() {
  return (
    <div className="loading-screen">
      <div className="loading-content">
        <div className="loading-spinner"></div>
        <h2>Connecting to Noumena Cloud...</h2>
        <p>Authenticating with Keycloak</p>
      </div>
    </div>
  )
}

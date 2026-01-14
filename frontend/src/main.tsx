import { ReactKeycloakProvider } from '@react-keycloak/web'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'
import keycloak, { keycloakInit, isDevMode } from './auth/keycloak'

console.log('VITE_DEV_MODE env:', import.meta.env.VITE_DEV_MODE)
console.log('isDevMode:', isDevMode)

if (isDevMode) {
  console.log('🔧 Dev Mode: Using direct OIDC HTTP calls')
  ReactDOM.createRoot(document.getElementById('root')!).render(<App />)
} else {
  console.log('📦 Production Mode: Using Keycloak library')
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

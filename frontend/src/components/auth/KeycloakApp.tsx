import { useKeycloak } from '@react-keycloak/web'
import { LoadingState } from '../shared/LoadingState'
import { LoginPrompt } from './LoginPrompt'
import { Dashboard } from '../dashboard/Dashboard'

export function KeycloakApp() {
  const { keycloak, initialized } = useKeycloak()

  if (!initialized) {
    return <LoadingState message="Initializing..." />
  }

  if (!keycloak.authenticated) {
    return <LoginPrompt onLogin={() => keycloak.login()} />
  }

  return <Dashboard keycloak={keycloak} />
}

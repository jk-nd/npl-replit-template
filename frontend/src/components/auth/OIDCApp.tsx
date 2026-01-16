import { useState, useEffect } from 'react'
import { OIDCClient } from '../../auth/oidc-client'
import { LoadingState } from '../shared/LoadingState'
import { DevLoginForm } from './DevLoginForm'
import { Dashboard } from '../dashboard/Dashboard'

interface OIDCAppProps {
  oidcClient: OIDCClient
}

export function OIDCApp({ oidcClient }: OIDCAppProps) {
  const [initialized, setInitialized] = useState(false)
  const [authenticated, setAuthenticated] = useState(false)
  const [loginError, setLoginError] = useState<string | null>(null)
  const [userInfo, setUserInfo] = useState<{ email: string; preferred_username: string }>({ 
    email: '', 
    preferred_username: '' 
  })

  useEffect(() => {
    const initOIDC = async () => {
      const isAuth = await oidcClient.init()
      setAuthenticated(isAuth)
      setInitialized(true)
    }
    initOIDC()
  }, [oidcClient])

  useEffect(() => {
    const loadUserInfo = async () => {
      if (!authenticated) return
      try {
        const info = await oidcClient.getUserInfo()
        setUserInfo({
          email: info.email || info.preferred_username || 'unknown',
          preferred_username: info.preferred_username || info.email || 'unknown'
        })
      } catch (err) {
        console.error('Failed to load user info:', err)
      }
    }
    loadUserInfo()
  }, [authenticated, oidcClient])

  const handleLogin = async (username: string, password: string) => {
    try {
      setLoginError(null)
      await oidcClient.loginWithPassword(username, password)
      setAuthenticated(true)
    } catch (err) {
      setLoginError(err instanceof Error ? err.message : 'Login failed')
    }
  }

  if (!initialized) {
    return <LoadingState message="Initializing OIDC..." />
  }

  if (!authenticated) {
    return <DevLoginForm onLogin={handleLogin} error={loginError} />
  }

  // Create a mock Keycloak-compatible object for Dashboard
  const mockKeycloak = {
    token: '',
    tokenParsed: userInfo,
    logout: () => oidcClient.logout()
  } as unknown as Keycloak.KeycloakInstance

  // Override getToken to use OIDC client
  const getOIDCToken = async () => oidcClient.getToken() || ''

  return <Dashboard keycloak={mockKeycloak} getTokenOverride={getOIDCToken} />
}

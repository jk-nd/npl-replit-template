import { useKeycloak } from '@react-keycloak/web'
import { useState, useEffect, useCallback } from 'react'
import { NPLClient, ProtocolInstance, partyFromEmail } from './api/npl-client'
import { isDevMode } from './auth/keycloak'
import { OIDCClient } from './auth/oidc-client'
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
  if (isDevMode) {
    return <OIDCApp />
  }
  return <KeycloakApp />
}

function OIDCApp() {
  const [initialized, setInitialized] = useState(false)
  const [authenticated, setAuthenticated] = useState(false)
  const [loginError, setLoginError] = useState<string | null>(null)
  const [userInfo, setUserInfo] = useState<{ email: string; preferred_username: string }>({ 
    email: '', 
    preferred_username: '' 
  })

  useEffect(() => {
    const initOIDC = async () => {
      if (!oidcClient) return
      
      const isAuth = await oidcClient.init()
      setAuthenticated(isAuth)
      setInitialized(true)
    }
    initOIDC()
  }, [])

  useEffect(() => {
    const loadUserInfo = async () => {
      if (!oidcClient || !authenticated) return
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
  }, [authenticated])

  const handleLogin = async (username: string, password: string) => {
    if (!oidcClient) return
    
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
    logout: () => oidcClient?.logout()
  } as unknown as Keycloak.KeycloakInstance

  // Override getToken to use OIDC client
  const getOIDCToken = async () => oidcClient?.getToken() || ''

  return <Dashboard keycloak={mockKeycloak} getTokenOverride={getOIDCToken} />
}

function KeycloakApp() {
  const { keycloak, initialized } = useKeycloak()

  if (!initialized) {
    return <LoadingState message="Initializing..." />
  }

  if (!keycloak.authenticated) {
    return <LoginPrompt onLogin={() => keycloak.login()} />
  }

  return <Dashboard keycloak={keycloak} />
}

function LoadingState({ message }: { message: string }) {
  return (
    <div className="loading-screen">
      <div className="loading-content">
        <div className="loading-spinner"></div>
        <p>{message}</p>
      </div>
    </div>
  )
}

function LoginPrompt({ onLogin }: { onLogin: () => void }) {
  return (
    <div className="login-container">
      <div className="login-card">
        <div className="login-header">
          <h1>NPL Demo</h1>
          <p>IOU Management System</p>
        </div>
        <button className="login-button" onClick={onLogin}>
          Sign in with Noumena Cloud
        </button>
      </div>
    </div>
  )
}

function DevLoginForm({ onLogin, error }: { onLogin: (username: string, password: string) => void, error: string | null }) {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    await onLogin(username, password)
    setLoading(false)
  }

  return (
    <div className="login-container">
      <div className="login-card">
        <div className="login-header">
          <h1>NPL Demo</h1>
          <p>Dev Mode - Direct OIDC Login</p>
        </div>
        <form onSubmit={handleSubmit} className="login-form">
          {error && (
            <div className="error-message" style={{ padding: '12px', marginBottom: '16px', backgroundColor: '#fee', border: '1px solid #fcc', borderRadius: '4px', color: '#c33' }}>
              {error}
            </div>
          )}
          <div className="form-group">
            <label htmlFor="username">Username or Email</label>
            <input
              id="username"
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="Enter username"
              required
              disabled={loading}
              style={{ width: '100%', padding: '10px', marginTop: '4px', border: '1px solid #ddd', borderRadius: '4px' }}
            />
          </div>
          <div className="form-group" style={{ marginTop: '16px' }}>
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter password"
              required
              disabled={loading}
              style={{ width: '100%', padding: '10px', marginTop: '4px', border: '1px solid #ddd', borderRadius: '4px' }}
            />
          </div>
          <button 
            type="submit" 
            className="login-button" 
            disabled={loading}
            style={{ marginTop: '24px' }}
          >
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  )
}

interface DashboardProps {
  keycloak: Keycloak.KeycloakInstance
  getTokenOverride?: () => Promise<string>
}

function Dashboard({ keycloak, getTokenOverride }: DashboardProps) {
  const [ious, setIous] = useState<ProtocolInstance[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showCreateForm, setShowCreateForm] = useState(false)

  // Use proxy endpoint if enabled, otherwise use direct URL
  const useProxy = import.meta.env.VITE_USE_PROXY === 'true'
  const engineUrl = useProxy 
    ? '' 
    : (import.meta.env.VITE_NPL_ENGINE_URL || 'http://localhost:12000')
  
  const client = new NPLClient({
    engineUrl,
    getToken: getTokenOverride || (async () => keycloak.token!),
    packageName: 'demo'
  })

  const userEmail = keycloak.tokenParsed?.email || keycloak.tokenParsed?.preferred_username || 'unknown'

  const loadIous = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const result = await client.list('Iou')
      setIous(result.items)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load IOUs')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadIous()
  }, [loadIous])

  const handleCreateIou = async (payeeEmail: string, amount: number) => {
    try {
      setError(null)
      await client.create('Iou', {
        '@parties': {
          issuer: partyFromEmail(userEmail),
          payee: partyFromEmail(payeeEmail)
        },
        forAmount: amount
      })
      setShowCreateForm(false)
      await loadIous()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create IOU')
    }
  }

  const handlePay = async (iouId: string, amount: number) => {
    try {
      setError(null)
      await client.action('Iou', iouId, 'pay', { amount })
      await loadIous()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to make payment')
    }
  }

  const handleForgive = async (iouId: string) => {
    try {
      setError(null)
      await client.action('Iou', iouId, 'forgive')
      await loadIous()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to forgive IOU')
    }
  }

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <div className="header-left">
          <h1>IOU Dashboard</h1>
          <span className="user-badge">{userEmail}</span>
        </div>
        <div className="header-right">
          <button className="btn btn-secondary" onClick={loadIous} disabled={loading}>
            {loading ? '...' : '↻ Refresh'}
          </button>
          <button className="btn btn-primary" onClick={() => setShowCreateForm(true)}>
            + New IOU
          </button>
          <button className="btn btn-ghost" onClick={() => keycloak.logout()}>
            Sign Out
          </button>
        </div>
      </header>

      {error && (
        <div className="error-banner">
          <span>{error}</span>
          <button onClick={() => setError(null)}>×</button>
        </div>
      )}

      {showCreateForm && (
        <CreateIouModal
          onSubmit={handleCreateIou}
          onClose={() => setShowCreateForm(false)}
        />
      )}

      <main className="dashboard-content">
        {loading && ious.length === 0 ? (
          <LoadingState message="Loading IOUs..." />
        ) : ious.length === 0 ? (
          <div className="empty-state">
            <h2>No IOUs yet</h2>
            <p>Create your first IOU to get started.</p>
            <button className="btn btn-primary" onClick={() => setShowCreateForm(true)}>
              Create IOU
            </button>
          </div>
        ) : (
          <div className="iou-grid">
            {ious.map((iou) => (
              <IouCard
                key={iou['@id']}
                iou={iou}
                currentUser={userEmail}
                onPay={handlePay}
                onForgive={handleForgive}
              />
            ))}
          </div>
        )}
      </main>
    </div>
  )
}

interface IouCardProps {
  iou: ProtocolInstance
  currentUser: string
  onPay: (id: string, amount: number) => void
  onForgive: (id: string) => void
}

function IouCard({ iou, currentUser, onPay, onForgive }: IouCardProps) {
  const [payAmount, setPayAmount] = useState('')
  
  const issuerEmail = (iou['@parties'] as Record<string, { claims: Record<string, string[]> }>)?.issuer?.claims?.email?.[0] || 'unknown'
  const payeeEmail = (iou['@parties'] as Record<string, { claims: Record<string, string[]> }>)?.payee?.claims?.email?.[0] || 'unknown'
  const forAmount = iou.forAmount as number
  const state = iou['@state']

  const isIssuer = issuerEmail === currentUser
  const isPayee = payeeEmail === currentUser
  const isPaid = state === 'paid'
  const isForgiven = state === 'forgiven'
  const isActive = !isPaid && !isForgiven

  const handlePaySubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const amount = parseFloat(payAmount)
    if (amount > 0) {
      onPay(iou['@id'], amount)
      setPayAmount('')
    }
  }

  return (
    <div className={`iou-card ${isPaid ? 'paid' : ''} ${isForgiven ? 'forgiven' : ''}`}>
      <div className="iou-header">
        <span className={`state-badge ${state}`}>{state}</span>
        <span className="iou-id">{iou['@id'].slice(0, 8)}...</span>
      </div>
      
      <div className="iou-amount">
        <span className="currency">$</span>
        <span className="value">{forAmount.toLocaleString()}</span>
      </div>

      <div className="iou-parties">
        <div className="party">
          <span className="party-label">From (Issuer)</span>
          <span className="party-value">{issuerEmail}</span>
        </div>
        <div className="party">
          <span className="party-label">To (Payee)</span>
          <span className="party-value">{payeeEmail}</span>
        </div>
      </div>

      {isActive && (
        <div className="iou-actions">
          {isIssuer && (
            <form onSubmit={handlePaySubmit} className="pay-form">
              <input
                type="number"
                placeholder="Amount"
                value={payAmount}
                onChange={(e) => setPayAmount(e.target.value)}
                min="0.01"
                step="0.01"
              />
              <button type="submit" className="btn btn-primary">Pay</button>
            </form>
          )}
          {isPayee && (
            <button 
              className="btn btn-secondary"
              onClick={() => onForgive(iou['@id'])}
            >
              Forgive
            </button>
          )}
        </div>
      )}
    </div>
  )
}

interface CreateIouModalProps {
  onSubmit: (payeeEmail: string, amount: number) => void
  onClose: () => void
}

function CreateIouModal({ onSubmit, onClose }: CreateIouModalProps) {
  const [payeeEmail, setPayeeEmail] = useState('')
  const [amount, setAmount] = useState('')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const numAmount = parseFloat(amount)
    if (payeeEmail && numAmount > 0) {
      onSubmit(payeeEmail, numAmount)
    }
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Create New IOU</h2>
          <button className="modal-close" onClick={onClose}>×</button>
        </div>
        <form onSubmit={handleSubmit} className="modal-form">
          <div className="form-group">
            <label htmlFor="payeeEmail">Payee Email</label>
            <input
              id="payeeEmail"
              type="email"
              placeholder="bob@example.com"
              value={payeeEmail}
              onChange={(e) => setPayeeEmail(e.target.value)}
              required
            />
          </div>
          <div className="form-group">
            <label htmlFor="amount">Amount</label>
            <input
              id="amount"
              type="number"
              placeholder="100"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              min="0.01"
              step="0.01"
              required
            />
          </div>
          <div className="modal-actions">
            <button type="button" className="btn btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              Create IOU
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export default App

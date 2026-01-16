import { useState } from 'react'

interface DevLoginFormProps {
  onLogin: (username: string, password: string) => void
  error: string | null
}

export function DevLoginForm({ onLogin, error }: DevLoginFormProps) {
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

import { useState, useEffect, useCallback } from 'react'
import { createApiClient } from '../../api/client'
import { partyFromEmail, type Iou } from '../../api/types'
import { LoadingState } from '../shared/LoadingState'
import { IouCard } from '../iou/IouCard'
import { CreateIouModal } from '../iou/CreateIouModal'

interface DashboardProps {
  keycloak: Keycloak.KeycloakInstance
  getTokenOverride?: () => Promise<string>
}

export function Dashboard({ keycloak, getTokenOverride }: DashboardProps) {
  const [ious, setIous] = useState<Iou[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showCreateForm, setShowCreateForm] = useState(false)

  // Use proxy endpoint if enabled, otherwise use direct URL
  const useProxy = import.meta.env.VITE_USE_PROXY === 'true'
  const engineUrl = useProxy 
    ? '' 
    : (import.meta.env.VITE_NPL_ENGINE_URL || 'http://localhost:12000')
  
  const client = createApiClient({
    engineUrl,
    getToken: getTokenOverride || (async () => keycloak.token!)
  })

  const userEmail = keycloak.tokenParsed?.email || keycloak.tokenParsed?.preferred_username || 'unknown'

  const loadIous = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const { data, error: apiError } = await client.GET('/npl/demo/Iou/')
      if (apiError || !data) {
        throw new Error(apiError?.message || 'Failed to load IOUs')
      }
      setIous(data.items)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load IOUs')
    } finally {
      setLoading(false)
    }
  }, [client])

  useEffect(() => {
    loadIous()
  }, [loadIous])

  const handleCreateIou = async (payeeEmail: string, amount: number) => {
    try {
      setError(null)
      const { error: apiError } = await client.POST('/npl/demo/Iou/', {
        body: {
          '@parties': {
            issuer: partyFromEmail(userEmail),
            payee: partyFromEmail(payeeEmail)
          },
          forAmount: amount
        }
      })
      if (apiError) {
        throw new Error(apiError.message || 'Failed to create IOU')
      }
      setShowCreateForm(false)
      await loadIous()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create IOU')
    }
  }

  const handlePay = async (iouId: string, amount: number) => {
    try {
      setError(null)
      const { error: apiError } = await client.POST('/npl/demo/Iou/{id}/pay', {
        params: { path: { id: iouId } },
        body: { amount }
      })
      if (apiError) {
        throw new Error(apiError.message || 'Failed to make payment')
      }
      await loadIous()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to make payment')
    }
  }

  const handleForgive = async (iouId: string) => {
    try {
      setError(null)
      const { error: apiError } = await client.POST('/npl/demo/Iou/{id}/forgive', {
        params: { path: { id: iouId } }
      })
      if (apiError) {
        throw new Error(apiError.message || 'Failed to forgive IOU')
      }
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

import { useState } from 'react'
import { getPartyEmail, type Iou } from '../../api/types'

interface IouCardProps {
  iou: Iou
  currentUser: string
  onPay: (id: string, amount: number) => void
  onForgive: (id: string) => void
}

export function IouCard({ iou, currentUser, onPay, onForgive }: IouCardProps) {
  const [payAmount, setPayAmount] = useState('')
  
  const issuerEmail = getPartyEmail(iou['@parties'].issuer)
  const payeeEmail = getPartyEmail(iou['@parties'].payee)
  const forAmount = iou.forAmount
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

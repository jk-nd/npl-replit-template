import { useState } from 'react'

interface CreateIouModalProps {
  onSubmit: (payeeEmail: string, amount: number) => void
  onClose: () => void
}

export function CreateIouModal({ onSubmit, onClose }: CreateIouModalProps) {
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

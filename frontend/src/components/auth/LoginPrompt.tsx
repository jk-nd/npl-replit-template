interface LoginPromptProps {
  onLogin: () => void
}

export function LoginPrompt({ onLogin }: LoginPromptProps) {
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

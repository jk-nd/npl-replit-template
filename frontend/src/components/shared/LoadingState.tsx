interface LoadingStateProps {
  message: string
}

export function LoadingState({ message }: LoadingStateProps) {
  return (
    <div className="loading-screen">
      <div className="loading-content">
        <div className="loading-spinner"></div>
        <p>{message}</p>
      </div>
    </div>
  )
}

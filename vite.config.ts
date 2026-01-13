import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    // Allow Replit and all other hosts
    allowedHosts: ['.replit.dev', '.repl.co', '.worf.replit.dev', 'localhost'],
    hmr: {
      // Disable HMR host check
      host: '0.0.0.0',
    },
  },
})

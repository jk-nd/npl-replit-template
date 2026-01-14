import Keycloak from 'keycloak-js';

/**
 * Check if running in dev mode with direct OIDC calls.
 * Set VITE_DEV_MODE=true to use direct OIDC instead of Keycloak agent.
 */
export const isDevMode = import.meta.env.VITE_DEV_MODE === 'true';

/**
 * Keycloak configuration from environment variables.
 * Set these in Replit's Secrets tab.
 */
const keycloakConfig = {
  url: import.meta.env.VITE_KEYCLOAK_URL || 'http://localhost:11000',
  realm: import.meta.env.VITE_KEYCLOAK_REALM || 'demo',
  clientId: import.meta.env.VITE_KEYCLOAK_CLIENT_ID || 'frontend'
};

const keycloak = new Keycloak(keycloakConfig);

/**
 * Keycloak initialization options.
 * - onLoad: 'login-required' forces login immediately
 * - checkLoginIframe: false is recommended for cross-origin scenarios
 * - silentCheckSsoRedirectUri: enables silent SSO checks
 */
export const keycloakInit = {
  onLoad: 'login-required' as const,
  checkLoginIframe: false,
  silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html'
};

export default keycloak;

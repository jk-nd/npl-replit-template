/**
 * Direct OIDC client without Keycloak library
 * Makes raw HTTP calls to OIDC endpoints
 */

interface OIDCConfig {
  url: string;
  realm: string;
  clientId: string;
}

interface TokenResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: string;
}

interface UserInfo {
  sub: string;
  email?: string;
  preferred_username?: string;
  name?: string;
}

export class OIDCClient {
  private config: OIDCConfig;
  private baseUrl: string;
  private accessToken: string | null = null;
  private refreshToken: string | null = null;
  private tokenExpiry: number = 0;
  private userInfo: UserInfo | null = null;

  constructor(config: OIDCConfig) {
    this.config = config;
    // Use proxy endpoint if enabled, otherwise use direct URL
    const useProxy = import.meta.env.VITE_USE_PROXY === 'true';
    this.baseUrl = useProxy 
      ? '/auth'
      : `${config.url}/realms/${config.realm}/protocol/openid-connect`;
  }

  /**
   * Initialize OIDC flow - check for existing token
   */
  async init(): Promise<boolean> {
    // Check if we have a stored token
    const storedToken = sessionStorage.getItem('oidc_access_token');
    const storedRefresh = sessionStorage.getItem('oidc_refresh_token');
    const storedExpiry = sessionStorage.getItem('oidc_token_expiry');

    if (storedToken && storedExpiry) {
      this.accessToken = storedToken;
      this.refreshToken = storedRefresh;
      this.tokenExpiry = parseInt(storedExpiry);

      if (Date.now() < this.tokenExpiry) {
        return true;
      }

      // Try to refresh
      if (this.refreshToken) {
        try {
          await this.refreshTokens();
          return true;
        } catch (err) {
          console.error('Token refresh failed:', err);
        }
      }
    }

    // No valid token
    return false;
  }

  /**
   * Redirect to Keycloak login page
   */
  login(): void {
    const redirectUri = window.location.origin + window.location.pathname;
    const authUrl = `${this.baseUrl}/auth?` + new URLSearchParams({
      client_id: this.config.clientId,
      redirect_uri: redirectUri,
      response_type: 'code',
      scope: 'openid email profile'
    });
    window.location.href = authUrl;
  }

  /**
   * Login with username and password (direct credentials)
   */
  async loginWithPassword(username: string, password: string): Promise<void> {
    const response = await fetch(`${this.baseUrl}/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'password',
        client_id: this.config.clientId,
        username: username,
        password: password,
        scope: 'openid email profile'
      })
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error_description: 'Invalid credentials' }));
      throw new Error(error.error_description || 'Login failed');
    }

    const data: TokenResponse = await response.json();
    this.storeTokens(data);
  }

  /**
   * Exchange authorization code for tokens
   */
  /*private async exchangeCode(code: string): Promise<void> {
    const redirectUri = window.location.origin + window.location.pathname;
    const response = await fetch(`${this.baseUrl}/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: this.config.clientId,
        code: code,
        redirect_uri: redirectUri
      })
    });

    if (!response.ok) {
      throw new Error('Failed to exchange authorization code');
    }

    const data: TokenResponse = await response.json();
    this.storeTokens(data);
  }*/

  /**
   * Refresh access token using refresh token
   */
  private async refreshTokens(): Promise<void> {
    if (!this.refreshToken) {
      throw new Error('No refresh token available');
    }

    const response = await fetch(`${this.baseUrl}/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'refresh_token',
        client_id: this.config.clientId,
        refresh_token: this.refreshToken
      })
    });

    if (!response.ok) {
      throw new Error('Failed to refresh token');
    }

    const data: TokenResponse = await response.json();
    this.storeTokens(data);
  }

  /**
   * Store tokens in memory and session storage
   */
  private storeTokens(data: TokenResponse): void {
    this.accessToken = data.access_token;
    this.refreshToken = data.refresh_token;
    this.tokenExpiry = Date.now() + (data.expires_in * 1000) - 60000; // 1 min buffer

    sessionStorage.setItem('oidc_access_token', this.accessToken);
    if (this.refreshToken) {
      sessionStorage.setItem('oidc_refresh_token', this.refreshToken);
    }
    sessionStorage.setItem('oidc_token_expiry', this.tokenExpiry.toString());
  }

  /**
   * Get current access token, refreshing if needed
   */
  async getToken(): Promise<string> {
    if (!this.accessToken) {
      throw new Error('Not authenticated');
    }

    // Refresh if token is about to expire
    if (Date.now() >= this.tokenExpiry && this.refreshToken) {
      await this.refreshTokens();
    }

    return this.accessToken;
  }

  /**
   * Get user information from OIDC userinfo endpoint
   */
  async getUserInfo(): Promise<UserInfo> {
    if (this.userInfo) {
      return this.userInfo;
    }

    const token = await this.getToken();
    const response = await fetch(`${this.baseUrl}/userinfo`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    if (!response.ok) {
      throw new Error('Failed to get user info');
    }

    this.userInfo = await response.json();
    if (!this.userInfo) {
      throw new Error('Failed to get user info from json');
    }
    return this.userInfo;
  }

  /**
   * Logout user
   */
  logout(): void {
    this.accessToken = null;
    this.refreshToken = null;
    this.userInfo = null;
    sessionStorage.removeItem('oidc_access_token');
    sessionStorage.removeItem('oidc_refresh_token');
    sessionStorage.removeItem('oidc_token_expiry');

    const logoutUrl = `${this.baseUrl}/logout?` + new URLSearchParams({
      redirect_uri: window.location.origin
    });
    window.location.href = logoutUrl;
  }

  /**
   * Check if user is authenticated
   */
  get authenticated(): boolean {
    return this.accessToken !== null && Date.now() < this.tokenExpiry;
  }
}

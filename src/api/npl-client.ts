/**
 * NPL API Client
 * 
 * A typed client for interacting with NPL Engine REST APIs.
 * Uses the authenticated user's JWT token from Keycloak.
 */

export interface Party {
  claims: Record<string, string[]>;
}

export interface NPLClientConfig {
  engineUrl: string;
  getToken: () => Promise<string>;
  packageName?: string;
}

export interface ProtocolInstance {
  '@id': string;
  '@parties': Record<string, Party>;
  '@actions': Record<string, string>;
  '@state': string;
  [key: string]: unknown;
}

export interface ProtocolList {
  items: ProtocolInstance[];
  page?: number;
  totalItems?: number;
  totalPages?: number;
  '@prev'?: string;
  '@next'?: string;
}

/**
 * NPL API Client for interacting with NPL Engine.
 * 
 * @example
 * ```typescript
 * const client = new NPLClient({
 *   engineUrl: 'https://your-app.noumena.cloud',
 *   getToken: () => keycloak.token!,
 *   packageName: 'demo'
 * });
 * 
 * // Create an IOU
 * const iou = await client.create('Iou', {
 *   '@parties': {
 *     issuer: { claims: { email: ['alice@example.com'] } },
 *     payee: { claims: { email: ['bob@example.com'] } }
 *   },
 *   forAmount: 100
 * });
 * 
 * // Execute an action
 * await client.action('Iou', iou['@id'], 'pay', { amount: 50 });
 * ```
 */
export class NPLClient {
  private config: NPLClientConfig;

  constructor(config: NPLClientConfig) {
    this.config = {
      ...config,
      packageName: config.packageName || 'demo'
    };
  }

  private async request<T>(
    method: string,
    path: string,
    body?: unknown
  ): Promise<T> {
    const token = await this.config.getToken();
    
    const response = await fetch(`${this.config.engineUrl}${path}`, {
      method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: body ? JSON.stringify(body) : undefined,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: response.statusText }));
      throw new Error(`NPL API error (${response.status}): ${error.message || JSON.stringify(error)}`);
    }

    // Handle 204 No Content
    if (response.status === 204) {
      return {} as T;
    }

    return response.json();
  }

  /**
   * Create a new protocol instance.
   */
  async create<T extends Record<string, unknown>>(
    protocol: string,
    data: T
  ): Promise<ProtocolInstance> {
    return this.request<ProtocolInstance>(
      'POST',
      `/npl/${this.config.packageName}/${protocol}/`,
      data
    );
  }

  /**
   * Get a protocol instance by ID.
   */
  async get(protocol: string, id: string): Promise<ProtocolInstance> {
    return this.request<ProtocolInstance>(
      'GET',
      `/npl/${this.config.packageName}/${protocol}/${id}/`
    );
  }

  /**
   * List protocol instances with optional pagination.
   */
  async list(
    protocol: string,
    options?: { page?: number; pageSize?: number; state?: string }
  ): Promise<ProtocolList> {
    const params = new URLSearchParams();
    if (options?.page) params.set('page', options.page.toString());
    if (options?.pageSize) params.set('pageSize', options.pageSize.toString());
    if (options?.state) params.set('state', options.state);
    
    const query = params.toString() ? `?${params.toString()}` : '';
    return this.request<ProtocolList>(
      'GET',
      `/npl/${this.config.packageName}/${protocol}/${query}`
    );
  }

  /**
   * Execute an action on a protocol instance.
   */
  async action<T = unknown, R = unknown>(
    protocol: string,
    id: string,
    actionName: string,
    params?: T
  ): Promise<R> {
    return this.request<R>(
      'POST',
      `/npl/${this.config.packageName}/${protocol}/${id}/${actionName}`,
      params
    );
  }
}

/**
 * Create a party object for NPL.
 * 
 * @example
 * ```typescript
 * const alice = createParty({ email: ['alice@example.com'] });
 * const admins = createParty({ role: ['admin'] });
 * ```
 */
export function createParty(claims: Record<string, string[]>): Party {
  return { claims };
}

/**
 * Create a party from an email address.
 */
export function partyFromEmail(email: string): Party {
  return createParty({ email: [email] });
}

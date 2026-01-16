/**
 * Type definitions for MCP Gateway
 */

export interface ServerConfig {
  command: string;
  args: string[];
  env?: Record<string, string>;
  disabled?: boolean;
}

export interface ToolSearchConfig {
  enabled?: boolean;          // Enable tool search (default: true)
  maxResults?: number;        // Max results per search (default: 5)
  minScore?: number;          // Minimum relevance score 0-1 (default: 0.1)
  searchFields?: ('name' | 'description' | 'args')[];
}

export interface HttpConfig {
  enabled: boolean;           // Enable HTTP server mode
  port: number;               // Port to listen on (default: 3000)
  host?: string;              // Host to bind to (default: 0.0.0.0)
  corsOrigins?: string[];     // Allowed CORS origins, '*' for all
  tls?: {
    cert: string;             // Path to SSL certificate file
    key: string;              // Path to SSL private key file
  };
}

export interface GatewayConfig {
  gateway: {
    name: string;
    version: string;
    toolSearch?: ToolSearchConfig;
    http?: HttpConfig;        // HTTP server config (if not set, uses stdio)
  };
  servers: Record<string, ServerConfig>;
}

export interface ToolInfo {
  serverId: string;
  name: string;
  description?: string;
  inputSchema: any;
}

export interface ResourceInfo {
  serverId: string;
  uri: string;
  name?: string;
  description?: string;
  mimeType?: string;
}

export interface PromptInfo {
  serverId: string;
  name: string;
  description?: string;
  arguments?: any[];
}

export interface ServerCapabilities {
  tools: ToolInfo[];
  resources: ResourceInfo[];
  prompts: PromptInfo[];
}

export interface ServerConnection {
  id: string;
  client: any; // MCP Client instance
  transport: any; // Transport instance
  process?: any; // Child process for stdio
  capabilities: ServerCapabilities;
  connected: boolean;
}

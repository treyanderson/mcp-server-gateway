/**
 * MCP Gateway Server - Aggregates multiple MCP servers into one interface
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  ListPromptsRequestSchema,
  GetPromptRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { ServerManager } from './server-manager.js';
import { GatewayConfig } from './types.js';
import {
  ToolSearchIndex,
  createToolSearchToolDefinition,
  formatAsToolReferences,
  formatAsTextResult,
} from './tool-search.js';
import { HttpMcpServer } from './http-server.js';

export class MCPGateway {
  private server: Server | null = null;
  private httpServer: HttpMcpServer | null = null;
  private serverManager: ServerManager;
  private config: GatewayConfig;
  private toolSearchIndex: ToolSearchIndex;
  private toolSearchEnabled: boolean;

  constructor(config: GatewayConfig) {
    this.config = config;
    this.serverManager = new ServerManager();
    this.toolSearchEnabled = config.gateway.toolSearch?.enabled !== false;
    this.toolSearchIndex = new ToolSearchIndex(config.gateway.toolSearch);
  }

  /**
   * Create a new MCP server instance with all handlers configured
   * Used for both stdio mode (single instance) and HTTP mode (per-session)
   */
  createServer(): Server {
    const server = new Server(
      {
        name: this.config.gateway.name,
        version: this.config.gateway.version,
      },
      {
        capabilities: {
          tools: {},
          resources: {},
          prompts: {},
        },
      }
    );

    this.setupHandlers(server);
    return server;
  }

  /**
   * Setup request handlers on a server instance
   */
  private setupHandlers(server: Server): void {
    // Handle tool list requests
    server.setRequestHandler(ListToolsRequestSchema, async () => {
      const capabilities = this.serverManager.getAggregatedCapabilities();

      // Build tools list
      const tools = capabilities.tools.map((t) => ({
        name: t.name,
        description: t.description,
        inputSchema: t.inputSchema,
      }));

      // Add tool_search if enabled
      if (this.toolSearchEnabled) {
        tools.unshift(createToolSearchToolDefinition());
      }

      return { tools };
    });

    // Handle tool call requests
    server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name: toolName, arguments: toolArgs } = request.params;

      console.error(`[gateway] Tool call: ${toolName}`);

      // Handle tool_search specially
      if (toolName === 'tool_search' && this.toolSearchEnabled) {
        return this.handleToolSearch(toolArgs as { query: string; mode?: string });
      }

      // Find which server has this tool
      const serverId = this.serverManager.findToolServer(toolName);
      if (!serverId) {
        throw new Error(`Tool not found: ${toolName}`);
      }

      const connection = this.serverManager.getConnection(serverId);
      if (!connection) {
        throw new Error(`Server not connected: ${serverId}`);
      }

      console.error(`[gateway] Routing to server: ${serverId}`);

      try {
        // Forward the request to the appropriate server
        const result = await connection.client.callTool({
          name: toolName,
          arguments: toolArgs,
        });

        return result;
      } catch (error: any) {
        console.error(`[gateway] Tool call failed:`, error);
        throw new Error(`Tool call failed: ${error.message}`);
      }
    });

    // Handle resource list requests
    server.setRequestHandler(ListResourcesRequestSchema, async () => {
      const capabilities = this.serverManager.getAggregatedCapabilities();
      return {
        resources: capabilities.resources.map((r) => ({
          uri: r.uri,
          name: r.name,
          description: r.description,
          mimeType: r.mimeType,
        })),
      };
    });

    // Handle resource read requests
    server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
      const { uri } = request.params;

      console.error(`[gateway] Resource read: ${uri}`);

      // Find which server has this resource
      const serverId = this.serverManager.findResourceServer(uri);
      if (!serverId) {
        throw new Error(`Resource not found: ${uri}`);
      }

      const connection = this.serverManager.getConnection(serverId);
      if (!connection) {
        throw new Error(`Server not connected: ${serverId}`);
      }

      console.error(`[gateway] Routing to server: ${serverId}`);

      try {
        // Forward the request to the appropriate server
        const result = await connection.client.readResource({ uri });
        return result;
      } catch (error: any) {
        console.error(`[gateway] Resource read failed:`, error);
        throw new Error(`Resource read failed: ${error.message}`);
      }
    });

    // Handle prompt list requests
    server.setRequestHandler(ListPromptsRequestSchema, async () => {
      const capabilities = this.serverManager.getAggregatedCapabilities();
      return {
        prompts: capabilities.prompts.map((p) => ({
          name: p.name,
          description: p.description,
          arguments: p.arguments,
        })),
      };
    });

    // Handle prompt get requests
    server.setRequestHandler(GetPromptRequestSchema, async (request) => {
      const { name: promptName, arguments: promptArgs } = request.params;

      console.error(`[gateway] Prompt get: ${promptName}`);

      // Find which server has this prompt
      const serverId = this.serverManager.findPromptServer(promptName);
      if (!serverId) {
        throw new Error(`Prompt not found: ${promptName}`);
      }

      const connection = this.serverManager.getConnection(serverId);
      if (!connection) {
        throw new Error(`Server not connected: ${serverId}`);
      }

      console.error(`[gateway] Routing to server: ${serverId}`);

      try {
        // Forward the request to the appropriate server
        const result = await connection.client.getPrompt({
          name: promptName,
          arguments: promptArgs,
        });

        return result;
      } catch (error: any) {
        console.error(`[gateway] Prompt get failed:`, error);
        throw new Error(`Prompt get failed: ${error.message}`);
      }
    });
  }

  /**
   * Handle tool_search requests
   */
  private handleToolSearch(args: { query: string; mode?: string }): any {
    const { query, mode = 'natural' } = args;

    console.error(`[gateway] Tool search: "${query}" (mode: ${mode})`);

    // Perform search based on mode
    const results = mode === 'regex'
      ? this.toolSearchIndex.searchRegex(query)
      : this.toolSearchIndex.searchNaturalLanguage(query);

    console.error(`[gateway] Found ${results.length} matching tools`);

    // Return results in MCP tool result format
    // Using text content with tool references for compatibility
    if (results.length === 0) {
      return {
        content: [
          {
            type: 'text',
            text: 'No matching tools found. Try a different search query.',
          },
        ],
      };
    }

    // Return both text summary and tool references
    // The tool_reference format enables Claude API to auto-expand deferred tools
    return {
      content: [
        {
          type: 'text',
          text: formatAsTextResult(results),
        },
        // Include tool_reference blocks for Claude API compatibility
        ...formatAsToolReferences(results),
      ],
    };
  }

  /**
   * Initialize and connect to all downstream servers
   */
  async initialize(): Promise<void> {
    console.error('[gateway] Initializing...');

    // Filter out disabled servers
    const serverEntries = Object.entries(this.config.servers).filter(
      ([_, config]) => !config.disabled
    );
    console.error(`[gateway] Connecting to ${serverEntries.length} servers...`);

    const connectionPromises = serverEntries.map(async ([serverId, serverConfig]) => {
      try {
        await this.serverManager.connectServer(serverId, serverConfig);
      } catch (error) {
        console.error(`[gateway] Failed to connect to ${serverId}:`, error);
        // Continue with other servers even if one fails
      }
    });

    await Promise.allSettled(connectionPromises);

    const connectedCount = this.serverManager.getConnections().length;
    console.error(`[gateway] Connected to ${connectedCount}/${serverEntries.length} servers`);

    // Log aggregated capabilities
    const capabilities = this.serverManager.getAggregatedCapabilities();
    console.error(
      `[gateway] Total capabilities: ` +
      `${capabilities.tools.length} tools, ` +
      `${capabilities.resources.length} resources, ` +
      `${capabilities.prompts.length} prompts`
    );

    // Update tool search index
    if (this.toolSearchEnabled) {
      this.toolSearchIndex.updateIndex(capabilities.tools);
      console.error(`[gateway] Tool search enabled with ${capabilities.tools.length} indexed tools`);
    }
  }

  /**
   * Start the gateway server
   * Mode depends on config: HTTP if http.enabled, otherwise stdio
   */
  async start(): Promise<void> {
    const httpConfig = this.config.gateway.http;

    if (httpConfig?.enabled) {
      // HTTP mode - multiple clients can connect
      console.error('[gateway] Starting in HTTP mode...');

      this.httpServer = new HttpMcpServer(
        {
          port: httpConfig.port || 3000,
          host: httpConfig.host || '0.0.0.0',
          corsOrigins: httpConfig.corsOrigins || ['*'],
          tls: httpConfig.tls,
        },
        () => this.createServer()  // Factory function for new sessions
      );

      await this.httpServer.start();
      console.error('[gateway] HTTP server started and ready for connections');
    } else {
      // Stdio mode - single client via stdin/stdout
      console.error('[gateway] Starting in stdio mode...');

      this.server = this.createServer();
      const transport = new StdioServerTransport();
      await this.server.connect(transport);

      console.error('[gateway] Server started and ready');
    }
  }

  /**
   * Shutdown the gateway
   */
  async shutdown(): Promise<void> {
    console.error('[gateway] Shutting down...');

    // Shutdown HTTP server if running
    if (this.httpServer) {
      await this.httpServer.stop();
    }

    // Shutdown stdio server if running
    if (this.server) {
      await this.server.close();
    }

    // Disconnect all downstream servers
    await this.serverManager.disconnectAll();

    console.error('[gateway] Shutdown complete');
  }

  /**
   * Get the transport mode
   */
  getMode(): 'http' | 'stdio' {
    return this.config.gateway.http?.enabled ? 'http' : 'stdio';
  }
}

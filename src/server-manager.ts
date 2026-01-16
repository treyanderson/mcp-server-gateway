/**
 * Manages connections to downstream MCP servers
 */

import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';
import { spawn } from 'child_process';
import { ServerConfig, ServerConnection, ServerCapabilities } from './types.js';

export class ServerManager {
  private connections: Map<string, ServerConnection> = new Map();

  /**
   * Initialize and connect to a downstream MCP server
   */
  async connectServer(serverId: string, config: ServerConfig): Promise<void> {
    console.error(`[${serverId}] Connecting to server...`);

    try {
      // Spawn the server process
      // Filter out undefined environment variables
      const envVars: Record<string, string> = {};
      for (const [key, value] of Object.entries({ ...process.env, ...(config.env || {}) })) {
        if (value !== undefined) {
          envVars[key] = value;
        }
      }

      const serverProcess = spawn(config.command, config.args, {
        env: envVars,
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      // Handle process errors
      serverProcess.on('error', (error) => {
        console.error(`[${serverId}] Process error:`, error);
      });

      serverProcess.stderr?.on('data', (data) => {
        const message = data.toString().trim();
        if (message) {
          console.error(`[${serverId}] ${message}`);
        }
      });

      // Create MCP client
      const client = new Client(
        {
          name: `gateway-client-${serverId}`,
          version: '1.0.0',
        },
        {
          capabilities: {
            tools: {},
            resources: {},
            prompts: {},
          },
        }
      );

      // Create stdio transport
      const transport = new StdioClientTransport({
        command: config.command,
        args: config.args,
        env: envVars,
      });

      // Connect client to transport
      await client.connect(transport);

      // Get server capabilities
      const capabilities = await this.getServerCapabilities(client, serverId);

      // Store connection
      const connection: ServerConnection = {
        id: serverId,
        client,
        transport,
        process: serverProcess,
        capabilities,
        connected: true,
      };

      this.connections.set(serverId, connection);

      console.error(
        `[${serverId}] Connected - ` +
        `${capabilities.tools.length} tools, ` +
        `${capabilities.resources.length} resources, ` +
        `${capabilities.prompts.length} prompts`
      );
    } catch (error) {
      console.error(`[${serverId}] Failed to connect:`, error);
      throw error;
    }
  }

  /**
   * Query a server for its capabilities
   */
  private async getServerCapabilities(
    client: any,
    serverId: string
  ): Promise<ServerCapabilities> {
    const capabilities: ServerCapabilities = {
      tools: [],
      resources: [],
      prompts: [],
    };

    try {
      // List tools
      const toolsResult = await client.listTools();
      if (toolsResult.tools) {
        capabilities.tools = toolsResult.tools.map((tool: any) => ({
          serverId,
          name: tool.name,
          description: tool.description,
          inputSchema: tool.inputSchema,
        }));
      }
    } catch (error) {
      console.error(`[${serverId}] Failed to list tools:`, error);
    }

    try {
      // List resources
      const resourcesResult = await client.listResources();
      if (resourcesResult.resources) {
        capabilities.resources = resourcesResult.resources.map((resource: any) => ({
          serverId,
          uri: resource.uri,
          name: resource.name,
          description: resource.description,
          mimeType: resource.mimeType,
        }));
      }
    } catch (error) {
      console.error(`[${serverId}] Failed to list resources:`, error);
    }

    try {
      // List prompts
      const promptsResult = await client.listPrompts();
      if (promptsResult.prompts) {
        capabilities.prompts = promptsResult.prompts.map((prompt: any) => ({
          serverId,
          name: prompt.name,
          description: prompt.description,
          arguments: prompt.arguments,
        }));
      }
    } catch (error) {
      console.error(`[${serverId}] Failed to list prompts:`, error);
    }

    return capabilities;
  }

  /**
   * Get all connected servers
   */
  getConnections(): ServerConnection[] {
    return Array.from(this.connections.values()).filter((conn) => conn.connected);
  }

  /**
   * Get a specific server connection
   */
  getConnection(serverId: string): ServerConnection | undefined {
    return this.connections.get(serverId);
  }

  /**
   * Get aggregated capabilities from all servers
   */
  getAggregatedCapabilities(): ServerCapabilities {
    const aggregated: ServerCapabilities = {
      tools: [],
      resources: [],
      prompts: [],
    };

    for (const connection of this.connections.values()) {
      if (connection.connected) {
        aggregated.tools.push(...connection.capabilities.tools);
        aggregated.resources.push(...connection.capabilities.resources);
        aggregated.prompts.push(...connection.capabilities.prompts);
      }
    }

    return aggregated;
  }

  /**
   * Find which server provides a specific tool
   */
  findToolServer(toolName: string): string | undefined {
    for (const connection of this.connections.values()) {
      if (connection.connected) {
        const hasTool = connection.capabilities.tools.some((t) => t.name === toolName);
        if (hasTool) {
          return connection.id;
        }
      }
    }
    return undefined;
  }

  /**
   * Find which server provides a specific resource
   */
  findResourceServer(uri: string): string | undefined {
    for (const connection of this.connections.values()) {
      if (connection.connected) {
        const hasResource = connection.capabilities.resources.some((r) => r.uri === uri);
        if (hasResource) {
          return connection.id;
        }
      }
    }
    return undefined;
  }

  /**
   * Find which server provides a specific prompt
   */
  findPromptServer(promptName: string): string | undefined {
    for (const connection of this.connections.values()) {
      if (connection.connected) {
        const hasPrompt = connection.capabilities.prompts.some((p) => p.name === promptName);
        if (hasPrompt) {
          return connection.id;
        }
      }
    }
    return undefined;
  }

  /**
   * Disconnect all servers
   */
  async disconnectAll(): Promise<void> {
    console.error('[gateway] Disconnecting all servers...');

    for (const connection of this.connections.values()) {
      try {
        await connection.client.close();
        connection.process?.kill();
        connection.connected = false;
      } catch (error) {
        console.error(`[${connection.id}] Error disconnecting:`, error);
      }
    }

    this.connections.clear();
    console.error('[gateway] All servers disconnected');
  }
}

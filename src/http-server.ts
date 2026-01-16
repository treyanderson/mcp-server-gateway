/**
 * HTTP/HTTPS Server for MCP Gateway
 *
 * Enables remote clients to connect to the gateway over HTTP(S).
 * Uses the MCP Streamable HTTP transport specification.
 */

import { createServer as createHttpServer, IncomingMessage, ServerResponse } from 'http';
import { createServer as createHttpsServer } from 'https';
import { readFileSync } from 'fs';
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { randomUUID } from 'crypto';

export interface HttpServerConfig {
  port: number;
  host?: string;
  corsOrigins?: string[];  // Allowed CORS origins, '*' for all
  tls?: {
    cert: string;          // Path to SSL certificate file
    key: string;           // Path to SSL private key file
  };
}

interface SessionInfo {
  transport: StreamableHTTPServerTransport;
  server: Server;
  createdAt: Date;
}

type HttpServer = ReturnType<typeof createHttpServer> | ReturnType<typeof createHttpsServer>;

/**
 * HTTP(S) Server that hosts the MCP Gateway for remote clients
 */
export class HttpMcpServer {
  private httpServer: HttpServer | null = null;
  private sessions: Map<string, SessionInfo> = new Map();
  private config: HttpServerConfig;
  private serverFactory: () => Server;
  private isHttps: boolean;

  constructor(config: HttpServerConfig, serverFactory: () => Server) {
    this.config = config;
    this.serverFactory = serverFactory;
    this.isHttps = !!config.tls;
  }

  /**
   * Start the HTTP(S) server
   */
  async start(): Promise<void> {
    return new Promise((resolve, reject) => {
      const requestHandler = (req: IncomingMessage, res: ServerResponse) => {
        this.handleRequest(req, res);
      };

      if (this.config.tls) {
        // HTTPS mode
        try {
          const tlsOptions = {
            cert: readFileSync(this.config.tls.cert),
            key: readFileSync(this.config.tls.key),
          };
          this.httpServer = createHttpsServer(tlsOptions, requestHandler);
          console.error('[http] TLS enabled');
        } catch (error: any) {
          console.error('[http] Failed to load TLS certificates:', error.message);
          reject(error);
          return;
        }
      } else {
        // HTTP mode (not recommended for production)
        this.httpServer = createHttpServer(requestHandler);
        console.error('[http] WARNING: Running without TLS - not recommended for production');
      }

      this.httpServer.on('error', (error) => {
        console.error('[http] Server error:', error);
        reject(error);
      });

      const host = this.config.host || '0.0.0.0';
      const protocol = this.isHttps ? 'https' : 'http';

      this.httpServer.listen(this.config.port, host, () => {
        console.error(`[http] MCP Gateway listening on ${protocol}://${host}:${this.config.port}`);
        console.error(`[http] Clients can connect to: ${protocol}://<your-ip>:${this.config.port}/mcp`);
        resolve();
      });
    });
  }

  /**
   * Handle incoming HTTP requests
   */
  private async handleRequest(req: IncomingMessage, res: ServerResponse): Promise<void> {
    const url = new URL(req.url || '/', `http://${req.headers.host}`);

    // Add CORS headers
    this.addCorsHeaders(req, res);

    // Handle preflight
    if (req.method === 'OPTIONS') {
      res.writeHead(204);
      res.end();
      return;
    }

    // Health check endpoint
    if (url.pathname === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        status: 'healthy',
        sessions: this.sessions.size,
        uptime: process.uptime(),
        tls: this.isHttps,
      }));
      return;
    }

    // MCP endpoint
    if (url.pathname === '/mcp') {
      await this.handleMcpRequest(req, res);
      return;
    }

    // 404 for other paths
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  }

  /**
   * Handle MCP protocol requests
   */
  private async handleMcpRequest(req: IncomingMessage, res: ServerResponse): Promise<void> {
    // Check for existing session
    const sessionId = req.headers['mcp-session-id'] as string | undefined;

    if (sessionId && this.sessions.has(sessionId)) {
      // Existing session - route to its transport
      const session = this.sessions.get(sessionId)!;
      await session.transport.handleRequest(req, res);
      return;
    }

    // New session - create transport and server
    if (req.method === 'POST') {
      await this.createNewSession(req, res);
      return;
    }

    // GET without session - return error
    if (req.method === 'GET') {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        jsonrpc: '2.0',
        error: {
          code: -32000,
          message: 'Bad Request: Session not established. Send POST to initialize.',
        },
        id: null,
      }));
      return;
    }

    res.writeHead(405, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      jsonrpc: '2.0',
      error: { code: -32000, message: 'Method not allowed' },
      id: null,
    }));
  }

  /**
   * Create a new MCP session
   */
  private async createNewSession(req: IncomingMessage, res: ServerResponse): Promise<void> {
    console.error('[http] Creating new session...');

    // Create transport with session management
    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: () => randomUUID(),
      onsessioninitialized: (sessionId: string) => {
        console.error(`[http] Session initialized: ${sessionId}`);

        // Create a new server instance for this session
        const server = this.serverFactory();

        // Store session info
        this.sessions.set(sessionId, {
          transport,
          server,
          createdAt: new Date(),
        });

        // Connect server to transport
        server.connect(transport).catch((error) => {
          console.error(`[http] Failed to connect server for session ${sessionId}:`, error);
        });
      },
      onsessionclosed: (sessionId: string | undefined) => {
        if (sessionId) {
          console.error(`[http] Session closed: ${sessionId}`);
          const session = this.sessions.get(sessionId);
          if (session) {
            session.server.close().catch(() => {});
            this.sessions.delete(sessionId);
          }
        }
      },
    });

    // Handle the initial request
    await transport.handleRequest(req, res);
  }

  /**
   * Add CORS headers to response
   */
  private addCorsHeaders(req: IncomingMessage, res: ServerResponse): void {
    const origin = req.headers.origin;

    if (this.config.corsOrigins?.includes('*')) {
      res.setHeader('Access-Control-Allow-Origin', '*');
    } else if (origin && this.config.corsOrigins?.includes(origin)) {
      res.setHeader('Access-Control-Allow-Origin', origin);
    }

    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Accept, Mcp-Session-Id, Mcp-Protocol-Version, Last-Event-ID');
    res.setHeader('Access-Control-Expose-Headers', 'Mcp-Session-Id');
  }

  /**
   * Stop the HTTP server
   */
  async stop(): Promise<void> {
    // Close all sessions
    for (const [sessionId, session] of this.sessions) {
      console.error(`[http] Closing session: ${sessionId}`);
      await session.transport.close();
      await session.server.close();
    }
    this.sessions.clear();

    // Close HTTP server
    return new Promise((resolve) => {
      if (this.httpServer) {
        this.httpServer.close(() => {
          console.error('[http] Server stopped');
          resolve();
        });
      } else {
        resolve();
      }
    });
  }

  /**
   * Get active session count
   */
  getSessionCount(): number {
    return this.sessions.size;
  }

  /**
   * Check if server is using TLS
   */
  isSecure(): boolean {
    return this.isHttps;
  }
}

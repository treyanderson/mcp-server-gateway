#!/usr/bin/env node
/**
 * MCP HTTP Bridge - Connects stdio-based MCP clients to HTTP-based MCP servers
 *
 * Usage: node mcp-http-bridge.js <gateway-url>
 * Example: node mcp-http-bridge.js https://dgx.leap21llc.com
 */

const GATEWAY_URL = process.argv[2] || process.env.MCP_GATEWAY_URL || 'https://dgx.leap21llc.com';
const MCP_ENDPOINT = `${GATEWAY_URL}/mcp`;

let sessionId = null;
let buffer = '';

// Read from stdin
process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => {
  buffer += chunk;

  // Try to parse complete JSON-RPC messages
  let newlineIndex;
  while ((newlineIndex = buffer.indexOf('\n')) !== -1) {
    const line = buffer.slice(0, newlineIndex).trim();
    buffer = buffer.slice(newlineIndex + 1);

    if (line) {
      handleMessage(line);
    }
  }
});

process.stdin.on('end', () => {
  process.exit(0);
});

async function handleMessage(line) {
  try {
    const message = JSON.parse(line);
    const response = await sendToGateway(message);

    if (response) {
      process.stdout.write(JSON.stringify(response) + '\n');
    }
  } catch (error) {
    console.error('[bridge] Error:', error.message);

    // Send error response
    const errorResponse = {
      jsonrpc: '2.0',
      error: {
        code: -32603,
        message: error.message
      },
      id: null
    };
    process.stdout.write(JSON.stringify(errorResponse) + '\n');
  }
}

async function sendToGateway(message) {
  const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };

  // Include session ID if we have one
  if (sessionId) {
    headers['Mcp-Session-Id'] = sessionId;
  }

  const response = await fetch(MCP_ENDPOINT, {
    method: 'POST',
    headers,
    body: JSON.stringify(message)
  });

  // Capture session ID from response
  const newSessionId = response.headers.get('Mcp-Session-Id');
  if (newSessionId) {
    sessionId = newSessionId;
  }

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }

  const contentType = response.headers.get('Content-Type') || '';

  // Handle SSE responses (for streaming)
  if (contentType.includes('text/event-stream')) {
    const text = await response.text();
    const lines = text.split('\n');

    for (const line of lines) {
      if (line.startsWith('data: ')) {
        const data = line.slice(6);
        if (data && data !== '[DONE]') {
          try {
            return JSON.parse(data);
          } catch {
            // Ignore parse errors for SSE
          }
        }
      }
    }
    return null;
  }

  // Handle JSON responses
  return response.json();
}

// Handle process signals
process.on('SIGINT', () => process.exit(0));
process.on('SIGTERM', () => process.exit(0));

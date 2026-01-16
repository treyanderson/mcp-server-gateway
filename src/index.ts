#!/usr/bin/env node
/**
 * MCP Gateway - Entry point
 */

import { MCPGateway } from './gateway.js';
import { loadConfig, loadEnv } from './config-loader.js';

async function main() {
  try {
    // Load environment variables
    loadEnv();

    // Load configuration
    const configPath = process.argv[2] || './config.json';
    const config = loadConfig(configPath);

    // Create and initialize gateway
    const gateway = new MCPGateway(config);
    await gateway.initialize();

    // Start the gateway server
    await gateway.start();

    // Handle shutdown signals
    const shutdown = async () => {
      await gateway.shutdown();
      process.exit(0);
    };

    process.on('SIGINT', shutdown);
    process.on('SIGTERM', shutdown);
  } catch (error) {
    console.error('[gateway] Fatal error:', error);
    process.exit(1);
  }
}

main();

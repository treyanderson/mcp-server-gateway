/**
 * Configuration loader with environment variable substitution
 */

import { readFileSync } from 'fs';
import { resolve } from 'path';
import { GatewayConfig } from './types.js';

/**
 * Substitute environment variables in string values
 * Supports ${VAR_NAME} syntax
 */
function substituteEnvVars(value: any): any {
  if (typeof value === 'string') {
    return value.replace(/\$\{([^}]+)\}/g, (_, varName) => {
      return process.env[varName] || '';
    });
  }

  if (Array.isArray(value)) {
    return value.map(substituteEnvVars);
  }

  if (typeof value === 'object' && value !== null) {
    const result: any = {};
    for (const [key, val] of Object.entries(value)) {
      result[key] = substituteEnvVars(val);
    }
    return result;
  }

  return value;
}

/**
 * Load and parse gateway configuration
 */
export function loadConfig(configPath: string = './config.json'): GatewayConfig {
  const fullPath = resolve(configPath);

  try {
    const configData = readFileSync(fullPath, 'utf-8');
    const rawConfig = JSON.parse(configData);
    const config = substituteEnvVars(rawConfig) as GatewayConfig;

    // Filter out disabled servers
    const enabledServers: Record<string, any> = {};
    for (const [id, serverConfig] of Object.entries(config.servers)) {
      if (!serverConfig.disabled) {
        enabledServers[id] = serverConfig;
      }
    }
    config.servers = enabledServers;

    console.error(`[config] Loaded configuration with ${Object.keys(config.servers).length} servers`);
    return config;
  } catch (error) {
    console.error(`[config] Failed to load configuration from ${fullPath}:`, error);
    throw error;
  }
}

/**
 * Load environment variables from .env file if it exists
 */
export function loadEnv(): void {
  try {
    const envPath = resolve('.env');
    const envData = readFileSync(envPath, 'utf-8');

    for (const line of envData.split('\n')) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;

      const [key, ...valueParts] = trimmed.split('=');
      if (key && valueParts.length > 0) {
        const value = valueParts.join('=').trim();
        if (!process.env[key]) {
          process.env[key] = value;
        }
      }
    }
    console.error('[config] Loaded .env file');
  } catch (error) {
    // .env file is optional
    console.error('[config] No .env file found (optional)');
  }
}

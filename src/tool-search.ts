/**
 * Tool Search - Enables dynamic tool discovery across aggregated MCP servers
 *
 * Implements the ToolSearchTool pattern from:
 * https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool
 */

import { ToolInfo } from './types.js';

export interface ToolSearchResult {
  toolName: string;
  serverId: string;
  score: number;
}

export interface ToolSearchConfig {
  maxResults?: number;        // Default: 5
  minScore?: number;          // Minimum relevance score (0-1)
  searchFields?: ('name' | 'description' | 'args')[];
}

const DEFAULT_CONFIG: Required<ToolSearchConfig> = {
  maxResults: 5,
  minScore: 0.1,
  searchFields: ['name', 'description', 'args'],
};

/**
 * ToolSearchIndex - Indexes tools for fast search
 */
export class ToolSearchIndex {
  private tools: ToolInfo[] = [];
  private config: Required<ToolSearchConfig>;

  constructor(config: ToolSearchConfig = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /**
   * Update the index with current tools
   */
  updateIndex(tools: ToolInfo[]): void {
    this.tools = tools;
    console.error(`[tool-search] Indexed ${tools.length} tools`);
  }

  /**
   * Search tools using regex pattern (matches tool_search_tool_regex behavior)
   */
  searchRegex(pattern: string): ToolSearchResult[] {
    if (!pattern || pattern.length > 200) {
      console.error(`[tool-search] Invalid pattern: ${pattern?.substring(0, 50)}...`);
      return [];
    }

    try {
      const regex = new RegExp(pattern, 'i');
      const results: ToolSearchResult[] = [];

      for (const tool of this.tools) {
        let matched = false;
        let score = 0;

        // Search tool name (highest weight)
        if (this.config.searchFields.includes('name') && regex.test(tool.name)) {
          matched = true;
          score += 0.5;
        }

        // Search description
        if (this.config.searchFields.includes('description') && tool.description && regex.test(tool.description)) {
          matched = true;
          score += 0.3;
        }

        // Search argument names
        if (this.config.searchFields.includes('args') && tool.inputSchema?.properties) {
          const argNames = Object.keys(tool.inputSchema.properties);
          const argDescriptions = Object.values(tool.inputSchema.properties)
            .map((p: any) => p.description || '')
            .filter(Boolean);

          const argText = [...argNames, ...argDescriptions].join(' ');
          if (regex.test(argText)) {
            matched = true;
            score += 0.2;
          }
        }

        if (matched && score >= this.config.minScore) {
          results.push({
            toolName: tool.name,
            serverId: tool.serverId,
            score,
          });
        }
      }

      // Sort by score descending, limit results
      return results
        .sort((a, b) => b.score - a.score)
        .slice(0, this.config.maxResults);
    } catch (error: any) {
      console.error(`[tool-search] Regex error: ${error.message}`);
      return [];
    }
  }

  /**
   * Search tools using natural language query (BM25-style)
   * Uses simple term frequency matching
   */
  searchNaturalLanguage(query: string): ToolSearchResult[] {
    if (!query) {
      return [];
    }

    // Tokenize query
    const queryTerms = query.toLowerCase().split(/\s+/).filter(t => t.length > 1);
    if (queryTerms.length === 0) {
      return [];
    }

    const results: ToolSearchResult[] = [];

    for (const tool of this.tools) {
      // Build searchable text for this tool
      const searchableText = this.buildSearchableText(tool).toLowerCase();

      // Calculate simple term frequency score
      let matchedTerms = 0;
      for (const term of queryTerms) {
        if (searchableText.includes(term)) {
          matchedTerms++;
        }
      }

      const score = matchedTerms / queryTerms.length;

      if (score >= this.config.minScore) {
        results.push({
          toolName: tool.name,
          serverId: tool.serverId,
          score,
        });
      }
    }

    return results
      .sort((a, b) => b.score - a.score)
      .slice(0, this.config.maxResults);
  }

  /**
   * Build searchable text from tool info
   */
  private buildSearchableText(tool: ToolInfo): string {
    const parts: string[] = [];

    if (this.config.searchFields.includes('name')) {
      // Split camelCase and snake_case for better matching
      parts.push(tool.name.replace(/([a-z])([A-Z])/g, '$1 $2').replace(/_/g, ' '));
    }

    if (this.config.searchFields.includes('description') && tool.description) {
      parts.push(tool.description);
    }

    if (this.config.searchFields.includes('args') && tool.inputSchema?.properties) {
      for (const [argName, argSchema] of Object.entries(tool.inputSchema.properties)) {
        parts.push(argName.replace(/_/g, ' '));
        if ((argSchema as any).description) {
          parts.push((argSchema as any).description);
        }
      }
    }

    return parts.join(' ');
  }

  /**
   * Get tool by name
   */
  getTool(toolName: string): ToolInfo | undefined {
    return this.tools.find(t => t.name === toolName);
  }

  /**
   * Get all indexed tools
   */
  getAllTools(): ToolInfo[] {
    return this.tools;
  }

  /**
   * Get tool count
   */
  getToolCount(): number {
    return this.tools.length;
  }
}

/**
 * Create the tool_search tool definition for the gateway
 */
export function createToolSearchToolDefinition() {
  return {
    name: 'tool_search',
    description:
      'Search for available tools across all connected MCP servers. ' +
      'Use this to discover tools when you need specific functionality. ' +
      'Returns tool names that can then be called directly. ' +
      'Supports both regex patterns and natural language queries.',
    inputSchema: {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description: 'Search query - can be a regex pattern or natural language description of needed functionality',
        },
        mode: {
          type: 'string',
          enum: ['regex', 'natural'],
          description: 'Search mode: "regex" for pattern matching, "natural" for natural language (default: natural)',
        },
      },
      required: ['query'],
    },
  };
}

/**
 * Format search results as tool_reference content blocks
 * This is the format expected by the Claude API for custom tool search
 */
export function formatAsToolReferences(results: ToolSearchResult[]): any[] {
  return results.map(result => ({
    type: 'tool_reference',
    tool_name: result.toolName,
  }));
}

/**
 * Format search results as a human-readable response
 * (Alternative format if tool_reference isn't supported by the client)
 */
export function formatAsTextResult(results: ToolSearchResult[]): string {
  if (results.length === 0) {
    return 'No matching tools found.';
  }

  const lines = ['Found matching tools:'];
  for (const result of results) {
    lines.push(`- ${result.toolName} (from: ${result.serverId})`);
  }
  return lines.join('\n');
}

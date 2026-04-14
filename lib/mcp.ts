/**
 * Module-level session cache. Intended for short-lived CLI processes:
 * one invocation = one session. If retried-on-400 fires more than once
 * per process the client surfaces the HTTP error rather than looping.
 * Do NOT import mcpCall from a long-running process without adding
 * expiry-aware retry bookkeeping.
 *
 * SSE parsing assumes single-event frames with one `data:` line, which
 * matches what @modelcontextprotocol/sdk's StreamableHTTPServerTransport
 * emits today. Revisit parseSseResult if the server ever multiplexes.
 */
const MCP_URL = process.env.P2E_MCP_URL ?? 'http://localhost:3000/api/mcp'

/**
 * AU-02-L1: every MCP request requires an Authorization: Bearer header.
 * Throws a clear error at invocation time if P2E_DEV_BEARER is not set.
 */
function getBearerHeaders(): Record<string, string> {
  const token = process.env.P2E_DEV_BEARER
  if (!token) {
    throw new Error(
      'P2E_DEV_BEARER env var is not set.\n' +
        'Run the OAuth bootstrap to get a token:\n' +
        '  See README.md → "MCP OAuth Bootstrap"',
    )
  }
  return { Authorization: `Bearer ${token}` }
}

interface Session {
  id: string
}

let currentSession: Session | null = null

export function __resetSessionForTest(): void {
  currentSession = null
}

async function initSession(): Promise<Session> {
  const initRes = await fetch(MCP_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json, text/event-stream',
      ...getBearerHeaders(),
    },
    body: JSON.stringify({
      jsonrpc: '2.0',
      id: 1,
      method: 'initialize',
      params: {
        protocolVersion: '2025-06-18',
        capabilities: {},
        clientInfo: { name: 'p2e-plugin', version: '0.1.0' },
      },
    }),
  })
  if (!initRes.ok) {
    throw new Error(`MCP initialize failed: HTTP ${initRes.status}`)
  }
  const sid = initRes.headers.get('mcp-session-id')
  if (!sid) throw new Error('MCP initialize returned no mcp-session-id header')

  const notifRes = await fetch(MCP_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json, text/event-stream',
      'mcp-session-id': sid,
      ...getBearerHeaders(),
    },
    body: JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }),
  })
  if (!notifRes.ok && notifRes.status !== 202) {
    throw new Error(`MCP notifications/initialized failed: HTTP ${notifRes.status}`)
  }

  return { id: sid }
}

export function parseSseResult(body: string): unknown {
  for (const line of body.split('\n')) {
    if (!line.startsWith('data: ')) continue
    const parsed = JSON.parse(line.slice(6))
    if (parsed.error) {
      throw new Error(`MCP protocol error: ${parsed.error.message ?? JSON.stringify(parsed.error)}`)
    }
    const result = parsed.result
    if (!result) continue
    const textNode = result.content?.[0]?.text
    if (result.isError) {
      throw new Error(typeof textNode === 'string' ? textNode : 'MCP tool returned isError=true')
    }
    if (typeof textNode !== 'string') {
      throw new Error('MCP tool response had no text content')
    }
    try {
      return JSON.parse(textNode)
    } catch {
      return textNode
    }
  }
  throw new Error('no MCP data line in SSE response')
}

export async function mcpCall<T = unknown>(
  name: string,
  args: Record<string, unknown>,
  opts: { retried?: boolean } = {},
): Promise<T> {
  if (!currentSession) currentSession = await initSession()
  const res = await fetch(MCP_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json, text/event-stream',
      'mcp-session-id': currentSession.id,
      ...getBearerHeaders(),
    },
    body: JSON.stringify({
      jsonrpc: '2.0',
      id: Date.now(),
      method: 'tools/call',
      params: { name, arguments: args },
    }),
  })
  if (res.status === 400 && !opts.retried) {
    currentSession = null
    return mcpCall<T>(name, args, { retried: true })
  }
  if (!res.ok) {
    throw new Error(`MCP call ${name} failed: HTTP ${res.status}`)
  }
  const text = await res.text()
  return parseSseResult(text) as T
}

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mcpCall, parseSseResult, __resetSessionForTest } from './mcp'

describe('parseSseResult', () => {
  it('extracts a JSON object from a single data: line and unwraps the text payload', () => {
    const body = 'event: message\ndata: {"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"{\\"ok\\":true}"}]}}\n\n'
    expect(parseSseResult(body)).toEqual({ ok: true })
  })

  it('throws when the result is flagged isError', () => {
    const body = 'data: {"jsonrpc":"2.0","id":1,"result":{"isError":true,"content":[{"type":"text","text":"boom"}]}}\n\n'
    expect(() => parseSseResult(body)).toThrow(/boom/)
  })

  it('throws when no data: line is present', () => {
    expect(() => parseSseResult('event: noop\n\n')).toThrow(/no MCP data line/)
  })
})

// TODO(D-01-L2): Requires live OAuth bootstrap. Unblock by setting up a CI fixture bearer token
// issuance + permanent OAuthClient row. Until then, gate on P2E_DEV_BEARER being present.
describe.runIf(process.env.P2E_DEV_BEARER)('mcpCall', () => {
  beforeEach(() => {
    __resetSessionForTest()
    vi.restoreAllMocks()
  })

  it('initializes a session on first call, then calls the tool with mcp-session-id', async () => {
    const fetchMock = vi.fn()
      // initialize
      .mockResolvedValueOnce(new Response(null, { status: 200, headers: { 'mcp-session-id': 'sid-1' } }))
      // notifications/initialized
      .mockResolvedValueOnce(new Response(null, { status: 200 }))
      // tools/call
      .mockResolvedValueOnce(new Response(
        'data: {"jsonrpc":"2.0","id":3,"result":{"content":[{"type":"text","text":"{\\"hello\\":\\"world\\"}"}]}}\n\n',
        { status: 200, headers: { 'content-type': 'text/event-stream' } }
      ))
    vi.stubGlobal('fetch', fetchMock)

    const result = await mcpCall('ping', {})
    expect(result).toEqual({ hello: 'world' })
    const toolsCall = fetchMock.mock.calls[2][1] as RequestInit
    expect((toolsCall.headers as Record<string, string>)['mcp-session-id']).toBe('sid-1')
    expect((toolsCall.headers as Record<string, string>).Accept).toContain('text/event-stream')
    const toolsBody = JSON.parse(toolsCall.body as string)
    expect(toolsBody.method).toBe('tools/call')
    expect(toolsBody.params).toEqual({ name: 'ping', arguments: {} })
    const initCall = fetchMock.mock.calls[0][1] as RequestInit
    const initBody = JSON.parse(initCall.body as string)
    expect(initBody.method).toBe('initialize')
    expect(initBody.params.protocolVersion).toBe('2025-06-18')
  })

  it('re-initializes once on 400 and retries the call', async () => {
    const fetchMock = vi.fn()
      .mockResolvedValueOnce(new Response(null, { status: 200, headers: { 'mcp-session-id': 'sid-1' } }))
      .mockResolvedValueOnce(new Response(null, { status: 200 }))
      .mockResolvedValueOnce(new Response('expired', { status: 400 }))
      .mockResolvedValueOnce(new Response(null, { status: 200, headers: { 'mcp-session-id': 'sid-2' } }))
      .mockResolvedValueOnce(new Response(null, { status: 200 }))
      .mockResolvedValueOnce(new Response(
        'data: {"jsonrpc":"2.0","id":3,"result":{"content":[{"type":"text","text":"{\\"retry\\":true}"}]}}\n\n',
        { status: 200 }
      ))
    vi.stubGlobal('fetch', fetchMock)

    const result = await mcpCall('ping', {})
    expect(result).toEqual({ retry: true })
    expect(fetchMock.mock.calls.length).toBe(6)
    const retryToolsCall = fetchMock.mock.calls[5][1] as RequestInit
    expect((retryToolsCall.headers as Record<string, string>)['mcp-session-id']).toBe('sid-2')
  })
})

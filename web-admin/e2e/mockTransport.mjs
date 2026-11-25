export function createMockTransport({
  omitReadbackForRole,
  preexistingRecords = [],
  failDelete = false,
} = {}) {
  const records = new Map(preexistingRecords.map((record) => [record.id, record]))
  const requests = []
  let nextId = 1

  const jsonResponse = (status, payload) => ({
    status,
    async json() {
      return payload
    },
  })

  async function fetch(input, options = {}) {
    const url = new URL(input)
    if (url.protocol !== 'mock:') throw new Error('Mock transport refused a non-mock URL.')

    const method = options.method || 'GET'
    const pathname = url.pathname.replace(/^\/api\/v1\/?/, '')
    const role = options.headers?.['X-Mock-Role']
    requests.push({ method, pathname, role })
    if (method === 'POST' && pathname === 'admin/announcements') {
      if (!['admin', 'kaprodi'].includes(role)) return jsonResponse(403, { message: 'Forbidden' })
      const body = JSON.parse(options.body)
      const record = { id: nextId++, ...body }
      records.set(record.id, record)
      return jsonResponse(201, { status: 'Created', message: 'Created', data: record })
    }

    if (method === 'GET' && pathname === 'admin/announcements/list') {
      if (!role) return jsonResponse(401, { message: 'Unauthorized' })
      const visibleRecords = role === omitReadbackForRole
        ? []
        : [...records.values()]
      return jsonResponse(200, { status: 'OK', message: 'Listed', data: visibleRecords })
    }

    if (method === 'DELETE' && pathname === 'admin/announcements/delete') {
      if (role !== 'admin') return jsonResponse(403, { message: 'Forbidden' })
      if (failDelete) return jsonResponse(500, { message: 'Delete failed' })
      records.delete(Number(url.searchParams.get('id')))
      return jsonResponse(200, { status: 'OK', message: 'Deleted', data: null })
    }

    return jsonResponse(404, { message: 'Mock route not found' })
  }

  return { fetch, records, requests }
}

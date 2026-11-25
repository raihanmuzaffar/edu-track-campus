import axios from 'axios'

const baseURL = import.meta.env.VITE_API_BASE_URL || '/api/v1'

const api = axios.create({ baseURL })
let refreshRequest

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const request = error.config
    const isAuthRequest = /\/(login|register|forgot-password|reset-password|refresh-token|logout)$/.test(request?.url || '')
    if (error.response?.status !== 401 || !request || request._retry || isAuthRequest) {
      return Promise.reject(error)
    }

    const refreshToken = localStorage.getItem('refresh_token')
    if (!refreshToken) return Promise.reject(error)

    request._retry = true
    try {
      if (!refreshRequest) {
        refreshRequest = axios.post(`${baseURL}/refresh-token`, { refresh_token: refreshToken })
      }
      const response = await refreshRequest
      const tokens = response.data?.data
      if (!tokens?.token || !tokens?.refresh_token) {
        throw new Error('Respons refresh token tidak lengkap')
      }
      localStorage.setItem('token', tokens.token)
      localStorage.setItem('refresh_token', tokens.refresh_token)
      localStorage.setItem('role', tokens.role)
      request.headers.Authorization = `Bearer ${tokens.token}`
      return api(request)
    } catch (refreshError) {
      localStorage.removeItem('token')
      localStorage.removeItem('refresh_token')
      localStorage.removeItem('role')
      if (window.location.pathname !== '/') window.location.assign('/')
      return Promise.reject(refreshError)
    } finally {
      refreshRequest = undefined
    }
  },
)

export async function getAllRecords(path) {
  const first = await api.get(path, { params: { page: 1, limit: 100 } })
  const payload = first.data?.data
  let records
  let total
  let limit
  let currentPage

  if (Array.isArray(payload)) {
    records = payload
    total = Number(first.headers['x-total-count'])
    limit = Number(first.headers['x-limit']) || records.length || 100
    currentPage = Number(first.headers['x-page']) || 1
  } else if (Array.isArray(payload?.data)) {
    records = payload.data
    total = Number(payload.total_data)
    limit = Number(payload.limit) || 100
    currentPage = Number(payload.page) || 1
  } else {
    throw new Error(`Format daftar dari ${path} tidak sesuai kontrak API`)
  }

  const totalPages = Number.isFinite(total) && total > 0 ? Math.ceil(total / limit) : 1
  if (totalPages <= currentPage) return records

  const remaining = await Promise.all(
    Array.from({ length: totalPages - currentPage }, (_, index) =>
      api.get(path, { params: { page: currentPage + index + 1, limit } }),
    ),
  )

  return [
    ...records,
    ...remaining.flatMap((response) => {
      const data = response.data?.data
      if (Array.isArray(data)) return data
      if (Array.isArray(data?.data)) return data.data
      throw new Error(`Format daftar dari ${path} tidak sesuai kontrak API`)
    }),
  ]
}

export function getApiError(error, fallback = 'Terjadi kesalahan saat menghubungi server') {
  return error?.response?.data?.message || error?.message || fallback
}

export function getApiValidationField(error, fieldMap) {
  const status = error?.response?.status
  if (status !== 400 && status !== 422) return null

  const message = getApiError(error)
  const normalizedMessage = message.toLocaleLowerCase('id').replace(/[^a-z0-9]/g, '')
  const field = Object.entries(fieldMap).find(([apiField]) => {
    const normalizedField = apiField.toLocaleLowerCase('id').replace(/[^a-z0-9]/g, '')
    return normalizedMessage.includes(normalizedField)
  })?.[1]

  return field ? { field, message } : null
}

export async function endSession() {
  let error
  const token = localStorage.getItem('token')
  const refreshToken = localStorage.getItem('refresh_token')
  try {
    if (token) {
      try {
        await api.post('/logout', { refresh_token: refreshToken || '' })
      } catch (logoutError) {
        if (logoutError.response?.status !== 401 || !refreshToken) throw logoutError
        const response = await axios.post(`${baseURL}/refresh-token`, { refresh_token: refreshToken })
        const tokens = response.data?.data
        if (!tokens?.token || !tokens?.refresh_token) {
          throw new Error('Respons refresh token tidak lengkap', { cause: logoutError })
        }
        localStorage.setItem('token', tokens.token)
        localStorage.setItem('refresh_token', tokens.refresh_token)
        await api.post('/logout', { refresh_token: tokens.refresh_token })
      }
    }
  } catch (requestError) {
    error = requestError
  } finally {
    localStorage.removeItem('token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('role')
  }
  return error
}

export default api

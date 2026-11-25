import { useEffect, useState } from 'react'
import { Navigate, Outlet } from 'react-router-dom'
import api from '../services/api'

const dashboardForRole = {
  admin: '/admin',
  kaprodi: '/prodi',
}

export default function RequireRole({ allowedRoles }) {
  const [state, setState] = useState({ status: 'loading', user: null })
  const rolesKey = allowedRoles.join(',')

  useEffect(() => {
    let active = true
    api.get('/users/me')
      .then((response) => {
        if (active) setState({ status: 'ready', user: response.data?.data })
      })
      .catch((error) => {
        if (!active) return
        if (error.response?.status === 401) {
          localStorage.removeItem('token')
          localStorage.removeItem('refresh_token')
          localStorage.removeItem('role')
          setState({ status: 'unauthenticated', user: null })
          return
        }
        setState({ status: 'error', user: null })
      })
    return () => { active = false }
  }, [rolesKey])

  if (state.status === 'loading') {
    return <main className="auth-state" role="status">Memverifikasi sesi...</main>
  }
  if (state.status === 'error') {
    return <main className="auth-state" role="alert">Tidak dapat memverifikasi akun. Periksa koneksi, lalu muat ulang halaman.</main>
  }
  if (state.status === 'unauthenticated' || !state.user) {
    return <Navigate to="/" replace state={{ sessionExpired: true }} />
  }
  if (!allowedRoles.includes(state.user.role)) {
    return <Navigate to={dashboardForRole[state.user.role] || '/'} replace />
  }

  return <Outlet context={{ user: state.user }} />
}

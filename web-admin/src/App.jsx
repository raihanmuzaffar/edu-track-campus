import { Navigate, Route, Routes } from 'react-router-dom'
import Login from './pages/Login'
import AdminDashboard from './admin/AdminDashboard'
import ProdiDashboard from './prodi/ProdiDashboard'
import RequireRole from './components/RequireRole'

function App() {
  return (
    <Routes>
      <Route path="/" element={<Login />} />
      <Route element={<RequireRole allowedRoles={['admin']} />}>
        <Route path="/admin" element={<AdminDashboard />} />
      </Route>
      <Route element={<RequireRole allowedRoles={['kaprodi']} />}>
        <Route path="/prodi" element={<ProdiDashboard />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

export default App

import { Routes, Route } from 'react-router-dom'
import Login from './pages/Login'
import AdminDashboard from './admin/AdminDashboard' // Mengarah ke file baru teman Anda
import ProdiDashboard from './prodi/ProdiDashboard'

function App() {
  return (
    <Routes>
      {/* Halaman Login */}
      <Route path="/" element={<Login />} />
      
      {/* Halaman Khusus Admin */}
      <Route path="/admin" element={<AdminDashboard />} />
      
      {/* Halaman Khusus Kaprodi */}
      <Route path="/prodi" element={<ProdiDashboard />} />
    </Routes>
  )
}

export default App
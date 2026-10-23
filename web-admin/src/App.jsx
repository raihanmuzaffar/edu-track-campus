import { Routes, Route } from 'react-router-dom'
import Login from './pages/Login'
import Dashboard from './Dashboard'
import './App.css'

function App() {
  return (
    <Routes>
      {/* Jika URL-nya "/", tampilkan halaman Login */}
      <Route path="/" element={<Login />} />
      
      {/* Jika URL-nya "/dashboard", tampilkan halaman Dashboard */}
      <Route path="/dashboard" element={<Dashboard />} />
    </Routes>
  )
}

export default App
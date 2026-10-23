import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import ProdiDashboard from './src/prodi/ProdiDashboard.jsx'

createRoot(document.getElementById('prodi-preview-root')).render(
  <StrictMode>
    <ProdiDashboard />
  </StrictMode>,
)

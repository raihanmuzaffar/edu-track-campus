// =============================================================================
// AdminHeader.jsx — Top-bar / header component
// =============================================================================
import { titles } from '../constants/adminData'
import { Icon } from './AdminUI'

export function AdminHeader({ page, setMobileOpen }) {
  return (
    <header className="admin-topbar">
      <div className="admin-topbar__left">
        <button
          className="admin-icon-button admin-menu-toggle"
          aria-label="Buka navigasi"
          onClick={() => setMobileOpen(true)}
        >
          <Icon name="menu" />
        </button>
        <div className="admin-breadcrumb">
          <span>EduTrack Campus</span>
          <b>›</b>
          <strong>{page === 'packages' ? 'Paket Semester' : titles[page]}</strong>
        </div>
      </div>
      <div className="admin-topbar__right">
        <span className="admin-live-date">
          {new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium' }).format(new Date())}
        </span>
        <span className="admin-user__avatar">AD</span>
      </div>
    </header>
  )
}

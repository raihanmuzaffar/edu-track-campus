// =============================================================================
// AdminSidebar.jsx — Sidebar navigation component
// =============================================================================
import { menuGroups } from '../constants/adminData'
import { Icon } from './AdminUI'

export function AdminSidebar({ page, navigate, mobileOpen, setMobileOpen }) {
  return (
    <aside className={`admin-sidebar${mobileOpen ? ' admin-sidebar--open' : ''}`}>
      <div className="admin-brand">
        <span className="admin-brand__mark">E</span>
        <span>
          <strong>EduTrack</strong>
          <small>ADMIN · TRKJ</small>
        </span>
        <button
          className="admin-icon-button admin-mobile-close"
          aria-label="Tutup menu"
          onClick={() => setMobileOpen(false)}
        >
          <Icon name="close" />
        </button>
      </div>

      <nav className="admin-academic-nav" aria-label="Navigasi dashboard admin">
        {menuGroups.map((group) => (
          <div className="admin-nav-group" key={group.title}>
            <span className="admin-sidebar__label">{group.title}</span>
            {group.items.map(([key, label, icon]) => {
              const isActive = page === key || (page === 'cases' && key === 'attendance')
              return (
                <button
                  key={key}
                  className={`admin-nav__item${isActive ? ' is-active' : ''}`}
                  aria-current={isActive ? 'page' : undefined}
                  onClick={() => navigate(key)}
                >
                  <Icon name={icon} />
                  <span>{label}</span>
                  {isActive && <i />}
                </button>
              )
            })}
          </div>
        ))}
      </nav>

      <div className="admin-sidebar__bottom">
        <div className="admin-sidebar-tip">
          <strong>Program studi</strong>
          <p>Teknologi Rekayasa Komputer Jaringan</p>
        </div>
        <div className="admin-user">
          <span className="admin-user__avatar">AD</span>
          <span>
            <strong>Admin Demo</strong>
            <small>Administrasi akademik</small>
          </span>
        </div>
      </div>
    </aside>
  )
}

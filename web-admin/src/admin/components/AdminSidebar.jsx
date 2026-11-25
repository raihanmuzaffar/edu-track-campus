import { menuGroups } from '../constants/adminData'
import { Icon } from './AdminUI'
import BrandLogo from '../../components/BrandLogo'

export function AdminSidebar({ page, navigate: setDashboardPage, mobileOpen, setMobileOpen, user, onLogout }) {
  return (
    <aside className={`admin-sidebar${mobileOpen ? ' admin-sidebar--open' : ''}`}>
      <div className="admin-brand">
        <BrandLogo compact />
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
                  onClick={() => setDashboardPage(key)}
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
          <strong>EduTrack Campus</strong>
          <p>Administrasi akademik</p>
        </div>
        <div className="admin-user">
          <span className="admin-user__avatar">{(user?.name || 'A').split(/\s+/).slice(0, 2).map((part) => part[0]).join('').toUpperCase()}</span>
          <span>
            <strong>{user?.name || 'Pengguna'}</strong>
            <small>{user?.role === 'admin' ? 'Administrator' : user?.role}</small>
          </span>
          <button
            type="button"
            className="admin-logout-icon-btn"
            title="Keluar dari sistem"
            aria-label="Logout"
            onClick={onLogout}
          >
            <Icon name="logout" size={16} />
          </button>
        </div>
        <button
          type="button"
          className="admin-logout-btn"
          onClick={onLogout}
        >
          <Icon name="logout" size={16} />
          <span>Keluar</span>
        </button>
      </div>
    </aside>
  )
}

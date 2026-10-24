import React from 'react';
import { prodiNavigation } from '../constants/prodiNavigation';

export default function ProdiSidebar({ activePage, onNavigate, hasUnreadRequests, onLogout }) {
  return (
    <aside className="prodi-sidebar">
      <a className="prodi-brand" href="#beranda" onClick={(event) => { event.preventDefault(); onNavigate('overview') }}>
        <span className="prodi-brand-mark">E</span>
        <span><strong>EduTrack</strong><small>Campus · Prodi</small></span>
      </a>
      
      <div className="prodi-sidebar-scroll">
        {prodiNavigation.map((group) => (
          <div className="prodi-nav-group" key={group.group}>
            <div className="prodi-sidebar-label">{group.group}</div>
            <nav aria-label={group.group}>
              {group.items.map((item) => (
                <button 
                  key={item.id} 
                  className={`prodi-nav-link${activePage === item.id ? ' is-active' : ''}`} 
                  onClick={() => onNavigate(item.id)} 
                  aria-current={activePage === item.id ? 'page' : undefined}
                >
                  <span className="prodi-nav-icon" aria-hidden="true">{item.icon}</span>
                  <span>{item.label}</span>
                  {item.id === 'requests' && hasUnreadRequests && <i className="prodi-nav-badge" aria-label="Ada pengajuan yang perlu ditinjau" />}
                </button>
              ))}
            </nav>
          </div>
        ))}
      </div>

      <div className="prodi-sidebar-profile">
        <span className="prodi-avatar prodi-avatar--profile">AW</span>
        <span><strong>Arman Wijaya</strong><small>Kaprodi · Demo</small></span>
        <span className="prodi-online-dot" />
        <button
          type="button"
          className="prodi-sidebar-logout-btn"
          title="Keluar dari akun"
          aria-label="Logout"
          onClick={onLogout}
        >
          <svg
            width="15"
            height="15"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
            <polyline points="16 17 21 12 16 7" />
            <line x1="21" y1="12" x2="9" y2="12" />
          </svg>
        </button>
      </div>
    </aside>
  );
}
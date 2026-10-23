import React from 'react';
import { prodiNavigation } from '../constants/prodiNavigation';

export default function ProdiSidebar({ activePage, onNavigate, hasUnreadRequests }) {
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
      </div>
    </aside>
  );
}
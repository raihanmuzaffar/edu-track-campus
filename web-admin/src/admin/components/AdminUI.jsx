// =============================================================================
// AdminUI.jsx — Reusable presentational / UI components
// =============================================================================
import { useEffect } from 'react'

// ---------------------------------------------------------------------------
// Icon paths (SVG fragments)
// ---------------------------------------------------------------------------
const iconPaths = {
  grid: <><rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" /><rect x="3" y="14" width="7" height="7" rx="1" /><rect x="14" y="14" width="7" height="7" rx="1" /></>,
  users: <><path d="M16 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="10" cy="7" r="4" /><path d="M20 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" /></>,
  book: <><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2Z" /></>,
  clock: <><circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" /></>,
  file: <><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><path d="M14 2v6h6M8 13h8M8 17h8" /></>,
  chart: <><path d="M3 3v18h18" /><path d="m19 9-5 5-4-4-5 5" /></>,
  wallet: <><rect x="3" y="5" width="18" height="15" rx="2" /><path d="M3 8h15a3 3 0 0 1 3 3v2h-5a2 2 0 0 0 0 4h5M17 13h.01" /><path d="M5 5V4a2 2 0 0 1 2-2h11" /></>,
  check: <><path d="M22 11.1V12a10 10 0 1 1-5.93-9.14" /><path d="m9 11 3 3L22 4" /></>,
  megaphone: <><path d="m3 11 18-5v12L3 13v-2zM11.6 14.5l1.8 6.2-3.2.9-2.4-7.8" /><path d="M3 11v2a2 2 0 0 0 2 2h1" /></>,
  settings: <><circle cx="12" cy="12" r="3" /><path d="m19.4 15 .1.1 1.4 1.1-1.4 2.4-1.7-.6a8 8 0 0 1-1.5.9l-.3 1.8h-2.8l-.3-1.8a8 8 0 0 1-1.5-.9l-1.7.6-1.4-2.4 1.4-1.1a7 7 0 0 1 0-1.8l-1.4-1.1 1.4-2.4 1.7.6a8 8 0 0 1 1.5-.9l.3-1.8h2.8l.3 1.8a8 8 0 0 1 1.5.9l1.7-.6 1.4 2.4-1.4 1.1a7 7 0 0 1 0 1.7z" transform="translate(-2 -1)" /></>,
  menu: <><path d="M4 6h16M4 12h16M4 18h16" /></>,
  close: <><path d="m18 6-12 12M6 6l12 12" /></>,
  search: <><circle cx="11" cy="11" r="7" /><path d="m20 20-4-4" /></>,
  chevron: <path d="m9 18 6-6-6-6" />,
  plus: <path d="M12 5v14M5 12h14" />,
  download: <><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><path d="m7 10 5 5 5-5M12 15V3" /></>,
  upload: <><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><path d="m17 8-5-5-5 5M12 3v12" /></>,
  logout: <><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" y1="12" x2="9" y2="12" /></>,
}

// ---------------------------------------------------------------------------
// Icon
// ---------------------------------------------------------------------------
export function Icon({ name, size = 17 }) {
  return (
    <svg
      aria-hidden="true"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {iconPaths[name] || iconPaths.grid}
    </svg>
  )
}

// ---------------------------------------------------------------------------
// Badge
// ---------------------------------------------------------------------------
export function Badge({ children }) {
  const text = String(children || '')
  const tone =
    /tidak bentrok|tidak ada/i.test(text) ? 'success'
    : /dipublikasikan|aktif|lunas|lengkap|siap|diterbitkan/i.test(text) ? 'success'
    : /draf|belum|tunggak|perlu|bentrok|sebagian|cuti/i.test(text) ? 'warning'
    : /nonaktif|berakhir|ditutup/i.test(text) ? 'muted'
    : 'neutral'
  return (
    <span className={`admin-badge admin-badge--${tone}`}>
      <i className="admin-badge__dot" />
      {text}
    </span>
  )
}

// ---------------------------------------------------------------------------
// Stat card
// ---------------------------------------------------------------------------
export function Stat({ title, value, note, icon }) {
  return (
    <article className="admin-stat-card">
      <div className="admin-stat-card__top">
        <span>{title}</span>
        <i><Icon name={icon} size={17} /></i>
      </div>
      <strong className="admin-stat-card__value">{value}</strong>
      <span className="admin-stat-card__note">{note}</span>
    </article>
  )
}

// ---------------------------------------------------------------------------
// Page / Panel headings
// ---------------------------------------------------------------------------
export function PageHeading({ title, subtitle, actions }) {
  return (
    <div className="admin-page-heading">
      <div>
        <span className="admin-eyebrow">ADMINISTRASI AKADEMIK · TRKJ</span>
        <h1>{title}</h1>
        <p>{subtitle}</p>
      </div>
      {actions}
    </div>
  )
}

export function PanelHeading({ title, subtitle, action }) {
  return (
    <div className="admin-panel-heading">
      <div>
        <h2>{title}</h2>
        <p>{subtitle}</p>
      </div>
      {action}
    </div>
  )
}

// ---------------------------------------------------------------------------
// ActivityList
// ---------------------------------------------------------------------------
export function ActivityList({ items }) {
  return (
    <div className="admin-activity-list">
      {items.map((item) => (
        <div className="admin-activity-row" key={item.id}>
          <span className="admin-activity-dot"><Icon name="clock" size={13} /></span>
          <div>
            <strong>{item.message}</strong>
            <small>
              {new Intl.DateTimeFormat('id-ID', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(item.time))}
              {' · '}{item.category}
            </small>
          </div>
          <Badge>{item.status}</Badge>
        </div>
      ))}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Table (internal helper)
// ---------------------------------------------------------------------------
function rowActionButton(row, onDetail) {
  return (
    <button
      className="admin-row-action"
      aria-label={`Detail ${row.name || row.student || row.class || row.code || row.title || row.kategori || ''}`}
      title="Lihat detail"
      onClick={() => onDetail?.(row)}
    >
      <Icon name="search" size={15} />
    </button>
  )
}

export function Table({ columns, rows, onSort, sort, renderCell, renderAction, onDetail, emptyMessage }) {
  return (
    <table className="admin-table">
      <thead>
        <tr>
          {columns.map(([key, label]) => (
            <th key={key}>
              <button className="admin-sort-button" onClick={() => onSort?.(key)}>
                {label}
                {onSort && (
                  <span>
                    {sort?.key === key ? (sort.direction === 'asc' ? '↑' : '↓') : '↕'}
                  </span>
                )}
              </button>
            </th>
          ))}
          <th key="actions">Tindakan</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((row, index) => (
          <tr key={row.id ?? `${columns[0]?.[0] || 'row'}-${index}`}>
            {columns.map(([key]) => (
              <td key={key}>
                {renderCell
                  ? renderCell(row, key)
                  : key === 'status'
                  ? <Badge>{row[key]}</Badge>
                  : row[key] ?? '—'}
              </td>
            ))}
            <td key="actions">
              <div className="admin-row-actions">
                {rowActionButton(row, onDetail)}
                {renderAction?.(row)}
              </div>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}

// ---------------------------------------------------------------------------
// Modal
// ---------------------------------------------------------------------------
export function Modal({ title, onClose, children }) {
  useEffect(() => {
    const closeOnEscape = (event) => { if (event.key === 'Escape') onClose() }
    window.addEventListener('keydown', closeOnEscape)
    return () => window.removeEventListener('keydown', closeOnEscape)
  }, [onClose])

  return (
    <div
      className="admin-modal-backdrop"
      onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}
    >
      <section className="admin-modal" role="dialog" aria-modal="true" aria-label={title}>
        <header className="admin-modal__header">
          <h2>{title}</h2>
          <button className="admin-icon-button" aria-label="Tutup dialog" onClick={onClose}>
            <Icon name="close" />
          </button>
        </header>
        <div className="admin-modal__body">{children}</div>
      </section>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Preference toggle (settings page)
// ---------------------------------------------------------------------------
export function Preference({ title, checked, onChange }) {
  return (
    <label className="admin-preference">
      <span>{title}</span>
      <input type="checkbox" checked={checked} onChange={onChange} />
    </label>
  )
}

import './BrandLogo.css'

export default function BrandLogo({ compact = false, subtitle = 'CAMPUS' }) {
  return (
    <div className={`brand-logo${compact ? ' brand-logo--compact' : ''}`}>
      <span className="brand-logo__mark" aria-hidden="true">
        E
      </span>
      <span className="brand-logo__text">
        <strong>EduTrack</strong>
        {!compact && <small>{subtitle}</small>}
      </span>
    </div>
  )
}

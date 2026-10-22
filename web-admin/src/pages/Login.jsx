import { useState } from 'react'
import '../App.css'

function Login() {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [feedback, setFeedback] = useState(null)

  function handleSubmit(event) {
    event.preventDefault()

    if (!username.trim() || !password) {
      setFeedback({
        type: 'error',
        text: 'Masukkan email atau username dan kata sandi Anda.',
      })
      return
    }

    setFeedback({
      type: 'info',
      text: 'Integrasi autentikasi belum tersedia. Login belum dapat dilakukan.',
    })
  }

  function clearFeedback() {
    if (feedback) setFeedback(null)
  }

  return (
    <main className="login-page">
      <section className="login-card" aria-labelledby="login-title">
        <header className="card-header">
          <div className="brand">
            <span className="brand-mark" aria-hidden="true">
              E
            </span>
            <span id="brand-name">EduTrack Campus</span>
          </div>
        </header>

        <div className="login-heading">
          <h1 id="login-title">Masuk ke EduTrack Campus</h1>
          <p>Sistem Informasi Akademik</p>
        </div>

        <form className="login-form" onSubmit={handleSubmit} noValidate>
          <div className="form-field">
            <label htmlFor="username">Email atau username</label>
            <input
              id="username"
              name="username"
              type="text"
              autoComplete="username"
              value={username}
              onChange={(event) => {
                setUsername(event.target.value)
                clearFeedback()
              }}
              aria-invalid={feedback?.type === 'error' && !username.trim()}
              aria-describedby={feedback ? 'form-feedback' : undefined}
              required
            />
          </div>

          <div className="form-field">
            <label htmlFor="password">Kata sandi</label>
            <div className="password-field">
              <input
                id="password"
                name="password"
                type={showPassword ? 'text' : 'password'}
                autoComplete="current-password"
                value={password}
                onChange={(event) => {
                  setPassword(event.target.value)
                  clearFeedback()
                }}
                aria-invalid={feedback?.type === 'error' && !password}
                aria-describedby={feedback ? 'form-feedback' : undefined}
                required
              />

              <button
                className="password-toggle"
                type="button"
                aria-label={
                  showPassword
                    ? 'Sembunyikan kata sandi'
                    : 'Tampilkan kata sandi'
                }
                aria-pressed={showPassword}
                onClick={() => setShowPassword((visible) => !visible)}
              >
                {showPassword ? 'Sembunyikan' : 'Tampilkan'}
              </button>
            </div>
          </div>

          {feedback && (
            <p
              className={`form-feedback form-feedback--${feedback.type}`}
              id="form-feedback"
              role={feedback.type === 'error' ? 'alert' : 'status'}
            >
              {feedback.text}
            </p>
          )}

          <button className="submit-button" type="submit">
            Masuk
          </button>
        </form>
      </section>
    </main>
  )
}

export default Login
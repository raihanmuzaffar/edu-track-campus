import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import api from "../services/api";
import "../App.css";

// 1. Nama fungsi diubah menjadi Login
export default function Login() {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  
  // 2. Backtick (``) yang nyasar di baris ini sudah dihapus
  const [feedback, setFeedback] = useState(null) 
  
  const [isLoading, setIsLoading] = useState(false)

  const navigate = useNavigate()

  async function handleSubmit(event) {
    event.preventDefault()
    setFeedback(null)

    if (!username.trim() || !password) {
      setFeedback({
        type: 'error',
        text: 'Masukkan email atau username dan kata sandi Anda.',
      })
      return
    }

    setIsLoading(true)

    try {
      const response = await api.post('/login', {
        email: username,
        password: password
      })

      const { token, role } = response.data.data

      if (role === 'admin' || role === 'kaprodi') {
        localStorage.setItem('token', token)
        localStorage.setItem('role', role)
        
        setFeedback({
          type: 'info',
          text: 'Login berhasil! Mengalihkan ke dashboard...',
        })

        setTimeout(() => {
          // --- PERUBAHAN DI SINI ---
          // Arahkan ke halaman yang berbeda berdasarkan role
          if (role === 'admin') {
            navigate('/admin')
          } else if (role === 'kaprodi') {
            navigate('/prodi')
          }
          // -------------------------
        }, 1000)
      } else {
        setFeedback({
          type: 'error',
          text: 'Akses Ditolak: Hanya Admin dan Kaprodi yang dapat mengakses Web Admin.',
        })
      }

    } catch (error) {
      const errorMessage = error.response?.data?.message || 'Terjadi kesalahan jaringan atau server mati.'
      setFeedback({
        type: 'error',
        text: errorMessage,
      })
    } finally {
      setIsLoading(false)
    }
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
              type="email"
              autoComplete="username"
              value={username}
              onChange={(event) => {
                setUsername(event.target.value)
                clearFeedback()
              }}
              aria-invalid={feedback?.type === 'error' && !username.trim()}
              aria-describedby={feedback ? 'form-feedback' : undefined}
              required
              disabled={isLoading}
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
                disabled={isLoading}
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
                disabled={isLoading}
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

          <button className="submit-button" type="submit" disabled={isLoading}>
            {isLoading ? 'Memproses...' : 'Masuk'}
          </button>
        </form>
      </section>
    </main>
  )
}
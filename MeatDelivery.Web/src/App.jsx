import { useState, useRef, useEffect } from 'react'
import './App.css'

const API = 'http://localhost:5147/api/v1'

function RateBar({ used, max }) {
  const pct = Math.min((used / max) * 100, 100)
  const cls = pct >= 100 ? 'full' : pct >= 66 ? 'warn' : ''
  return (
    <div className="rate-bar">
      <div className="rate-bar-label">
        <span>OTP requests this window</span>
        <span>{used}/{max}</span>
      </div>
      <div className="rate-bar-track">
        <div className="rate-bar-fill" style={{ width: `${pct}%` }} />
      </div>
    </div>
  )
}

function StepIndicator({ step }) {
  return (
    <div className="steps">
      <div className={`step ${step === 1 ? 'active' : 'done'}`}>1</div>
      <div className={`step-line ${step > 1 ? 'done' : ''}`} />
      <div className={`step ${step === 2 ? 'active' : step > 2 ? 'done' : 'inactive'}`}>2</div>
      <div className={`step-line ${step > 2 ? 'done' : ''}`} />
      <div className={`step ${step === 3 ? 'active done' : 'inactive'}`}>✓</div>
    </div>
  )
}

export default function App() {
  const [step, setStep]           = useState(1)   // 1=send, 2=verify, 3=success
  const [loading, setLoading]     = useState(false)
  const [error, setError]         = useState('')
  const [info, setInfo]           = useState('')
  const [countdown, setCountdown] = useState(0)

  // Step 1 state
  const [country, setCountry]     = useState('+971')
  const [phone, setPhone]         = useState('')

  // Step 2 state
  const [otp, setOtp]             = useState(['','','','','',''])
  const [challengeId, setChallengeId] = useState('')
  const [resendCount, setResendCount] = useState(0)
  const [maxResend, setMaxResend] = useState(3)
  const otpRefs = useRef([])

  // Step 3 state
  const [authToken, setAuthToken] = useState('')
  const [isNew, setIsNew]         = useState(false)

  // Countdown timer
  useEffect(() => {
    if (countdown <= 0) return
    const t = setInterval(() => setCountdown(c => c - 1), 1000)
    return () => clearInterval(t)
  }, [countdown])

  const clearMessages = () => { setError(''); setInfo('') }

  // ─── SEND OTP ───────────────────────────────────────────
  async function handleSendOtp(e) {
    e.preventDefault()
    clearMessages()
    if (!phone.trim()) return setError('Please enter your phone number.')
    setLoading(true)
    try {
      const res = await fetch(`${API}/auth/send-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          countryCode: country,
          mobileNumber: phone.trim(),
          purpose: 'REGISTRATION'
        })
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data?.message || data?.title || 'Failed to send OTP.')
      const cid = data.challengeId || ''
      setChallengeId(cid)
      // Persist in localStorage so it survives page refresh
      if (cid) localStorage.setItem('otp_challenge_id', cid)
      setResendCount(data.resendCount || 1)
      setMaxResend(data.maxResendPerWindow || 3)
      setStep(2)
      setInfo('OTP sent! Check your phone (or console logs in dev mode).')
      setCountdown(30)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  // ─── RESEND OTP ──────────────────────────────────────────
  async function handleResend() {
    if (countdown > 0) return
    clearMessages()
    setLoading(true)
    try {
      const res = await fetch(`${API}/auth/send-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          countryCode: country,
          mobileNumber: phone.trim(),
          purpose: 'REGISTRATION'
        })
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data?.message || data?.title || 'Failed to resend OTP.')
      const cid = data.challengeId || ''
      setChallengeId(cid)
      // Update localStorage with new challengeId on resend
      if (cid) localStorage.setItem('otp_challenge_id', cid)
      setResendCount(data.resendCount || resendCount + 1)
      setOtp(['','','','','',''])
      otpRefs.current[0]?.focus()
      setInfo('New OTP sent!')
      setCountdown(30)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

function getDeviceId() {
  let id = localStorage.getItem('app_device_id')
  if (!id) {
    id = crypto.randomUUID()
    localStorage.setItem('app_device_id', id)
  }
  return id
}

  // ─── VERIFY OTP ──────────────────────────────────────────
  async function handleVerify(e) {
    e.preventDefault()
    clearMessages()
    const otpCode = otp.join('')
    if (otpCode.length < 6) return setError('Please enter the full 6-digit OTP.')
    setLoading(true)
    // Read challengeId from localStorage (fallback to state)
    const storedChallengeId = localStorage.getItem('otp_challenge_id') || challengeId
    try {
      const res = await fetch(`${API}/auth/verify-otp`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Device-Id': getDeviceId(),
          'X-Device-Type': 'WEB'
        },
        credentials: 'include',   // for HttpOnly refresh token cookie
        body: JSON.stringify({
          countryCode: country,
          mobileNumber: phone.trim(),
          otpCode,
          challengeId: storedChallengeId || undefined
        })
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data?.message || data?.title || 'OTP verification failed.')
      // ✅ Verified — remove challengeId from localStorage immediately
      localStorage.removeItem('otp_challenge_id')
      setAuthToken(data.accessToken || '')
      setIsNew(data.isNewUser ?? false)
      setStep(3)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  // ─── OTP input helpers ───────────────────────────────────
  function handleOtpChange(idx, val) {
    const digit = val.replace(/\D/g, '').slice(-1)
    const next = [...otp]; next[idx] = digit; setOtp(next)
    if (digit && idx < 5) otpRefs.current[idx + 1]?.focus()
  }
  function handleOtpKeyDown(idx, e) {
    if (e.key === 'Backspace' && !otp[idx] && idx > 0) otpRefs.current[idx - 1]?.focus()
  }
  function handleOtpPaste(e) {
    const text = e.clipboardData.getData('text').replace(/\D/g,'').slice(0,6)
    if (text.length) {
      setOtp(text.split('').concat(Array(6).fill('')).slice(0,6))
      otpRefs.current[Math.min(text.length, 5)]?.focus()
      e.preventDefault()
    }
  }

  function reset() {
    localStorage.removeItem('otp_challenge_id')
    setStep(1); setPhone(''); setOtp(['','','','','','']); setChallengeId(''); setAuthToken(''); clearMessages()
  }

  // ─── LOGOUT ──────────────────────────────────────────────
  async function handleLogout() {
    setLoading(true)
    clearMessages()
    try {
      await fetch(`${API}/auth/logout`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          countryCode: country,
          mobileNumber: phone.trim(),
          refreshToken: ''
        })
      })
    } catch {
      // Ignore network failures on logout
    } finally {
      reset()
      setInfo('Logged out successfully.')
      setLoading(false)
    }
  }

  // ─── RENDER ──────────────────────────────────────────────
  return (
    <div id="root">
      <div className="card">

        <div className="header">
          <div className="logo">🥩</div>
          <h1>Al Azeem Delivery</h1>
          <p>{step === 1 ? 'Enter your phone number to continue' : step === 2 ? 'Verify your phone number' : 'Welcome!'}</p>
        </div>

        <StepIndicator step={step} />

        {error && <div className="alert alert-error">⚠️ {error}</div>}
        {info  && <div className="alert alert-info">ℹ️ {info}</div>}

        {/* ── STEP 1: Send OTP ── */}
        {step === 1 && (
          <form onSubmit={handleSendOtp}>
            <div className="form-group">
              <label>Phone Number</label>
              <div className="phone-row">
                <select className="country-select" value={country} onChange={e => setCountry(e.target.value)}>
                  <option value="+971">🇦🇪 +971</option>
                  <option value="+91">🇮🇳 +91</option>
                  <option value="+1">🇺🇸 +1</option>
                  <option value="+44">🇬🇧 +44</option>
                </select>
                <input
                  type="tel" placeholder="507 123 456" value={phone}
                  onChange={e => setPhone(e.target.value)} autoFocus
                />
              </div>
            </div>
            <button className="btn btn-primary" type="submit" disabled={loading}>
              {loading ? <span className="spinner" /> : 'Send OTP →'}
            </button>
          </form>
        )}

        {/* ── STEP 2: Verify OTP ── */}
        {step === 2 && (
          <form onSubmit={handleVerify}>
            <div className="form-group">
              <label>6-Digit Code sent to {country} {phone}</label>
              <div className="otp-row" onPaste={handleOtpPaste}>
                {otp.map((d, i) => (
                  <input
                    key={i} type="text" maxLength={1} value={d}
                    inputMode="numeric" autoComplete="one-time-code"
                    ref={el => otpRefs.current[i] = el}
                    onChange={e => handleOtpChange(i, e.target.value)}
                    onKeyDown={e => handleOtpKeyDown(i, e)}
                    autoFocus={i === 0}
                  />
                ))}
              </div>
            </div>

            {challengeId && (
              <div className="badge">Challenge: {challengeId}</div>
            )}

            <RateBar used={resendCount} max={maxResend} />

            <button className="btn btn-primary" type="submit" disabled={loading} style={{marginTop: 18}}>
              {loading ? <span className="spinner" /> : 'Verify OTP ✓'}
            </button>

            <button
              type="button" className="btn btn-ghost"
              onClick={handleResend} disabled={loading || countdown > 0}
            >
              {countdown > 0 ? `Resend in ${countdown}s` : 'Resend OTP'}
            </button>

            <button type="button" className="btn btn-ghost" style={{marginTop:6,borderColor:'#374151',color:'#64748b'}} onClick={() => { setStep(1); clearMessages() }}>
              ← Change Number
            </button>
          </form>
        )}

        {/* ── STEP 3: Success ── */}
        {step === 3 && (
          <div>
            <div className="success-icon">{isNew ? '🎉' : '👋'}</div>
            <div className="alert alert-success" style={{textAlign:'center'}}>
              {isNew ? 'Account created successfully!' : 'Welcome back!'}
            </div>
            <div className="token-label">Access Token</div>
            <div className="token-box">{authToken || '(stored in memory)'}</div>
            <div className="token-label">Refresh Token</div>
            <div className="token-box">HttpOnly Cookie (not visible to JS ✓)</div>

            <button
              className="btn btn-primary"
              style={{ marginTop: 24, background: '#ef4444' }}
              onClick={handleLogout}
              disabled={loading}
            >
              {loading ? <span className="spinner" /> : 'Log Out 🚪'}
            </button>

            <button
              className="btn btn-ghost"
              style={{ marginTop: 8, borderColor: '#374151', color: '#64748b' }}
              onClick={reset}
            >
              ← Start Over
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

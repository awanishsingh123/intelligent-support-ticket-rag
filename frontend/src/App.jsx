import { useId, useRef, useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { AlertCircle } from 'lucide-react'
import './Form.css'

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

function validateField(name, value) {
  switch (name) {
    case 'first_name':
      if (!value.trim()) return 'Enter your first name.'
      return ''
    case 'last_name':
      if (!value.trim()) return 'Enter your last name.'
      return ''
    case 'email':
      if (!value.trim()) return 'Enter your email address.'
      if (!EMAIL_PATTERN.test(value.trim())) return 'Enter a valid email address.'
      return ''
    case 'phone':
      if (value && value.replace(/\D/g, '').length < 7) {
        return 'Enter a valid phone number, or leave this field blank.'
      }
      return ''
    case 'question':
      if (!value.trim()) return 'Describe your question.'
      if (value.trim().length < 10) return 'Add a bit more detail — at least 10 characters.'
      return ''
    default:
      return ''
  }
}

function App() {
  const navigate = useNavigate()
  const baseId = useId()
  const fieldId = (name) => `${baseId}-${name}`
  const errorId = (name) => `${fieldId(name)}-error`
  const formStatusRef = useRef(null)

  const [formData, setFormData] = useState({
    first_name: '',
    last_name: '',
    email: '',
    phone: '',
    question: '',
  })
  const [errors, setErrors] = useState({})
  const [status, setStatus] = useState({ tone: '', message: '', live: '' })
  const [loading, setLoading] = useState(false)
  const [touched, setTouched] = useState({})

  useEffect(() => {
    document.title = 'Submit a ticket'
  }, [])

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
    if (touched[name]) {
      const message = validateField(name, value)
      setErrors((prev) => ({ ...prev, [name]: message }))
    }
  }

  const handleBlur = (e) => {
    const { name, value } = e.target
    setTouched((prev) => ({ ...prev, [name]: true }))
    setErrors((prev) => ({ ...prev, [name]: validateField(name, value) }))
  }

  const validateAll = (data) => {
    const next = {}
    for (const name of Object.keys(data)) {
      const message = validateField(name, data[name])
      if (message) next[name] = message
    }
    return next
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (loading) return

    const nextErrors = validateAll(formData)
    setTouched({
      first_name: true,
      last_name: true,
      email: true,
      phone: true,
      question: true,
    })
    setErrors(nextErrors)

    if (Object.keys(nextErrors).length > 0) {
      const firstField = Object.keys(nextErrors)[0]
      setStatus({
        tone: 'error',
        message: 'Please fix the highlighted fields and try again.',
        live: 'Form has errors. Please fix the highlighted fields and try again.',
      })
      const el = document.getElementById(fieldId(firstField))
      if (el) el.focus()
      return
    }

    setStatus({ tone: '', message: '', live: '' })
    setLoading(true)

    try {
      const API_URL = import.meta.env.VITE_API_URL || ''
      const response = await fetch(`${API_URL}/support/submit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          first_name: formData.first_name.trim(),
          last_name: formData.last_name.trim(),
          email: formData.email.trim(),
          phone: formData.phone.trim() || null,
          question: formData.question.trim(),
        }),
      })

      const result = await response.json().catch(() => ({}))

      if (response.ok) {
        navigate('/thank-you', {
          state: {
            response: result.llm_response || '',
            userName: formData.first_name.trim(),
            ticketId: typeof result.id === 'number' ? result.id : null,
          },
        })
      } else {
        const detail = result?.detail
        const message =
          typeof detail === 'string'
            ? detail
            : Array.isArray(detail) && detail.length
              ? detail.map((d) => d?.msg || '').filter(Boolean).join('. ')
              : 'We could not submit your ticket. Please try again.'
        setStatus({ tone: 'error', message, live: message })
      }
    } catch (err) {
      const message = 'Network error. Check your connection and try again.'
      setStatus({ tone: 'error', message, live: message })
    } finally {
      setLoading(false)
    }
  }

  return (
    <main className="form-page">
      <div className="form-card">
        <header className="form-header">
          <h1>Submit a ticket</h1>
          <p>
            Tell us what is going on. We will look up the answer from our knowledge base and
            get back with a response immediately.
          </p>
        </header>

        <form className="support-form" onSubmit={handleSubmit} noValidate>
          <div className="form-row">
            <div className="form-group">
              <label htmlFor={fieldId('first_name')}>
                First name
                <span className="required-mark" aria-hidden="true">
                  *
                </span>
                <span className="sr-only"> (required)</span>
              </label>
              <input
                id={fieldId('first_name')}
                type="text"
                name="first_name"
                value={formData.first_name}
                onChange={handleChange}
                onBlur={handleBlur}
                autoComplete="given-name"
                spellCheck="false"
                aria-required="true"
                aria-invalid={Boolean(errors.first_name)}
                aria-describedby={errors.first_name ? errorId('first_name') : undefined}
                placeholder="Jordan"
              />
              <div id={errorId('first_name')} className="field-error" role="alert">
                {errors.first_name || ''}
              </div>
            </div>

            <div className="form-group">
              <label htmlFor={fieldId('last_name')}>
                Last name
                <span className="required-mark" aria-hidden="true">
                  *
                </span>
                <span className="sr-only"> (required)</span>
              </label>
              <input
                id={fieldId('last_name')}
                type="text"
                name="last_name"
                value={formData.last_name}
                onChange={handleChange}
                onBlur={handleBlur}
                autoComplete="family-name"
                spellCheck="false"
                aria-required="true"
                aria-invalid={Boolean(errors.last_name)}
                aria-describedby={errors.last_name ? errorId('last_name') : undefined}
                placeholder="Reyes"
              />
              <div id={errorId('last_name')} className="field-error" role="alert">
                {errors.last_name || ''}
              </div>
            </div>
          </div>

          <div className="form-group">
            <label htmlFor={fieldId('email')}>
              Email
              <span className="required-mark" aria-hidden="true">
                *
              </span>
              <span className="sr-only"> (required)</span>
            </label>
            <input
              id={fieldId('email')}
              type="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              onBlur={handleBlur}
              autoComplete="email"
              inputMode="email"
              spellCheck="false"
              aria-required="true"
              aria-invalid={Boolean(errors.email)}
              aria-describedby={errors.email ? errorId('email') : undefined}
              placeholder="jordan@example.com"
            />
            <div id={errorId('email')} className="field-error" role="alert">
              {errors.email || ''}
            </div>
          </div>

          <div className="form-group">
            <label htmlFor={fieldId('phone')}>
              Phone
              <span className="optional-tag">optional</span>
            </label>
            <input
              id={fieldId('phone')}
              type="tel"
              name="phone"
              value={formData.phone}
              onChange={handleChange}
              onBlur={handleBlur}
              autoComplete="tel"
              inputMode="tel"
              spellCheck="false"
              aria-invalid={Boolean(errors.phone)}
              aria-describedby={errors.phone ? errorId('phone') : undefined}
              placeholder="+1 555 123 4567"
            />
            <div id={errorId('phone')} className="field-error" role="alert">
              {errors.phone || ''}
            </div>
          </div>

          <div className="form-group">
            <label htmlFor={fieldId('question')}>
              Your question
              <span className="required-mark" aria-hidden="true">
                *
              </span>
              <span className="sr-only"> (required)</span>
            </label>
            <textarea
              id={fieldId('question')}
              name="question"
              value={formData.question}
              onChange={handleChange}
              onBlur={handleBlur}
              rows={5}
              aria-required="true"
              aria-invalid={Boolean(errors.question)}
              aria-describedby={errors.question ? errorId('question') : undefined}
              placeholder="Describe what is going on, including any error messages or steps you tried."
            />
            <div id={errorId('question')} className="field-error" role="alert">
              {errors.question || ''}
            </div>
          </div>

          <div
            ref={formStatusRef}
            className="form-status"
            data-tone={status.tone}
            role={status.tone ? 'status' : undefined}
            aria-live="polite"
            aria-atomic="true"
            hidden={!status.message}
          >
            {status.tone === 'error' && (
              <AlertCircle className="form-status-icon" aria-hidden="true" />
            )}
            <div className="form-status-text">{status.message}</div>
            <span className="sr-only">{status.live}</span>
          </div>

          <div className="submit-row">
            <p className="submit-hint">
              We will respond with an answer from our knowledge base within seconds.
            </p>
            <button
              type="submit"
              className="btn-primary"
              data-loading={loading || undefined}
              disabled={loading}
              aria-busy={loading}
            >
              <span className="btn-label">{loading ? 'Submitting' : 'Submit ticket'}</span>
              <span className="btn-spinner" aria-hidden="true">
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <circle
                    cx="12"
                    cy="12"
                    r="9"
                    stroke="currentColor"
                    strokeOpacity="0.35"
                    strokeWidth="2.5"
                  />
                  <path
                    d="M21 12a9 9 0 0 1-9 9"
                    stroke="currentColor"
                    strokeWidth="2.5"
                    strokeLinecap="round"
                  />
                </svg>
              </span>
            </button>
          </div>
        </form>
      </div>
    </main>
  )
}

export default App

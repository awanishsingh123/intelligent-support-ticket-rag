import { useEffect, useMemo } from 'react'
import { useLocation, Link } from 'react-router-dom'
import ReactMarkdown from 'react-markdown'
import { Check, ArrowRight, Info } from 'lucide-react'
import './ThankYou.css'

function ThankYou() {
  const location = useLocation()
  const state = location.state || {}
  const { response, userName } = state

  useEffect(() => {
    document.title = 'Your answer is ready'
  }, [])

  const greeting = useMemo(() => {
    const trimmed = (userName || '').trim()
    if (!trimmed) return 'Here is what we found.'
    return `Thanks, ${trimmed}. Here is what we found.`
  }, [userName])

  const hasResponse = typeof response === 'string' && response.trim().length > 0

  return (
    <main className="thankyou-page">
      <article className="thankyou-card">
        <header className="thankyou-header">
          <span className="thankyou-icon" aria-hidden="true">
            <Check strokeWidth={2.25} />
          </span>
          <div className="thankyou-header-text">
            <h1 className="thankyou-title">{greeting}</h1>
            <p className="thankyou-subtitle">
              An answer from our knowledge base, based on your question.
            </p>
          </div>
        </header>

        {hasResponse ? (
          <section className="response" aria-labelledby="response-heading">
            <div className="response-header">
              <Info className="response-header-icon" aria-hidden="true" />
              <h2 id="response-heading">Answer</h2>
            </div>
            <div className="response-body">
              <ReactMarkdown>{response}</ReactMarkdown>
            </div>
          </section>
        ) : (
          <section className="response" aria-labelledby="response-heading">
            <div className="response-header">
              <Info className="response-header-icon" aria-hidden="true" />
              <h2 id="response-heading">No answer</h2>
            </div>
            <div className="response-empty">
              <h2>We could not generate an answer for that question.</h2>
              <p>
                Submit a new ticket with a bit more detail and we will try again, or reach the
                team directly if the issue is urgent.
              </p>
            </div>
          </section>
        )}

        <div className="thankyou-footer">
          <p className="thankyou-footnote">
            Need to add detail? <Link to="/">Submit another ticket</Link>.
          </p>
          <Link to="/" className="btn-secondary">
            Submit another ticket
            <ArrowRight aria-hidden="true" />
          </Link>
        </div>
      </article>
    </main>
  )
}

export default ThankYou

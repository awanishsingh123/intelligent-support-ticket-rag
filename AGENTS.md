# AGENTS.md — Customer Support Ticket System

## Quick start

```powershell
# Terminal 1: backend
cd backend
.\venv\Scripts\activate
uvicorn app.main:app --reload --port 8000

# Terminal 2: frontend
cd frontend
npm install   # first time only
npm run dev   # serves on :3000, proxies /api & /support to :8000
```

## Architecture

- **Backend**: FastAPI (`backend/app/main.py`), SQLAlchemy async + PostgreSQL. Tables auto-created on startup via `Base.metadata.create_all`.
- **Frontend**: Vite + React 18 in `frontend/`, proxies `/support/**` to :8000.
- **RAG pipeline** (`backend/app/core/pipeline.py:4`): SVM classifier → Hybrid retriever (Pinecone 0.7 + BM25 0.3, per-category indices) → Cohere rerank → Groq LLM.

### Key directories

| Path | Purpose |
|---|---|
| `backend/` | FastAPI backend |
| `backend/app/` | Application package |
| `backend/app/api/routes.py` | Single endpoint: `POST /support/submit` |
| `backend/app/core/pipeline.py` | Orchestrates classify → retrieve → generate |
| `backend/app/rag/retriever.py` | Pinecone + per-category BM25 ensemble + Cohere compression |
| `backend/app/rag/generator.py` | Loads system prompt from `backend/app/prompts/generator_prompt.md` |
| `backend/app/classifier/` | SVM + TF-IDF (pickled models) |
| `backend/app/database/models/` | SQLAlchemy models: `users`, `queries` |
| `backend/scripts/ingest_knowledge.py` | Ingests `backend/data/clean.csv` into Pinecone + `rag_artifacts/` |
| `backend/data/` | Raw + cleaned CSV, EDA notebooks, analysis charts |
| `backend/rag_artifacts/` | Local BM25 artifacts: `knowledge_corpus.pkl`, `bm25_by_type.pkl` |
| `frontend/` | React SPA (Vite) |

## Prerequisites (required running services)

1. **PostgreSQL** — host/port per `backend/.env`
2. **Ollama** with model `qwen3-embedding:0.6b` pulled
3. API keys in `backend/.env`: `GROQ_API_KEY`, `COHERE_API_KEY`, `PINECONE_API_KEY`

## Commands

| Action | Command |
|---|---|
| Start backend | `cd backend; .\venv\Scripts\activate; uvicorn app.main:app --reload --port 8000` |
| Start frontend | `cd frontend; npm run dev` |
| Build frontend | `cd frontend; npm run build` |
| Rebuild Pinecone index | `cd backend; python -c "from scripts.ingest_knowledge import Knowledge; Knowledge().ingest_knowledge()"` |

## Important gotchas

- **No tests** — no test framework configured anywhere. `backend/evaluation/evaluate.py` and `backend/evaluation/test_queries.json` are empty stubs.
- **No linter/formatter/typechecker** configured (no pyproject.toml, no pre-commit, no ESLint).
- **Import quirk**: `backend/app/rag/retriever.py:8` imports from `langchain_classic` — this is a non-standard package name and may cause runtime errors. The intended imports (`EnsembleRetriever`, `ContextualCompressionRetriever`) historically live in `langchain.retrievers` or `langchain_community`.
- **Classifier models** (`backend/app/classifier/svm_model.pkl`, `tfidf.pkl`) are pre-trained and tracked in git.
- **Environment**: `backend/.env` is gitignored but contains real keys — do not commit. A `backend/.env.example` template is provided.
- **CORS**: backend whitelists `localhost:3000` and `127.0.0.1:3000` only.

## API

- `POST /support/submit` — accepts `SupportFormInput` (first_name, last_name, email, phone, question). Returns `{id, llm_response, created_at}`.
- `GET /` — `{"message": "Customer Support Ticket System API"}`
- `GET /health` — `{"status": "healthy"}`

## Design Context

- **Register**: product — design SERVES the product (support ticket form, restrained, earned familiarity).
- **Personality**: calm, expert, trustworthy. Voice is direct, sentence-case, no exclamation marks, no apology cascades.
- **Authoritative files**: `PRODUCT.md` (strategic), `DESIGN.md` (visual: OKLCH palette, type, motion, banned patterns).
- **Current code violation**: `frontend/src/Form.css`, `frontend/src/ThankYou.css`, `frontend/src/index.css` use the 2023-era purple-gradient AI default and are slated for replacement.
- **Color anchor**: burnt-honey primary `oklch(0.620 0.180 56)` on pure-white `oklch(1.000 0.000 0)` surface, with slate-blue accent `oklch(0.450 0.105 250)`. All colors in OKLCH; never hex.
- **Bans committed in DESIGN.md**: no purple/indigo gradients, no drop shadows > 8px blur, no border-radius > 16px on cards, no gradient text, no glassmorphism, no sketchy SVG, no uppercase tracked kickers, no `translateY(-2px)` hover bumps, no bounce/elastic easing.
- **Accessibility floor**: WCAG 2.2 AA. Body contrast ≥ 4.5:1, large text ≥ 3:1, focus rings never removed, `prefers-reduced-motion` honored, touch targets ≥ 44px, programmatic labels on all fields.
- **Live mode**: configured at `.impeccable/live/config.json` (Vite SPA, single shell `frontend/index.html`). CSP check returned no signals.

When working on frontend code, read `PRODUCT.md` and `DESIGN.md` first; their bans and tokens override any reflex defaults.

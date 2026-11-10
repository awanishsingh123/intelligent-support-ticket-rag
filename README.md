# Customer Support Ticket System

An intelligent, AI-powered support ticket system that classifies user queries, retrieves relevant knowledge, and generates contextual responses in real time via a Retrieval-Augmented Generation (RAG) pipeline.

- **User** submits a ticket through a web form.
- **SVM classifier** categorizes the question (billing, technical support, account, etc.).
- **Hybrid retriever** searches a knowledge base via Pinecone (vector similarity, 0.7 weight) and BM25 (keyword, 0.3 weight) with per-category indices.
- **Cohere reranker** compresses and re-ranks the top documents.
- **Groq LLM** (Llama 3.3 70B) generates a grounded, human-readable response.
- Ticket and response are persisted to PostgreSQL.

---

## Architecture

```
User ──► React SPA ──► FastAPI ──► SVM Classifier
                                      │
                                      ▼
                               Hybrid Retriever
                          ┌──────────┴──────────┐
                          ▼                      ▼
                    Pinecone (0.7)         BM25 (0.3)
                          │                      │
                          └──────────┬──────────┘
                                     ▼
                             Cohere Reranker
                                     │
                                     ▼
                               Groq LLM
                                     │
                                     ▼
                            Response + PostgreSQL
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Backend** | Python 3.11, FastAPI, Uvicorn |
| **Frontend** | React 18, Vite, React Router, react-markdown, Lucide icons |
| **Database** | PostgreSQL 16 (Supabase), SQLAlchemy async |
| **Vector Store** | Pinecone (cosine similarity) |
| **Keyword Search** | BM25 (`rank_bm25`) |
| **Embeddings** | Ollama — `qwen3-embedding:0.6b` |
| **Reranking** | Cohere — `rerank-english-v3.0` |
| **LLM** | Groq — `llama-3.3-70b-versatile` |
| **Classifier** | Scikit-learn SVM + TF-IDF (pre-trained) |
| **Language Detection** | `langdetect` |
| **Infrastructure** | Azure Container Apps, ACR, Key Vault, App Insights |
| **IaC** | Bicep |

---

## Project Structure

```
├── backend/                           # FastAPI backend
│   ├── app/
│   │   ├── main.py                    # App entrypoint, CORS, lifespan
│   │   ├── config.py                  # Pydantic settings, model factories
│   │   ├── api/
│   │   │   └── routes.py              # POST /support/submit
│   │   ├── core/
│   │   │   └── pipeline.py            # Classify → Retrieve → Generate
│   │   ├── classifier/
│   │   │   ├── model.py               # SVM + TF-IDF wrapper
│   │   │   ├── svm_model.pkl          # Pre-trained classifier
│   │   │   └── tfidf.pkl              # Pre-trained vectorizer
│   │   ├── rag/
│   │   │   ├── retriever.py           # Pinecone + BM25 + Cohere rerank
│   │   │   └── generator.py           # Prompt loading + LLM invocation
│   │   ├── database/
│   │   │   ├── base.py                # SQLAlchemy DeclarativeBase
│   │   │   ├── session.py             # Async engine + session factory
│   │   │   └── models/
│   │   │       ├── user.py            # User table (name, email, phone)
│   │   │       └── query.py           # Query table (question, response, timestamp)
│   │   ├── repositories/
│   │   │   └── support_repository.py  # get_or_create_user, save_query
│   │   ├── schemas/
│   │   │   └── support.py             # Pydantic: SupportFormInput, SupportResponse
│   │   └── prompts/
│   │       └── generator_prompt.md    # LLM system prompt
│   ├── scripts/
│   │   ├── ingest_knowledge.py        # CSV → Pinecone + BM25 artifacts
│   │   └── M1_2.ipynb                 # Data exploration notebook
│   ├── data/
│   │   ├── clean.csv                  # Cleaned knowledge base
│   │   ├── raw.csv
│   │   ├── cleaning.ipynb
│   │   └── analysis/                  # EDA charts
│   ├── evaluation/                    # Stubs (no test framework)
│   ├── rag_artifacts/                 # Local BM25 cache (gitignored)
│   ├── Dockerfile                     # Container image for Azure
│   ├── startup.sh
│   ├── runtime.txt
│   ├── requirements.txt
│   ├── .env                           # API keys + DB credentials (gitignored)
│   └── .env.example                   # Template for .env
├── frontend/                          # React SPA
│   ├── src/
│   │   ├── main.jsx                   # Entry point, BrowserRouter
│   │   ├── App.jsx                    # Support form component
│   │   ├── pages/
│   │   │   ├── ThankYou.jsx           # Response display (Markdown)
│   │   │   └── ThankYou.css
│   │   ├── tokens.css                 # Design system primitives (OKLCH)
│   │   ├── Form.css
│   │   └── index.css                  # Global reset, base, shell
│   ├── index.html
│   ├── vite.config.js                 # Dev proxy: /api, /support → :8000
│   ├── vite.config.js
│   ├── .env.production                # Prod API URL
│   └── package.json
├── infra/                             # Azure Bicep IaC
│   ├── azure.yaml                     # AZD config
│   ├── main.bicep                     # Orchestrator
│   └── modules/                       # Log Analytics, App Insights, ACR, etc.
├── .azure/
│   └── deployment-plan.md             # Deployment plan
├── deploy.ps1                         # Two-phase Azure deployment script
├── AGENTS.md
└── README.md
```

---

## Quick Start

### Prerequisites

| Service | Details |
|---|---|
| PostgreSQL | Running on host/port from `backend/.env` |
| Ollama | Model `qwen3-embedding:0.6b` pulled and accessible |
| Groq | API key in `backend/.env` |
| Cohere | API key in `backend/.env` |
| Pinecone | API key + pre-created index in `backend/.env` |

### Backend

```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Tables are auto-created on first startup. The backend starts at `http://localhost:8000`.

### Frontend

```powershell
cd frontend
npm install
npm run dev
```

The frontend starts at `http://localhost:3000` and proxies `/api` and `/support` to the backend.

---

## Environment Variables

Copy `backend/.env.example` to `backend/.env`:

| Variable | Description |
|---|---|
| `COHERE_API_KEY` | Cohere API key for reranking |
| `GROQ_API_KEY` | Groq API key for LLM inference |
| `PINECONE_API_KEY` | Pinecone API key for vector store |
| `PINECONE_INDEX_NAME` | Pinecone index name (e.g. `chat-ticket`) |
| `OLLAMA_BASE_URL` | Ollama server URL |
| `OLLAMA_API_KEY` | Ollama API key (optional) |
| `PGHOST` | PostgreSQL host |
| `PGPORT` | PostgreSQL port |
| `PGDATABASE` | PostgreSQL database name |
| `PGUSER` | PostgreSQL user |
| `PGPASSWORD` | PostgreSQL password |

---

## API

| Method | Path | Description |
|---|---|---|
| GET | `/` | API info |
| GET | `/health` | Health check |
| POST | `/support/submit` | Submit support ticket |

### POST /support/submit

```json
// Request
{
  "first_name": "Jordan",
  "last_name": "Reyes",
  "email": "jordan@example.com",
  "phone": "+1 (555) 123-4567",
  "question": "How do I reset my password?"
}

// Response
{
  "id": 1,
  "llm_response": "**Answer:** To reset your password...",
  "created_at": "2026-06-21T12:00:00Z"
}
```

---

## Data Ingestion

Rebuild the Pinecone index and BM25 artifacts from `backend/data/clean.csv`:

```powershell
cd backend
.\venv\Scripts\activate
python -c "from scripts.ingest_knowledge import Knowledge; Knowledge().ingest_knowledge()"
```

Requires a pre-existing Pinecone index (name set in `PINECONE_INDEX_NAME`).

---

## Azure Deployment

The system includes full Bicep infrastructure for Azure Container Apps.

### Resources

| Component | Azure Service |
|---|---|
| Backend API | Container App (Consumption, 0.5 CPU / 1Gi, min 1 replica) |
| Image Registry | Container Registry (Basic) |
| Monitoring | Log Analytics + Application Insights |
| Secrets | Key Vault (Standard, RBAC) |

### Deploy

```powershell
./deploy.ps1 -SubscriptionId "<id>" -ResourceGroup "rg-support-ticket" -Location "eastus"
```

This two-phase script:
1. Deploys infrastructure with a placeholder image
2. Builds and pushes the real image to ACR
3. Configures managed identity auth
4. Populates Key Vault secrets
5. Updates the Container App and verifies the health endpoint

---

## Design System

The frontend uses a calm, expert visual system defined in `frontend/src/tokens.css`:

- **Color**: OKLCH throughout — burnt honey primary (`oklch(0.620 0.180 56)`), slate-blue accent (`oklch(0.450 0.105 250)`), pure white surfaces
- **Type**: Inter Variable, fixed rem scale, sentence-case only
- **Motion**: `cubic-bezier(0.22, 1, 0.36, 1)` easing, `prefers-reduced-motion` honored
- **Accessibility**: WCAG 2.2 AA, focus rings never removed, touch targets ≥ 44px, ARIA labels on all fields
- **Banned**: No purple/indigo, no glassmorphism, no gradient text, no bounce easing, no `translateY(-2px)` hover bumps

---

## Notes

- Database tables auto-create on first startup via `Base.metadata.create_all`.
- The SVM classifier (`svm_model.pkl`, `tfidf.pkl`) is pre-trained and tracked in git.
- `backend/rag_artifacts/` must exist at startup for BM25. It is gitignored and can be regenerated via the ingestion script.
- Known issue: `from langchain_classic.retrievers import EnsembleRetriever` — the intended imports should come from `langchain.retrievers` or `langchain_community`.
- No test framework, linter, or type checker is currently configured.

# README.md

An AI-powered customer support application that classifies incoming support questions, retrieves relevant answers from a knowledge base, and generates a context-aware response using Retrieval-Augmented Generation (RAG).

The project combines a React frontend, a FastAPI backend, a hybrid retrieval pipeline, and PostgreSQL persistence.

## Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Knowledge-Base Ingestion](#knowledge-base-ingestion)
- [API Reference](#api-reference)
- [Database](#database)
- [Azure Deployment](#azure-deployment)
- [Important Implementation Notes](#important-implementation-notes)

## Overview

Users submit a support request through a web form. The backend processes the question through a multi-stage pipeline:

1. A pre-trained SVM model predicts the support category.
2. A priority rule checks the question for high- and medium-priority keywords.
3. A hybrid retriever finds relevant knowledge-base content using Pinecone vector search and BM25 keyword search.
4. Cohere reranks the retrieved documents.
5. Groq generates a response grounded in the retrieved context.
6. The user, question, generated response, category, and priority are stored in PostgreSQL.

The generated response is displayed on a dedicated results page in the frontend.

## How It Works

### Ticket-processing pipeline

| Stage | Implementation | Responsibility |
|---|---|---|
| Category classification | Scikit-learn SVM + TF-IDF | Predicts the support category |
| Priority detection | Keyword-based rules | Assigns High, Medium, or Low priority |
| Semantic retrieval | Pinecone | Finds semantically similar knowledge-base entries |
| Keyword retrieval | BM25 | Finds relevant entries through keyword matching |
| Hybrid retrieval | LangChain EnsembleRetriever | Combines vector and keyword results |
| Reranking | Cohere `rerank-english-v3.0` | Reranks and compresses retrieved context |
| Response generation | Groq `openai/gpt-oss-20b` | Generates a context-grounded answer |
| Persistence | PostgreSQL + SQLAlchemy async | Stores users and support queries |

### Retrieval strategy

The retriever combines two search methods:

- **Pinecone vector search — weight 0.7:** uses Ollama embeddings to find semantically related content.
- **BM25 keyword search — weight 0.3:** finds matches based on query terms.

Both retrievers use a retrieval size of 10. The implementation maintains BM25 retrievers by knowledge-base category and applies a category filter to Pinecone when a category is available. Cohere then reranks the combined results, with the configured reranker returning up to five documents.

## Key Features

- Support-ticket submission through a React form.
- Client-side validation for name, email, phone, and question fields.
- SVM-based ticket categorization.
- Rule-based priority detection (High, Medium, Low).
- Hybrid semantic and keyword retrieval.
- Category-aware retrieval.
- Cohere contextual reranking.
- LLM-generated answers grounded in retrieved knowledge.
- Language detection so the response can follow the language of the user's question.
- Persistent user and ticket records in PostgreSQL.
- Markdown rendering for generated answers.
- FastAPI health-check endpoint.
- Azure infrastructure templates using Bicep.

## Architecture

```text
                         CUSTOMER
                            |
                            v
                   React + Vite Frontend
                     Support Ticket Form
                            |
                            | POST /support/submit
                            v
                       FastAPI Backend
                            |
                            v
                  Ticket Processing Pipeline
                            |
                +-----------+-----------+
                |                       |
                v                       v
          SVM + TF-IDF             Priority Rules
        Category Prediction       High / Medium / Low
                |                       |
                +-----------+-----------+
                            |
                            v
                     Hybrid Retriever
                     /             \
                    v               v
             Pinecone Search      BM25 Search
              (weight 0.7)       (weight 0.3)
                    \               /
                     +------+------+
                            |
                            v
                     Cohere Reranker
                            |
                            v
                     Retrieved Context
                            |
                            v
                       Groq LLM
                  openai/gpt-oss-20b
                            |
                            v
                  Grounded Support Answer
                            |
                 +----------+----------+
                 |                     |
                 v                     v
             PostgreSQL          React Results Page
          User + Query Records     Markdown Answer
```

## Tech Stack

| Layer | Technology |
|---|---|
| Backend API | Python 3.11, FastAPI, Uvicorn |
| Frontend | React 18, Vite, React Router |
| UI libraries | Lucide React, react-markdown |
| Validation / settings | Pydantic, pydantic-settings |
| Classification | Scikit-learn, TF-IDF, SVM, Joblib |
| RAG orchestration | LangChain |
| Vector database | Pinecone |
| Keyword retrieval | BM25 via `rank_bm25` / LangChain community retriever |
| Embeddings | Ollama — `qwen3-embedding:0.6b` |
| Reranking | Cohere — `rerank-english-v3.0` |
| LLM | Groq — `openai/gpt-oss-20b` |
| Language detection | `langdetect` |
| Relational database | PostgreSQL |
| ORM / async driver | SQLAlchemy async, asyncpg |
| Cloud infrastructure | Azure Container Apps, Azure Container Registry, Key Vault |
| Monitoring | Azure Log Analytics, Application Insights |
| Infrastructure as Code | Bicep |

## Project Structure

```text
intelligent-support-ticket-rag/
|
|-- backend/
|   |-- app/
|   |   |-- main.py                    # FastAPI app, CORS, startup/shutdown lifecycle
|   |   |-- config.py                  # Environment settings and AI model configuration
|   |   |-- api/
|   |   |   \-- routes.py              # POST /support/submit
|   |   |-- core/
|   |   |   \-- pipeline.py            # Classification, priority, and generation orchestration
|   |   |-- classifier/
|   |   |   |-- model.py               # SVM + TF-IDF inference
|   |   |   |-- svm_model.pkl          # Pre-trained SVM model
|   |   |   \-- tfidf.pkl              # Pre-trained TF-IDF vectorizer
|   |   |-- rag/
|   |   |   |-- retriever.py           # Pinecone + BM25 hybrid retrieval and Cohere reranking
|   |   |   \-- generator.py           # Language detection, context, and LLM response
|   |   |-- database/
|   |   |   |-- base.py                # SQLAlchemy declarative base
|   |   |   |-- session.py             # Async engine and session dependency
|   |   |   \-- models/
|   |   |       |-- user.py            # User model
|   |   |       \-- query.py           # Support-query model
|   |   |-- repositories/
|   |   |   \-- support_repository.py # User lookup/creation and query persistence
|   |   |-- schemas/
|   |   |   \-- support.py             # Request and response schemas
|   |   \-- prompts/
|   |       \-- generator_prompt.md    # Grounding, language, and response instructions
|   |-- scripts/
|   |   \-- ingest_knowledge.py        # CSV ingestion into Pinecone and BM25 artifacts
|   |-- data/
|   |   |-- raw.csv                    # Raw dataset (local; not tracked)
|   |   |-- clean.csv                  # Cleaned knowledge base (local; not tracked)
|   |   |-- cleaning.ipynb             # Data cleaning notebook
|   |   \-- analysis/                  # Exploratory data analysis outputs
|   |-- rag_artifacts/                  # Local BM25/corpus pickle artifacts
|   |-- Dockerfile                     # Backend container image
|   |-- startup.sh                     # Container startup command
|   |-- runtime.txt                    # Python runtime version
|   |-- requirements.txt               # Python dependencies
|   \-- .env.example                  # Backend environment template
|
|-- frontend/
|   |-- src/
|   |   |-- main.jsx                   # React Router entry point
|   |   |-- App.jsx                    # Support-ticket form and submission
|   |   |-- pages/
|   |   |   |-- ThankYou.jsx           # Generated-answer page
|   |   |   \-- ThankYou.css
|   |   |-- tokens.css                 # Design tokens
|   |   |-- Form.css                   # Form styles
|   |   \-- index.css                 # Global styles
|   |-- index.html
|   |-- vite.config.js                 # Dev server and backend proxy
|   \-- package.json
|
|-- infra/
|   |-- main.bicep                     # Azure infrastructure orchestrator
|   |-- azure.yaml                     # Azure Developer CLI configuration
|   \-- modules/                      # Reusable Azure Bicep modules
|
|-- deploy.ps1                         # Two-phase Azure deployment script
|-- .gitignore
|-- AGENTS.md
\-- README.md
```

> **Data and generated artifacts:** The repository's `.gitignore` excludes `backend/data/*.csv`. Put your cleaned knowledge-base file at `backend/data/clean.csv` locally before running ingestion. The BM25 pickle files are generated under `backend/rag_artifacts/`.

## Getting Started

### Prerequisites

Make sure you have the following installed or configured:

- Python 3.11
- Node.js and npm
- PostgreSQL
- Ollama, with the `qwen3-embedding:0.6b` model available
- A Pinecone account and an existing index
- API keys for Groq and Cohere

The Pinecone index must be created before ingestion. Its vector dimensions and similarity metric must be compatible with the embedding configuration.

### 1. Clone the repository

```bash
git clone https://github.com/awanishsingh123/intelligent-support-ticket-rag.git
cd intelligent-support-ticket-rag
```

### 2. Configure the backend

Create and activate a virtual environment:

**Windows PowerShell**

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

**macOS / Linux**

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Create your environment file:

```bash
# Run from the backend directory
cp .env.example .env
```

On Windows PowerShell, you can use:

```powershell
Copy-Item .env.example .env
```

Update the values in `backend/.env` with your own service credentials and PostgreSQL connection details.

### 3. Start the backend

From the `backend/` directory, with the virtual environment activated:

```bash
uvicorn app.main:app --reload --port 8000
```

The API will be available at:

- API root: http://localhost:8000/
- Health check: http://localhost:8000/health
- Support endpoint: http://localhost:8000/support/submit

The application creates the SQLAlchemy tables during FastAPI startup.

### 4. Start the frontend

Open a second terminal:

```bash
cd frontend
npm install
npm run dev
```

Open http://localhost:3000 in your browser.

The Vite development server proxies `/support` and `/api` requests to the backend at `http://127.0.0.1:8000`.

For a production frontend build:

```bash
npm run build
```

## Environment Configuration

Create `backend/.env` from `backend/.env.example`.

| Variable | Required | Description |
|---|---:|---|
| `GROQ_API_KEY` | Yes | API key used for Groq response generation |
| `COHERE_API_KEY` | Yes | API key used by the Cohere reranker |
| `PINECONE_API_KEY` | Yes | Pinecone API key |
| `PINECONE_INDEX_NAME` | Yes | Existing Pinecone index name |
| `OLLAMA_BASE_URL` | Yes | Base URL for the Ollama embedding service |
| `OLLAMA_API_KEY` | Optional | Optional Ollama credential supported by settings |
| `PGHOST` | Yes | PostgreSQL host |
| `PGPORT` | Yes | PostgreSQL port |
| `PGDATABASE` | Yes | PostgreSQL database name |
| `PGUSER` | Yes | PostgreSQL username |
| `PGPASSWORD` | Yes | PostgreSQL password |
| `CORS_ORIGINS` | Optional | Comma-separated allowed frontend origins; defaults to `http://localhost:3000` |

Example configuration (replace placeholders with your own values):

```dotenv
GROQ_API_KEY=your_groq_api_key
COHERE_API_KEY=your_cohere_api_key
PINECONE_API_KEY=your_pinecone_api_key
PINECONE_INDEX_NAME=your_pinecone_index

OLLAMA_BASE_URL=http://localhost:11434

PGHOST=localhost
PGPORT=5432
PGDATABASE=your_database
PGUSER=postgres
PGPASSWORD=your_database_password

CORS_ORIGINS=http://localhost:3000
```

Do not commit `.env` files or paste API keys into source code.

## Knowledge-Base Ingestion

The ingestion script reads the cleaned CSV from:

```text
backend/data/clean.csv
```

The loader uses the `text` column as document content and `answer` and `type` as metadata. The script then:

1. Loads the knowledge-base rows.
2. Connects to the existing Pinecone index.
3. Generates embeddings using Ollama.
4. Uploads document batches to Pinecone.
5. Builds BM25 retrievers grouped by `type`, plus a global retriever.
6. Saves the local corpus and BM25 retrievers under `backend/rag_artifacts/`.

Run from the `backend/` directory with the virtual environment activated:

```bash
python -c "from scripts.ingest_knowledge import Knowledge; Knowledge().ingest_knowledge()"
```

**Current implementation detail:** `ingest_knowledge.py` currently limits the loaded documents to the first 50 rows (`loader.load()[:50]`). If you intend to ingest the full CSV, review that slice in the script before running ingestion. The script also expects the Pinecone index to exist already; it does not create the index.

## API Reference

### Health check

`GET /`

Returns basic API information.

`GET /health`

Returns the service health status.

Example:

```json
{
  "status": "healthy"
}
```

### Submit a support ticket

`POST /support/submit`

Content type: `application/json`

**Request body**

```json
{
  "first_name": "Jordan",
  "last_name": "Reyes",
  "email": "jordan@example.com",
  "phone": "+1 555 123 4567",
  "question": "How can I reset my account password?"
}
```

The `phone` field is optional and can be `null`.

**Response body**

```json
{
  "id": 1,
  "llm_response": "To reset your password, ...",
  "category": "account",
  "priority": "Low",
  "created_at": "2026-06-21T12:00:00Z"
}
```

The example values are illustrative. The actual category and generated answer depend on the submitted question and available knowledge-base content.

### Priority rules

Priority is currently assigned by keyword matching in `backend/app/core/pipeline.py`:

- **High:** matches terms such as `urgent`, `critical`, `emergency`, `security breach`, `data loss`, `account hacked`, `completely down`, `payment deducted`, or `server down`.
- **Medium:** matches terms such as `not working`, `failed`, `error`, `unable`, `issue`, `problem`, `incorrect`, `blocked`, or `slow`.
- **Low:** default when no configured High or Medium keyword matches.

This is a rule-based heuristic, not a separately trained priority model.

## Database

The backend uses PostgreSQL through SQLAlchemy's asynchronous engine and `asyncpg`.

| Table | Main fields | Purpose |
|---|---|---|
| `users` | `id`, `first_name`, `last_name`, `email`, `phone` | Stores user details; email is unique |
| `queries` | `id`, `user_id`, `question`, `llm_response`, `category`, `priority`, `created_at` | Stores submitted questions and generated results |

Tables are created during application startup using `Base.metadata.create_all`. The repository looks up users by email and creates a user record when one does not already exist.

## Azure Deployment

The repository includes Bicep templates for Azure infrastructure and a PowerShell deployment script.

The infrastructure definitions include:

- Azure Container Apps and a Container Apps environment
- Azure Container Registry (ACR)
- Azure Key Vault
- Log Analytics workspace
- Application Insights
- Managed-identity-based container image pull configuration

The backend Dockerfile builds the FastAPI service. The deployment script, `deploy.ps1`, follows a two-phase process:

1. Deploys the Azure infrastructure with a placeholder container image.
2. Builds and pushes the backend image to ACR.
3. Configures the Container App to pull from ACR using its managed identity.
4. Sets the required Key Vault secrets and grants the app access.
5. Updates the Container App image and checks the service.

The script requires Azure CLI and an authenticated Azure account with the required permissions. Review `deploy.ps1`, `infra/main.bicep`, and the Bicep modules and supply your own subscription, resource group, region, and secret values before deploying.

## Important Implementation Notes

- **Model configuration:** The current Groq model configured in `backend/app/config.py` is `openai/gpt-oss-20b`; the embedding model is `qwen3-embedding:0.6b` through Ollama.
- **Classifier artifacts:** The SVM and TF-IDF files are loaded from `backend/app/classifier/` at runtime.
- **Knowledge-base files:** CSV files under `backend/data/` are excluded by `.gitignore`; provide the cleaned dataset locally.
- **RAG artifacts:** The retriever expects locally generated corpus and BM25 artifacts under `backend/rag_artifacts/`. Run ingestion when these artifacts are missing or need to be rebuilt.
- **Pinecone index:** Create the index before running ingestion and ensure its configuration matches the embedding model.
- **Prompt grounding:** The system prompt in `backend/app/prompts/generator_prompt.md` instructs the LLM to answer using retrieved context and to avoid inventing missing information.
- **No frontend API key:** The frontend submits the form to the backend endpoint; service credentials belong in the backend environment, not the browser bundle.

---

## License

No license file was found in the repository when this README was updated. Add a license file if you intend to publish the project with explicit reuse terms.

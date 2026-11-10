# Support Ticket Form

A modern, responsive contact form for submitting support tickets.

## Prerequisites

- Node.js 18+ installed
- Python 3.9+ with the project dependencies installed

## Running the Application

### Step 1: Start the Backend Server

Open a terminal in the main project directory (`C:\Files\Customer Support Ticket System`) and run:

```bash
# Activate virtual environment if not already active
# Windows:
venv\Scripts\activate

# Start the FastAPI server
uvicorn app.main:app --reload --port 8000
```

The backend will be available at `http://localhost:8000`

### Step 2: Start the Frontend (Form)

Open a **new terminal** and navigate to the form folder:

```bash
cd form
```

Install dependencies (first time only):

```bash
npm install
```

Start the development server:

```bash
npm run dev
```

The form will be available at `http://localhost:3000`

## Project Structure

```
form/
├── index.html          # HTML entry point
├── package.json        # Node.js dependencies
├── vite.config.js      # Vite configuration
├── .gitignore          # Git ignore file
├── README.md           # This file
└── src/
    ├── main.jsx        # React entry point
    ├── App.jsx         # Main form component
    ├── Form.css        # Form styles
    └── index.css       # Global styles
```

## Features

- Modern, clean design with gradient styling
- Fully responsive (mobile, tablet, desktop)
- Form validation
- Loading states
- Success/error feedback
- CORS-enabled for local development

## API Endpoint

The form submits to: `POST /api/v1/submit-form`

Request body:
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "phone": "+1 (555) 123-4567",
  "query": "My question is..."
}
```

## Production Build

To create a production build:

```bash
npm run build
```

The built files will be in the `dist/` folder.

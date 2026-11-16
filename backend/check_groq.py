import os
from pathlib import Path
from dotenv import load_dotenv
from groq import Groq

load_dotenv(Path(__file__).resolve().parent / ".env")

api_key = os.getenv("GROQ_API_KEY")

if not api_key:
    raise ValueError("GROQ_API_KEY not found in .env")

client = Groq(api_key=api_key)

try:
    models = client.models.list()

    print("\nAVAILABLE LLAMA MODELS:\n")

    for model in models.data:
        if "llama" in model.id.lower():
            print(model.id)

except Exception as e:
    print("Groq API Error:", e)

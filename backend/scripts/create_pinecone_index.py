from pinecone import Pinecone, ServerlessSpec
from app.config import settings

INDEX_NAME = "chat-ticket-v4"

pc = Pinecone(api_key=settings.PINECONE_API_KEY)

existing = [i["name"] for i in pc.list_indexes()]

if INDEX_NAME in existing:
    print(f"Index '{INDEX_NAME}' already exists.")
else:
    pc.create_index(
        name=INDEX_NAME,
        dimension=1024,
        metric="cosine",
        spec=ServerlessSpec(
            cloud="aws",
            region="us-east-1"
        )
    )
    print(f"Index '{INDEX_NAME}' creation requested.")
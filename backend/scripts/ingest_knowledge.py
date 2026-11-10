import pickle
from pathlib import Path
from collections import defaultdict
from langchain_community.document_loaders import CSVLoader
from langchain_community.retrievers import BM25Retriever
from pinecone import Pinecone
from langchain_pinecone import PineconeVectorStore
from app.config import settings

BACKEND_DIR = Path(__file__).resolve().parent.parent


class Knowledge():
    def __init__(self):
        self.__embed = settings.embedding_model
        self.__csv_path = str(BACKEND_DIR / "data" / "clean.csv")
        self.__index_name = settings.PINECONE_INDEX_NAME
        self.__corpus_path = str(BACKEND_DIR / "rag_artifacts" / "knowledge_corpus.pkl")
        self.__bm25_path = str(BACKEND_DIR / "rag_artifacts" / "bm25_by_type.pkl")

    def __ensure_index(self):
        pc = Pinecone(api_key=settings.PINECONE_API_KEY)
        existing = [i["name"] for i in pc.list_indexes()]
        if self.__index_name not in existing:
            raise ValueError(
                f"Pinecone index '{self.__index_name}' does not exist. "
                "Create it manually in the Pinecone console first."
            )
        return pc.Index(self.__index_name)

    @staticmethod
    def __build_bm25_by_type(docs):
        by_type = defaultdict(list)
        for d in docs:
            key = d.metadata.get("type") or "__none__"
            by_type[key].append(d)

        bm25_by_type = {}
        for type_name, group in by_type.items():
            retriever = BM25Retriever.from_documents(group)
            retriever.k = 10
            bm25_by_type[type_name] = retriever

        bm25_all = BM25Retriever.from_documents(docs)
        bm25_all.k = 10
        bm25_by_type["__all__"] = bm25_all

        return bm25_by_type

    def ingest_knowledge(self):
        loader = CSVLoader(
            file_path=self.__csv_path,
            content_columns=["text"],
            metadata_columns=["answer", "type"]
        )

        docs = loader.load()

        index = self.__ensure_index()

        vector_db = PineconeVectorStore(index=index, embedding=self.__embed)

        batch_size = 100
        for i in range(0, len(docs), batch_size):
            vector_db.add_documents(docs[i:i + batch_size])

        with open(self.__corpus_path, "wb") as f:
            pickle.dump(docs, f)

        bm25_by_type = self.__build_bm25_by_type(docs)
        with open(self.__bm25_path, "wb") as f:
            pickle.dump(bm25_by_type, f)

        return vector_db
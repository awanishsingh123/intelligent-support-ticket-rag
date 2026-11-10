from pathlib import Path
from langchain_core.documents.base import Document
from typing import List
import pickle
from pinecone import Pinecone
from langchain_pinecone import PineconeVectorStore
from langchain_classic.retrievers import EnsembleRetriever, ContextualCompressionRetriever
from scripts.ingest_knowledge import Knowledge
from app.config import settings

BACKEND_DIR = Path(__file__).resolve().parent.parent.parent


class Retriever():
    def __init__(self):
        self.__embedding_model = settings.embedding_model
        self.__reranker = settings.rerank_model
        self.__index_name = settings.PINECONE_INDEX_NAME
        self.__corpus_path = str(BACKEND_DIR / "rag_artifacts" / "knowledge_corpus.pkl")
        self.__bm25_path = str(BACKEND_DIR / "rag_artifacts" / "bm25_by_type.pkl")
        self.__retriever = None
        self.__bm25_by_type = None
        self.__active_bm25 = None

    def __resolve_vector_db(self):
        pc = Pinecone(api_key=settings.PINECONE_API_KEY)
        existing = [i["name"] for i in pc.list_indexes()]
        if self.__index_name in existing and Path(self.__corpus_path).exists() and Path(self.__bm25_path).exists():
            print("loading knowledge...")
            index = pc.Index(self.__index_name)
            return PineconeVectorStore(index=index, embedding=self.__embedding_model)
        print("creating knowledge...")
        kb = Knowledge()
        return kb.ingest_knowledge()

    def __build_retriever(self):
        vector_db = self.__resolve_vector_db()
        with open(self.__bm25_path, "rb") as f:
            self.__bm25_by_type = pickle.load(f)
        self.__active_bm25 = self.__bm25_by_type["__all__"]
        pinecone_retriever = vector_db.as_retriever(search_kwargs={"k": 10})
        hybrid_retriever = EnsembleRetriever(
            retrievers=[self.__active_bm25, pinecone_retriever],
            weights=[0.3, 0.7]
        )
        return ContextualCompressionRetriever(
            base_compressor=self.__reranker,
            base_retriever=hybrid_retriever
        )

    async def retrieve_docs(self, query: str, category: str = None) -> List[Document]:
        if self.__retriever is None:
            self.__retriever = self.__build_retriever()

        if category:
            self.__retriever.base_retriever.retrievers[1].search_kwargs["filter"] = {"type": category}
            self.__active_bm25 = self.__bm25_by_type.get(category, self.__bm25_by_type["__all__"])
        else:
            self.__retriever.base_retriever.retrievers[1].search_kwargs.pop("filter", None)
            self.__active_bm25 = self.__bm25_by_type["__all__"]

        self.__retriever.base_retriever.retrievers[0] = self.__active_bm25

        return await self.__retriever.ainvoke(query)
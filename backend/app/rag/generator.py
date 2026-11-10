
from pathlib import Path
from langdetect import detect
from langchain_core.output_parsers import StrOutputParser
from langchain_core.messages import SystemMessage, HumanMessage
from app.config import settings
from app.rag.retriever import Retriever

BACKEND_DIR = Path(__file__).resolve().parent.parent.parent


class Generator():
    def __init__(self):
        self.__llm = settings.chat_model
        prompt_path = BACKEND_DIR / "app" / "prompts" / "generator_prompt.md"
        with open(prompt_path, 'r', encoding='utf-8') as f:
            self.__system_prompt = f.read()

    def _detect_language(self, text: str) -> str:
        try:
            return detect(text)
        except Exception:
            return 'en'

    async def generate(self, query: str, category: str = None) -> str:
        retriever = Retriever()
        docs = await retriever.retrieve_docs(query, category)

        context = "\n\n---\n\n".join(doc.metadata.get('answer', 'No answer available in knowledge base.') for doc in docs)

        lang = self._detect_language(query)
        messages = [
            SystemMessage(content=self.__system_prompt),
            HumanMessage(content=f"Context from Knowledge Base:\n{context}\n\nUser's Current Query (language: {lang}):\n{query}")
        ]

        chain = self.__llm | StrOutputParser()
        return await chain.ainvoke(messages)

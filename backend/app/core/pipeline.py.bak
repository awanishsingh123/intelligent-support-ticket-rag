from app.rag.generator import Generator
from app.classifier.model import Classifier

class TicketProcessingPipeline():
    def __init__(self):
        self.__classifier = Classifier()
        self.__generator = Generator()

    async def run_pipeline(self, query: str) -> str:
        text_cat = await self.__classifier.classify(query)
        response = await self.__generator.generate(query, text_cat)

        return response
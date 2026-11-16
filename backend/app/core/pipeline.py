from app.rag.generator import Generator
from app.classifier.model import Classifier


class TicketProcessingPipeline:

    def __init__(self):
        self.__classifier = Classifier()
        self.__generator = Generator()

    def detect_priority(self, query: str) -> str:
        text = query.lower()

        high_keywords = [
            "urgent", "critical", "emergency",
            "security breach", "data loss",
            "account hacked", "completely down",
            "payment deducted", "server down"
        ]

        medium_keywords = [
            "not working", "failed", "error",
            "unable", "issue", "problem",
            "incorrect", "blocked", "slow"
        ]

        if any(word in text for word in high_keywords):
            return "High"

        if any(word in text for word in medium_keywords):
            return "Medium"

        return "Low"

    async def run_pipeline(self, query: str) -> dict:

        category = await self.__classifier.classify(query)

        priority = self.detect_priority(query)

        response = await self.__generator.generate(
            query,
            str(category)
        )

        return {
            "category": str(category),
            "priority": priority,
            "llm_response": response
        }

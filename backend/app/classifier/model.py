from pathlib import Path
import joblib
import asyncio

BACKEND_DIR = Path(__file__).resolve().parent.parent.parent

class Classifier():
    def __init__(self):
        self.__tfidf = joblib.load(BACKEND_DIR / "app" / "classifier" / "tfidf.pkl")
        self.__model = joblib.load(BACKEND_DIR / "app" / "classifier" / "svm_model.pkl")

    async def classify(self, query: str):
        loop = asyncio.get_event_loop()
        text_vec = await loop.run_in_executor(None, self.__tfidf.transform, [query])
        prediction = await loop.run_in_executor(None, self.__model.predict, text_vec)

        return prediction[0]
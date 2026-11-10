from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database.models.user import User
from app.database.models.query import Query

class SupportRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_or_create_user(self, first_name: str, last_name: str, email: str, phone: str | None) -> User:
        result = await self.db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        if not user:
            user = User(first_name=first_name, last_name=last_name, email=email, phone=phone)
            self.db.add(user)
            await self.db.flush()
        return user

    async def save_query(self, user_id: int, question: str, llm_response: str) -> Query:
        query = Query(user_id=user_id, question=question, llm_response=llm_response)
        self.db.add(query)
        await self.db.commit()
        await self.db.refresh(query)
        return query
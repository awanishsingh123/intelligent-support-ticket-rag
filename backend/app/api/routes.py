from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database.session import get_db
from app.repositories.support_repository import SupportRepository
from app.schemas.support import SupportFormInput, SupportResponse
from app.core.pipeline import  TicketProcessingPipeline

router = APIRouter(prefix="/support", tags=["support"])

@router.post("/submit", response_model=SupportResponse)
async def submit_form(form: SupportFormInput, db: AsyncSession = Depends(get_db)):
    repo = SupportRepository(db)

    # 1. Get or create user
    user = await repo.get_or_create_user(
        first_name=form.first_name,
        last_name=form.last_name,
        email=form.email,
        phone=form.phone,
    )

    # 2. Call your existing LLM
    pipeline = TicketProcessingPipeline()
    llm_response = await pipeline.run_pipeline(form.question)

    # 3. Save query + response
    query = await repo.save_query(
        user_id=user.id,
        question=form.question,
        llm_response=llm_response,
    )

    return query
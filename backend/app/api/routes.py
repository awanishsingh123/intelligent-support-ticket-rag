from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.repositories.support_repository import SupportRepository
from app.schemas.support import SupportFormInput, SupportResponse
from app.core.pipeline import TicketProcessingPipeline


router = APIRouter(prefix="/support", tags=["support"])


@router.post("/submit", response_model=SupportResponse)
async def submit_form(
    form: SupportFormInput,
    db: AsyncSession = Depends(get_db)
):

    repo = SupportRepository(db)

    user = await repo.get_or_create_user(
        first_name=form.first_name,
        last_name=form.last_name,
        email=form.email,
        phone=form.phone
    )

    pipeline = TicketProcessingPipeline()

    result = await pipeline.run_pipeline(form.question)

    query = await repo.save_query(
        user_id=user.id,
        question=form.question,
        llm_response=result["llm_response"],
        category=result["category"],
        priority=result["priority"]
    )

    return query

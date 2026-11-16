from pydantic import BaseModel, EmailStr
from datetime import datetime

class SupportFormInput(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    phone: str | None = None
    question: str

class SupportResponse(BaseModel):
    id: int
    llm_response: str
    created_at: datetime

    model_config = {"from_attributes": True}
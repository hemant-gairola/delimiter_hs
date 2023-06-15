from datetime import date
from pydantic import BaseModel


class DataInfo(BaseModel):
    data: str
    class Config:
        orm_mode = True
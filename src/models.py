from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from .database import Base


class DataSetInfo(Base):
    __tablename__ = "data_set"

    id = Column(Integer, primary_key=True, index=True)
    data = Column(String, index=True)

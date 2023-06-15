from typing import List
import uvicorn

from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy.orm import Session

from . import crud, models, schemas
from .database import SessionLocal, engine
from fastapi import FastAPI, APIRouter
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse
from fastapi import Response
import json

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# router = APIRouter(prefix="/sample")


# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.post("/api/data-sets")
def create_data_info(data: dict, db: Session = Depends(get_db)):

    return json.loads(crud.create_data_info(db=db, data=data).data)


@app.get("/api/data-sets/{id}")
def get_data_info_by_id(id: int, db: Session = Depends(get_db)):
    id = crud.get_data_info_by_id(db, id=id)
    if id is None:
        raise HTTPException(status_code=404, detail="Id not found")
    # json_compatible_item_data = jsonable_encoder(id)
    # return JSONResponse(content=json_compatible_item_data)
    # return Response(content=id, media_type="application/json")
    return json.loads(id.data)

@app.get("/api/api-version")
def get_api_version():
    return {"versionId": "v3.1.0"}





# uvicorn.run("main:app", host="0.0.0.0", port=80)

from sqlalchemy.orm import Session

from . import models, schemas
import json




def get_data_info_by_id(db: Session, id: int):
    data1 = db.query(models.DataSetInfo).filter(models.DataSetInfo.id == id).first()
    return data1



def create_data_info(db: Session, data):
    data = data
    db_data_info_data = json.dumps(data)
    db_data_info = models.DataSetInfo(data=db_data_info_data)

    db.add(db_data_info)
    db.commit()
    db.refresh(db_data_info)
    return db_data_info


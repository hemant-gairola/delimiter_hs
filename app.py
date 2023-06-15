import uvicorn

uvicorn.run("src.main:app", host="0.0.0.0", port=80, reload=False)
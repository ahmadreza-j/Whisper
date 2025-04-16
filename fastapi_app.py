from fastapi import FastAPI, File, UploadFile, HTTPException, Query
from typing import List, Optional
from fastapi.responses import JSONResponse, RedirectResponse
import whisper
import torch
from tempfile import NamedTemporaryFile

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
model = whisper.load_model("medium", device=DEVICE)

app = FastAPI()

@app.post("/whisper")
async def handler(
    files: List[UploadFile] = File(...),
    language: Optional[str] = Query(None),
    initial_prompt: Optional[str] = Query(None),
    temperature: Optional[float] = Query(0.0),
    beam_size: Optional[int] = Query(5),
    condition_on_previous_text: Optional[bool] = Query(True)
):
    if not files:
        raise HTTPException(status_code=400, detail="No files uploaded")

    kwargs = {
        "temperature": temperature,
        "beam_size": beam_size,
        "condition_on_previous_text": condition_on_previous_text
    }

    if language:
        kwargs["language"] = language
    if initial_prompt:
        kwargs["initial_prompt"] = initial_prompt

    results = []
    for file in files:
        with NamedTemporaryFile(delete=True) as temp:
            temp.write(file.file.read())
            temp.flush()
            result = model.transcribe(temp.name, **kwargs)
            results.append({
                "filename": file.filename,
                "transcript": result["text"]
            })

    return JSONResponse(content={"results": results})

@app.get("/", response_class=RedirectResponse)
def redirect_to_docs():
    return "/docs"

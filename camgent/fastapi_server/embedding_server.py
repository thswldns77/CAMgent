# embedding_server.py
try:
    import torchvision.transforms.functional_tensor  # 구버전 경로
except Exception:
    import sys, types
    import torchvision.transforms.functional as F
    shim = types.ModuleType("torchvision.transforms.functional_tensor")
    for name in dir(F):
        setattr(shim, name, getattr(F, name))
    sys.modules["torchvision.transforms.functional_tensor"] = shim
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from PIL import Image
import io

from sentence_transformers import SentenceTransformer
from .youtube_url_getter import search_youtube_shorts
from .enhance import enhance

# NIMA 관련 함수 임포트
from .model_loader import load_nima_model, predict_score_from_pil

# FastAPI 앱 시작
app = FastAPI()

# 모델 로드 (서버 시작 시 1회만)
nima_model, nima_target_size = load_nima_model()

# 텍스트 임베딩 모델
text_model = SentenceTransformer("jhgan/ko-sroberta-multitask")

# 텍스트 임베딩용 엔드포인트
class Query(BaseModel):
    text: str

class ImagePath(BaseModel):
    image_path: str

@app.post("/embed")
async def embed(query: Query):
    embedding = text_model.encode(query.text).tolist()
    return {"embedding": embedding}

# 이미지 점수 평가용 엔드포인트
@app.post("/analyze")
async def analyze_image(image: UploadFile = File(...)):
    try:
        contents = await image.read()
        
        img = Image.open(io.BytesIO(contents)).convert("RGB")
        print("--------------")
        print(img)
        score = float(predict_score_from_pil(img, nima_model, nima_target_size))*10
        print("--------------analyze")
        print(score)
        payload = {"score": round(score, 3)}
        print(payload)
        resp = JSONResponse(content=payload)

        print("json body:", resp.body.decode("utf-8"))  # -> {"score": 0.123}

        return JSONResponse(content={"score": round(score, 3)})
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})
    
@app.post("/search_youtube")
async def search_youtube_video(query: Query):
    url = search_youtube_shorts(query.text)
    return {"url": url}


@app.post("/enhance")
async def enhance_image(data: ImagePath):
    output_path = enhance(data.image_path)
    return {"output_path": output_path}


# 실행 명령어:
# uvicorn embedding_server:app --reload --port 8000


from sentence_transformers import SentenceTransformer
import pandas as pd
import json

model = SentenceTransformer("jhgan/ko-sroberta-multitask")

df = pd.read_excel("camera_settings.xlsx")

embeddings = []
for idx, row in df.iterrows():
    texts = []
    if pd.notna(row["situation_korean"]):
        texts.append(row["situation_korean"])
    if pd.notna(row["situation_english"]):
        texts.append(row["situation_english"])
    for text in texts:
        vec = model.encode(text)
        embeddings.append({
            "index": idx,
            "text": text,
            "embedding": vec.tolist()
        })

with open("situation_embeddings.json", "w", encoding="utf-8") as f:
    json.dump(embeddings, f, ensure_ascii=False)


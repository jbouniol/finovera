#
//  app.py
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

from fastapi import FastAPI, Query
from pydantic import BaseModel
from typing import List
import recommender  # <-- ton module existant

app = FastAPI(title="Finovera Reco API", version="1.0")

class Recommendation(BaseModel):
    symbol: str
    name: str
    score: float      # 0-100
    reason: str

@app.on_event("startup")
def load_model():
    app.state.model = recommender.Loader.load()  # adapte à ton code

@app.get("/recommendations", response_model=List[Recommendation])
async def get_recommendations(
    risk: str = Query("balanced", enum=["conservative", "balanced", "aggressive"]),
    sectors: str | None = None
):
    recs = app.state.model.recommend(risk=risk, sectors=sectors)
    return [Recommendation(**r) for r in recs]

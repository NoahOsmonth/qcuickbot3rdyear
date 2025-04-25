# server.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from supabase import create_client, Client
from typing import Any

app = FastAPI()

# Use your Supabase URL and SERVICE_ROLE_KEY (never expose this to clients)
SUPABASE_URL = "https://jgvaqwmxwtherxrdplmv.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpndmFxd214d3RoZXJ4cmRwbG12Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NTQ2MzU4MCwiZXhwIjoyMDYxMDM5NTgwfQ.xHo0XWWggukuxzg7PEYjHuDZCpShFXBsGPJWFAGTKjM"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

class NotificationPayload(BaseModel):
    title: str
    body: str

@app.post("/send_all")
async def send_all(payload: NotificationPayload):
    # 1. Fetch all user IDs
    resp: Any = supabase.table("auth.users").select("id").execute()
    if resp.error:
        raise HTTPException(status_code=500, detail=resp.error.message)
    user_ids = [u["id"] for u in resp.data]

    # 2. Build bulk insert records
    records = [
        {
            "user_id": uid,
            "title": payload.title,
            "body": payload.body
        } for uid in user_ids
    ]

    # 3. Insert into notifications table
    insert_resp: Any = supabase.table("notifications").insert(records).execute()
    if insert_resp.error:
        raise HTTPException(status_code=500, detail=insert_resp.error.message)

    return {"status": "sent", "count": len(records)}
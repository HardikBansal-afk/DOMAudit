import asyncio
import json
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from google import genai
import os

app = FastAPI(title="DOMAudit-AI Production API (Gemini Powered)")

# CORS rules for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

API_KEY = os.environ.get("GEMINI_API_KEY")
client = genai.Client(api_key=API_KEY)
# --- 2. Data Models ---
class AuditRequest(BaseModel):
    html_snippet: str

# --- 3. The Single-Shot AI Call ---
def analyze_with_gemini(html_content: str):
    """
    Sends the entire HTML block to Gemini and asks for a structured JSON array back.
    This avoids hitting the 5 Requests-Per-Minute rate limit.
    """
    prompt = f"""
    You are an expert web accessibility auditor. Analyze the following HTML snippet for WCAG violations.
    Return ONLY a raw JSON array containing objects for each violation found. 
    Do not include markdown formatting like ```json.
    
    Format requirement:
    [
        {{
            "original_element": "<the exact broken html tag>",
            "ai_patch": "Violation: [reason] \\nPatch: <the fixed html tag>"
        }}
    ]
    
    If there are no accessibility violations, return an empty array: []
    
    HTML Snippet:
    {html_content}
    """
    
    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash-lite',
            contents=prompt,
        )
        
        raw_text = response.text.strip()
        
        # Safety net: Strip markdown if the LLM includes it
        if raw_text.startswith("```json"):
            raw_text = raw_text[7:-3].strip()
        elif raw_text.startswith("```"):
            raw_text = raw_text[3:-3].strip()
            
        results = json.loads(raw_text)
        return results
        
    except Exception as e:
        print(f"API Error: {e}")
        # Return a graceful fallback so the Flutter app doesn't crash
        return [{"original_element": "Error", "ai_patch": "API request failed. Please try again."}]

# --- 4. The Endpoint ---
@app.post("/api/audit")
async def run_audit(request: AuditRequest):
    print("Received audit request from Flutter...")
    audit_results = await asyncio.to_thread(analyze_with_gemini, request.html_snippet)
    
    return {
        "status": "success",
        "total_issues_found": len(audit_results),
        "results": audit_results
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

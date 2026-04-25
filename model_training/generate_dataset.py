import jsonlines
import time
import json
from google import genai

# REPLACE THIS WITH YOUR ACTUAL API KEY
API_KEY = "AIzaSyChgJko2Z6oERfi7achMbQ1iBPQft_D6Cc" 
client = genai.Client(api_key=API_KEY)

SYSTEM_PROMPT = """
You are an expert web accessibility auditor. Analyze the provided HTML snippet.
If there is a WCAG violation, output a raw JSON object (no markdown formatting) with exactly two keys:
{"violation": "Brief description of the issue", "patch": "The corrected HTML code"}
If there is no violation, output {"violation": "None", "patch": "None"}
"""

def call_teacher_llm(html_snippet, max_retries=3):
    prompt = f"{SYSTEM_PROMPT}\n\nHTML Snippet:\n{html_snippet}"
    
    # Retry loop: If the API fails, wait and try again
    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(
                model='gemini-2.5-flash-lite',
                contents=prompt,
            )
            
            raw_text = response.text.strip()
            
            if raw_text.startswith("```json"):
                raw_text = raw_text[7:-3].strip()
            elif raw_text.startswith("```"):
                raw_text = raw_text[3:-3].strip()
                
            return json.loads(raw_text)
            
        except Exception as e:
            print(f"  [!] API Error on attempt {attempt + 1}: {e}")
            if "429" in str(e) or "503" in str(e):
                if attempt < max_retries - 1:
                    wait_time = 20 * (attempt + 1) # Wait 20s, then 40s
                    print(f"  [~] Rate limit hit. Waiting {wait_time} seconds before retrying...")
                    time.sleep(wait_time)
                else:
                    print("  [x] Max retries reached. Skipping this snippet.")
                    return {"violation": "None", "patch": "None"}
            else:
                # If it's a different kind of error, skip immediately
                return {"violation": "None", "patch": "None"}

def generate_training_data(input_html_snippets, output_filename="training_data.jsonl"):
    print(f"Generating robust synthetic dataset. Saving to {output_filename}...")
    
    with jsonlines.open(output_filename, mode='w') as writer:
        for i, snippet in enumerate(input_html_snippets):
            print(f"Processing snippet {i+1}/{len(input_html_snippets)}...")
            
            llm_response = call_teacher_llm(snippet)
            
            if llm_response.get("violation", "None") != "None":
                training_example = {
                    "instruction": "Audit this DOM snippet for WCAG accessibility violations and provide the patched HTML.",
                    "input": snippet,
                    "output": f"Violation: {llm_response.get('violation')}\nPatch: {llm_response.get('patch')}"
                }
                writer.write(training_example)
            
            # Base delay of 15 seconds to strictly respect the 5 Requests Per Minute limit
            print("  [-] Sleeping for 15 seconds to respect quotas...")
            time.sleep(15) 
            
    print("\nDataset generation complete!")

if __name__ == "__main__":
    sample_broken_doms = [
        "<img src='hero-banner.jpg' class='w-100'>",
        "<button class='submit-btn' onclick='save()'></button>",
        "<input type='text' id='username'>",
        "<div class='clickable-card' onclick='navigate()'>Read More</div>", 
        "<a href='#' class='nav-link'></a>", 
        "<form><input type='password'></form>", 
        "<span style='color: #ccc; background: #fff;'>Low Contrast Text</span>" 
    ]
    
    generate_training_data(sample_broken_doms)
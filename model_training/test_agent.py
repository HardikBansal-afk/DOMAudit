from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

def test_dom_auditor():
    print("Waking up the local DOMAudit-AI agent...")
    
    # Point this to the folder where your model was just saved
    model_path = "./dom_auditor_model_final"
    
    # Load your custom model and tokenizer (offline mode)
    tokenizer = AutoTokenizer.from_pretrained(model_path, local_files_only=True)
    model = AutoModelForSeq2SeqLM.from_pretrained(model_path, local_files_only=True)

    print("Agent loaded successfully!\n")

    # We MUST use the exact same instruction format we used during training
    instruction = "Audit this DOM snippet for WCAG accessibility violations and provide the patched HTML."
    
    # A standard accessibility failure: an image with no alt text
    broken_html = "<img src='profile-pic.jpg' class='avatar'>"
    
    # Combine them into the final prompt
    prompt = f"{instruction}\n{broken_html}"

    print(f"Target HTML: {broken_html}")
    print("Agent is analyzing the DOM...\n")

    # Convert the text into tensors and feed it to the model
    inputs = tokenizer(prompt, return_tensors="pt", max_length=512, truncation=True)
    
    # Generate the fix
    outputs = model.generate(**inputs, max_length=128)
    
    # Decode the AI's tensor output back into human-readable text
    response = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    print("--- AUDIT RESULT ---")
    print(response)

if __name__ == "__main__":
    test_dom_auditor()
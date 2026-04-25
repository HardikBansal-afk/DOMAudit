import torch
from datasets import load_dataset
from transformers import (
    AutoTokenizer, 
    AutoModelForSeq2SeqLM, 
    Seq2SeqTrainer, 
    Seq2SeqTrainingArguments,
    DataCollatorForSeq2Seq
)

def prepare_dataset():
    print("Loading training data...")
    # Load the JSONL file we generated in the last step
    dataset = load_dataset("json", data_files="training_data.jsonl", split="train")
    return dataset

def train_model():
    # 1. Initialize the tokenizer and the lightweight student model
    model_id = "google/flan-t5-small"
    print(f"Loading {model_id}...")
    tokenizer = AutoTokenizer.from_pretrained(model_id, local_files_only=True)
    model = AutoModelForSeq2SeqLM.from_pretrained(model_id, local_files_only=True)

    # 2. Tokenize the dataset
    def preprocess_function(examples):
        # Combine the instruction and the broken HTML
        inputs = [f"{inst}\n{inp}" for inst, inp in zip(examples["instruction"], examples["input"])]
        
        # Tokenize inputs
        model_inputs = tokenizer(inputs, max_length=512, truncation=True, padding="max_length")
        
        # Tokenize the expected patches (labels)
        labels = tokenizer(examples["output"], max_length=512, truncation=True, padding="max_length")
        
        model_inputs["labels"] = labels["input_ids"]
        return model_inputs

    dataset = prepare_dataset()
    print("Tokenizing dataset...")
    tokenized_dataset = dataset.map(preprocess_function, batched=True)

    # 3. Configure the Training Loop
    print("Setting up training arguments...")
    training_args = Seq2SeqTrainingArguments(
        output_dir="./dom_auditor_model",
        eval_strategy="no", # Skipping evaluation for this initial test run
        learning_rate=2e-5,
        per_device_train_batch_size=4, # Keep this small for local testing
        weight_decay=0.01,
        save_total_limit=2,
        num_train_epochs=50, # 3 epochs is enough to see the loss decrease
        predict_with_generate=True,
        fp16=False, # Set to True if training on a GPU
    )

    data_collator = DataCollatorForSeq2Seq(tokenizer, model=model)

    # 4. Initialize the Trainer
    # 4. Initialize the Trainer
    trainer = Seq2SeqTrainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_dataset,
        processing_class=tokenizer,    # <--- The updated argument
        data_collator=data_collator,
    )

    # 5. Execute Training
    print("Beginning distillation training...")
    trainer.train()

    # 6. Save the final tuned model
    print("Training complete. Saving student model...")
    trainer.save_model("./dom_auditor_model_final")
    print("Model saved to ./dom_auditor_model_final")

if __name__ == "__main__":
    train_model()
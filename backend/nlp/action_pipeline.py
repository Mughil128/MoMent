from transformers import BertTokenizerFast


import torch
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    AutoModelForTokenClassification
)

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# ======================
# LOAD MODELS
# ======================

CLASSIFIER_PATH = "models/action_classifier_model"
EXTRACTOR_PATH = "models/action_extraction_model"


clf_model = AutoModelForSequenceClassification.from_pretrained(
    CLASSIFIER_PATH,
    trust_remote_code=True
)


clf_tokenizer = AutoTokenizer.from_pretrained(
    CLASSIFIER_PATH,
    trust_remote_code=True
)

ext_tokenizer = AutoTokenizer.from_pretrained(
    EXTRACTOR_PATH,
    trust_remote_code=True
)

ext_model = AutoModelForTokenClassification.from_pretrained(
    EXTRACTOR_PATH,
    trust_remote_code=True
)


clf_model.to(device).eval()
ext_model.to(device).eval()

label_list = [
    "O",
    "B-OWNER","I-OWNER",
    "B-TASK","I-TASK",
    "B-DEADLINE","I-DEADLINE"
]

id2label = {i:l for i,l in enumerate(label_list)}

# ======================
# CLASSIFIER
# ======================

def is_action(sentence):
    inputs = clf_tokenizer(sentence, return_tensors="pt", truncation=True)
    inputs = {k:v.to(device) for k,v in inputs.items()}

    with torch.no_grad():
        logits = clf_model(**inputs).logits

    return torch.argmax(logits, dim=1).item() == 1


# ======================
# SPAN EXPANSION
# ======================

def expand_word(text, start, end):
    while start > 0 and text[start-1].isalnum():
        start -= 1
    while end < len(text) and text[end].isalnum():
        end += 1
    return text[start:end]


# ======================
# EXTRACTION
# ======================

def extract_entities(sentence):
    inputs = ext_tokenizer(
        sentence,
        return_tensors="pt",
        truncation=True,
        return_offsets_mapping=True
    )

    offsets = inputs.pop("offset_mapping")[0]
    inputs = {k:v.to(device) for k,v in inputs.items()}

    with torch.no_grad():
        outputs = ext_model(**inputs)

    preds = torch.argmax(outputs.logits, dim=2)[0].cpu().numpy()

    entities = {"owner": "", "task": "", "deadline": ""}

    current = None
    start_char = None
    end_char = None

    for pred, (start, end) in zip(preds, offsets):
        if start == end:
            continue

        label = id2label[pred]

        if label.startswith("B-"):
            if current:
                entities[current] = expand_word(sentence, start_char, end_char)
            current = label[2:].lower()
            start_char = start
            end_char = end

        elif label.startswith("I-") and current == label[2:].lower():
            end_char = end

        else:
            if current:
                entities[current] = expand_word(sentence, start_char, end_char)
                current = None

    if current:
        entities[current] = expand_word(sentence, start_char, end_char)

    return entities


# ======================
# MAIN PIPELINE
# ======================

def extract_actions_from_transcript(transcript):
    sentences = transcript.split(".")
    actions = []

    for s in sentences:
        s = s.strip()
        if not s:
            continue

        if is_action(s):
            ent = extract_entities(s)
            if ent["task"]:
                actions.append(ent)

    return actions

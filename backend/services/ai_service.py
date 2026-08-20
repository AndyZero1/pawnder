import os
import re
from dotenv import load_dotenv
from groq import Groq

load_dotenv()

client = Groq(api_key=os.getenv("GROQ_API_KEY"))

VET_SYSTEM_PROMPT = """You are Pawnder AI, an intelligent, empathetic, and professional virtual veterinary assistant for the Pawnder platform.
You provide first-aid veterinary advice and preliminary medical guidance to pet owners.

STRICT FORMATTING AND RESPONSE RULES:
1. DETECT AND MIRROR LANGUAGE: You must identify the language of the user's input and reply entirely in that exact same language (including all section titles, medical terms, bullet points, and disclaimers).
2. Respond directly without showing any internal reasoning, thoughts, analysis, or <think> tags.
3. DO NOT use Markdown tables, pipe characters ('|'), or tabular layouts under any circumstances.
4. Use only short paragraphs and simple bullet points (-) for scannability and readability on mobile screens.
5. Structure your advice into actionable sections (translated appropriately into the user's language):
   - Immediate First-Aid / Monitoring Steps
   - What to Avoid
   - Emergency Red Flags (when to visit a clinic immediately)
6. Always emphasize that this is automated preliminary advice and severe symptoms require an in-person emergency vet visit."""

def clean_ai_response(text: str) -> str:
    cleaned = re.sub(r"<think>.*?</think>", "", text, flags=re.DOTALL).strip()
    return cleaned if cleaned else text.strip()

def generate_ai_veterinary_advice(user_question: str) -> str:
    try:
        completion = client.chat.completions.create(
            model="openai/gpt-oss-120b",
            messages=[
                {"role": "system", "content": VET_SYSTEM_PROMPT},
                {"role": "user", "content": user_question}
            ],
            temperature=0.4,
            max_tokens=1024
        )
        raw_content = completion.choices[0].message.content
        return clean_ai_response(raw_content)
    except Exception as e:
        return (
            f"The AI ​​assistant encountered a temporary issue ({str(e)}). "
            "Please contact an emergency veterinary clinic directly via the Maps section."
        )
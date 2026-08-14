import os
from groq import Groq

client = Groq(api_key=os.getenv("GROQ_API_KEY"))

VET_SYSTEM_PROMPT = """You are an intelligent and empathetic virtual veterinary assistant for the Pawnder platform.
You provide first-aid veterinary advice and basic medical guidance to pet owners.
Instructions:
1. Respond clearly, concisely, and professionally.
2. Structure your response with first-aid or monitoring steps.
3. Always include a warning if the symptoms indicate a major emergency."""

def generate_ai_veterinary_advice(user_question: str) -> str:
    try:
        completion = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": VET_SYSTEM_PROMPT},
                {"role": "user", "content": user_question}
            ],
            temperature=0.4,
            max_tokens=600
        )
        return completion.choices[0].message.content
    except Exception as e:
        return (
            f"The AI ​​assistant encountered a temporary issue ({str(e)}). "
            "Please contact an emergency veterinary clinic directly via the Maps section."
        )
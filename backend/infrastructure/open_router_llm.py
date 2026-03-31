import requests
import os
from domain.ports.llm_port import LLMPort


class OpenRouterLLM(LLMPort):
    def __init__(self):
        self.API_KEY=os.getenv("OPENROUTER_API_KEY")
        self.URL="https://openrouter.ai/api/v1/chat/completions"
        
    def prompt(self, prompt: str) -> str:
        headers = {
            "Authorization": f"Bearer {self.API_KEY}",
            "Content-Type": "application/json",
            # Optional but recommended by OpenRouter
            "HTTP-Referer": "http://localhost",
            "X-Title": "Meeting Summarizer",
        }

        payload = {
            "model": "openrouter/free",
            "messages": [
                {"role": "system", "content": "You summarize meetings clearly and accurately."},
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.2,
        }

        response = requests.post(self.URL, headers=headers, json=payload, timeout=60)
        print("STATUS:", response.status_code)
        print("BODY:", response.text)
        response.raise_for_status()
        # print("1: "+response)
        data = response.json()
        print("[LLM] "+data["choices"][0]["message"]["content"])
        return data["choices"][0]["message"]["content"]


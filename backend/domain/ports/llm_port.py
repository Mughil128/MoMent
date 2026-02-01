from typing import Protocol

class LLMPort(Protocol):
    def prompt(self, prompt: str) -> str:
        ...


def build_prompt(transctipt):
    prompt=f"""You are an AI-powered meeting assistant.

Given the following meeting transcript, generate a SINGLE structured output that includes:
1. A detailed Minutes of Meeting (MoM)
2. A concise summary at the end

Rules:
- Use only the information present in the transcript
- Do NOT assume or invent details
- Be clear, professional, and structured
- Group related discussion points together
- Clearly distinguish between discussion, decisions, and action items

Output Format:

========================
MINUTES OF MEETING (MoM)
========================

Meeting Title:
Date:
Participants:

1. Agenda / Topics Covered
- List each major topic discussed

2. Detailed Discussion Notes
- Provide detailed but concise points for each topic
- Attribute speakers if names are available

3. Decisions Made
- Clearly list finalized decisions
- If none, state: "No decisions were finalized"

4. Action Items
- Format: [Owner] - [Task] - [Deadline]
- If owner or deadline is missing, use "Unassigned" or "Not specified"

5. Risks, Blockers, or Concerns
- Any challenges, disagreements, or risks mentioned

6. Open Questions / Follow-ups
- Items requiring further discussion or clarification

========================
MEETING SUMMARY
========================

- Provide a concise, high-level summary (5-7 bullet points or 1 short paragraph)
- Focus on purpose, key outcomes, and next steps

The following is the Transcript:
<<<
{transctipt}
>>>
"""
    print("[Promp Builder] "+ prompt)
    return prompt
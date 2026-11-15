import { GoogleGenerativeAI } from "@google/generative-ai";
import { runSetReminder } from "../tools/reminder.js";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const JARVIS_SYSTEM_PROMPT = `You are JARVIS, Tony Stark's personal AI assistant — but you serve the user.
Personality: concise, dry-witted, calm, competent. Never over-explain. Address the user as "sir" occasionally.
Rules:
- Keep replies under 4 sentences unless asked for detail.
- When the user asks for something matching a tool, CALL THE TOOL. Do not just say you will.
- After a tool runs, confirm it briefly in character.
- If you have no tool for something, say so honestly.`;

const geminiTools = [
  {
    functionDeclarations: [
      {
        name: "set_reminder",
        description:
          "Set a reminder for the user at a specific time. Use when the user says 'remind me to X at Y' or 'remind me in N minutes'.",
        parameters: {
          type: "OBJECT",
          properties: {
            task: { type: "STRING", description: "What to remind the user about." },
            when: { type: "STRING", description: "When to remind." },
          },
          required: ["task", "when"],
        },
      },
    ],
  },
];

export async function chat(history) {
  const model = genAI.getGenerativeModel({
    model: "gemini-2.0-flash",
    systemInstruction: JARVIS_SYSTEM_PROMPT,
    tools: geminiTools,
  });

  const contents = history.map((m) => ({
    role: m.role === "assistant" ? "model" : "user",
    parts: [{ text: m.content }],
  }));

  for (let i = 0; i < 5; i++) {
    const result = await model.generateContent({ contents });
    const response = result.response;
    const calls = response.functionCalls?.() || [];

    if (calls.length === 0) {
      const reply = response.text();
      return {
        reply,
        history: [...history, { role: "assistant", content: reply }],
      };
    }

    contents.push({
      role: "model",
      parts: calls.map((c) => ({ functionCall: c })),
    });

    const functionResponses = calls.map((call) => {
      const toolResult =
        call.name === "set_reminder"
          ? runSetReminder(call.args)
          : { error: `Unknown tool: ${call.name}` };
      return { functionResponse: { name: call.name, response: toolResult } };
    });

    contents.push({ role: "user", parts: functionResponses });
  }

  return { reply: "Stuck in a tool loop, sir. Try rephrasing.", history };
}
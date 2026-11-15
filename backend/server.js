import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { chat } from "./services/ai.js";
import { listReminders } from "./tools/reminder.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/", (_req, res) => res.json({ status: "JARVIS online" }));

app.post("/api/chat", async (req, res) => {
  try {
    const { history } = req.body;
    if (!Array.isArray(history) || history.length === 0) {
      return res.status(400).json({ error: "history must be a non-empty array." });
    }
    const { reply, history: newHistory } = await chat(history);
    res.json({ reply, history: newHistory });
  } catch (err) {
    console.error("Chat error:", err);
    res.status(500).json({ error: "JARVIS hit a snag." });
  }
});

app.get("/api/reminders", (_req, res) => res.json(listReminders()));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🤖 JARVIS backend on http://localhost:${PORT}`));
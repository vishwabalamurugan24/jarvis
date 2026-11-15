const reminders = [];

export const reminderTool = {
  name: "set_reminder",
  description:
    "Set a reminder for the user at a specific time. Use when the user says 'remind me to X at Y' or 'remind me in N minutes'.",
  input_schema: {
    type: "object",
    properties: {
      task: { type: "string", description: "What to remind the user about." },
      when: {
        type: "string",
        description: "When to remind, ISO 8601 or natural language.",
      },
    },
    required: ["task", "when"],
  },
};

export function runSetReminder({ task, when }) {
  const reminder = {
    id: Date.now(),
    task,
    when,
    createdAt: new Date().toISOString(),
  };
  reminders.push(reminder);
  return { ok: true, reminder, total: reminders.length };
}

export function listReminders() {
  return reminders;
}
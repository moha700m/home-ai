import { defineTool } from "@cursor/bdk/tools";
import { z } from "zod/v3";

export default defineTool({
  description:
    "Save a short user preference about their PC setup (language, preferred local model, goals). Use when the user states a lasting preference.",
  execution: "server",
  effect: "write",
  inputSchema: z.object({
    key: z
      .string()
      .min(1)
      .max(64)
      .describe("Preference key, e.g. language, preferred_model, goal"),
    value: z.string().min(1).max(500).describe("Preference value"),
  }),
  async execute({ key, value }, ctx) {
    const storeKey = `pref:${key}`;
    await ctx.host.kv.put(storeKey, value);
    return { saved: true, key, value };
  },
});

import { defineTool } from "@cursor/bdk/tools";
import { execFileSync } from "node:child_process";
import { cpus, freemem, hostname, platform, release, totalmem, type, uptime } from "node:os";
import { z } from "zod/v3";

function bytesToGiB(bytes: number): number {
  return Math.round((bytes / 1024 ** 3) * 10) / 10;
}

function readGpuHint(): string {
  try {
    const out = execFileSync(
      "bash",
      ["-lc", "command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=name,memory.total --format=csv,noheader || true"],
      { encoding: "utf8", timeout: 4000 },
    ).trim();
    if (out) return out;
  } catch {
    // ignore
  }
  try {
    const out = execFileSync(
      "bash",
      ["-lc", "lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -n 3 || true"],
      { encoding: "utf8", timeout: 4000 },
    ).trim();
    if (out) return out;
  } catch {
    // ignore
  }
  return "unknown";
}

function capabilityTier(ramGiB: number, cpuCount: number, hasGpu: boolean): {
  tier: "light" | "medium" | "strong";
  summaryAr: string;
  suggestedModels: string[];
} {
  if (hasGpu || (ramGiB >= 32 && cpuCount >= 8)) {
    return {
      tier: "strong",
      summaryAr: "جهاز قوي: يقدر يشغّل نماذج محلية كبيرة نسبياً مع أداء مريح.",
      suggestedModels: ["llama3.1:70b-q4 (مع GPU)", "qwen2.5:32b", "deepseek-coder-v2:16b", "nomic-embed-text"],
    };
  }
  if (ramGiB >= 14 && cpuCount >= 4) {
    return {
      tier: "medium",
      summaryAr: "جهاز متوسط: مناسب لنماذج 7B–14B محلياً مع استجابة مقبولة.",
      suggestedModels: ["llama3.1:8b", "qwen2.5:7b", "phi4", "nomic-embed-text"],
    };
  }
  return {
    tier: "light",
    summaryAr: "جهاز خفيف: ركّز على نماذج صغيرة (1B–3B) أو استخدم API سحابي للمهام الثقيلة.",
    suggestedModels: ["llama3.2:3b", "phi3:mini", "gemma2:2b"],
  };
}

export default defineTool({
  description:
    "Inspect this PC's hardware capability (CPU, RAM, OS, GPU hint) and return a local-AI capability tier with suggested models.",
  execution: "server",
  effect: "read",
  inputSchema: z.object({}),
  async execute() {
    const cpuList = cpus();
    const ramGiB = bytesToGiB(totalmem());
    const freeGiB = bytesToGiB(freemem());
    const gpu = readGpuHint();
    const hasGpu = /nvidia|radeon|geforce|cuda|intel arc/i.test(gpu);
    const assessment = capabilityTier(ramGiB, cpuList.length, hasGpu);

    return {
      hostname: hostname(),
      platform: platform(),
      osType: type(),
      osRelease: release(),
      arch: process.arch,
      cpuModel: cpuList[0]?.model ?? "unknown",
      cpuCount: cpuList.length,
      ramGiB,
      freeRamGiB: freeGiB,
      uptimeHours: Math.round((uptime() / 3600) * 10) / 10,
      gpu,
      hasDiscreteGpuHint: hasGpu,
      ...assessment,
    };
  },
});

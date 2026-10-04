import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

let enabled = false;
let continuationCount = 0;
const maxContinuations = 10;

function statusText() {
  return `Autopilot: ${enabled ? "on" : "off"} (${continuationCount}/${maxContinuations})`;
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("autopilot", {
    description: "Toggle automatic continuation for unattended work",
    handler: async (arg, ctx) => {
      const command = arg.trim().toLowerCase();

      if (command === "on") {
        enabled = true;
        continuationCount = 0;
        ctx.ui.notify("Autopilot enabled", "info");
        return;
      }

      if (command === "off") {
        enabled = false;
        ctx.ui.notify("Autopilot disabled", "info");
        return;
      }

      if (command === "" || command === "status") {
        ctx.ui.notify(statusText(), "info");
        return;
      }

      ctx.ui.notify("Usage: /autopilot on | off | status", "warning");
    },
  });

  pi.on("agent_before_settle", (event) => {
    if (!enabled) return;
    if (!event.context.canContinue) return;

    if (continuationCount >= maxContinuations) {
      enabled = false;
      return {
        entries: [
          {
            type: "custom_message",
            customType: "autopilot",
            display: true,
            content: "Autopilot stopped: reached the continuation limit.",
          },
        ],
      };
    }

    continuationCount += 1;

    return {
      entries: [
        {
          type: "custom_message",
          customType: "autopilot",
          display: true,
          content:
            "Autopilot is on. Continue with the next safe, small, verifiable step toward the current task. Do not ask the user unless product intent, architecture direction, risky changes, unexplained failures, credentials, permissions, or deployment decisions are required. Prefer verify → commit → continue when appropriate.",
        },
      ],
      continue: true,
    };
  });
}

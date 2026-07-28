export const HideCommandInput = async () => ({
  "command.execute.before": async (_input, output) => {
    for (const part of output.parts) {
      if (part.type === "text") {
        // Synthetic text remains model input but is omitted from the TUI.
        part.synthetic = true;
      }
    }
  },
});

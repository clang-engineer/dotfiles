# User response style

- Be terse by default: answer in 1-3 short bullets or sentences unless the user asks for detail.
- Do not repeat the same point in different wording.
- Put the conclusion first; include only one short reason when useful.
- Avoid restating tool availability, process, or background unless directly relevant.
- For choices, show at most 3 options.
- In Korean conversations, keep the same concise Korean tone.

# Browser automation safety (macOS)

- Never launch the user's `/Applications/Google Chrome.app` with `--headless` for tests: even with a separate `--user-data-dir`, macOS URL-open requests can land in the invisible test process. Use standalone `chrome-headless-shell` instead; install with `npx --yes @puppeteer/browsers install chrome-headless-shell@stable --path "$HOME/.cache/puppeteer"` and use the executable path it prints. Do not silently fall back to the user's browser. Headless Shell differs from full Chrome; ask before tests requiring full Chrome or extensions.
- Use a fresh temporary profile and a loopback-only debugging endpoint for each run. Own the browser within the test process and close it in `finally`; shell launches need an EXIT/INT/TERM cleanup trap and a bounded lifetime. Avoid detached, unowned background browsers.
- Before finishing, verify that the run's browser PID and debugging endpoint are gone. Stop only processes owned by that run; never use broad `pkill Chrome` or terminate another session's browser.
